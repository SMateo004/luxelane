import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../di/injection.dart';
import '../models/place_model.dart';
import '../services/maps_service.dart';

class PlaceAutocompleteField extends StatefulWidget {
  const PlaceAutocompleteField({
    super.key,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.initialValue,
    this.onPlaceSelected,
    this.onMapPick,
  });

  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Place? initialValue;
  final ValueChanged<Place>? onPlaceSelected;
  final VoidCallback? onMapPick;

  @override
  State<PlaceAutocompleteField> createState() =>
      _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  final _ctrl     = TextEditingController();
  final _focus    = FocusNode();
  final _maps     = sl<MapsService>();
  final _fieldKey = GlobalKey();
  final _portalController = OverlayPortalController();

  List<PlaceSuggestion> _suggestions = [];
  Timer?  _debounce;
  bool    _loading  = false;
  bool    _showDrop = false;
  bool    _ignoreUpdates = false;
  String? _token;

  // ── theme helpers ──────────────────────────────────────────────────────────
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _fieldBg     => _isDark ? LuxColors.blackElevated   : const Color(0xFFF5F4F1);
  Color get _borderColor => _isDark ? LuxColors.blackBorder     : const Color(0xFFE4E1DA);
  Color get _focusBorder => _isDark ? LuxColors.sapphire.withOpacity(0.6) : const Color(0xFF111111);
  Color get _iconColor   => _isDark ? LuxColors.whiteTertiary   : const Color(0xFFAAAAAA);
  Color get _textColor   => _isDark ? LuxColors.white           : const Color(0xFF111111);
  Color get _hintColor   => _isDark ? LuxColors.whiteTertiary   : const Color(0xFFBBBBBB);
  Color get _dropBg      => _isDark ? LuxColors.blackSurface    : Colors.white;
  Color get _dropDivider => _isDark ? LuxColors.blackBorder     : const Color(0xFFEEECE8);
  Color get _suggPrimary   => _isDark ? LuxColors.white         : const Color(0xFF111111);
  Color get _suggSecondary => _isDark ? LuxColors.whiteTertiary : const Color(0xFF999999);
  Color get _suggIcon      => _isDark ? LuxColors.whiteTertiary : const Color(0xFFCCCCCC);

  void _dbg(String msg) => debugPrint('[PAF] $msg');

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) _ctrl.text = widget.initialValue!.displayName;
    _token = _newToken();
    _focus.addListener(() {
      if (!_focus.hasFocus) _hideDropdown();
    });
  }

  @override
  void didUpdateWidget(PlaceAutocompleteField old) {
    super.didUpdateWidget(old);
    if (_ignoreUpdates) return;
    if (widget.initialValue != old.initialValue && widget.initialValue != null) {
      _ctrl.text = widget.initialValue!.displayName;
      _hideDropdown();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _newToken() => DateTime.now().millisecondsSinceEpoch.toString();

  void _showDropdown() {
    if (!_showDrop) setState(() => _showDrop = true);
    if (!_portalController.isShowing) _portalController.show();
  }

  void _hideDropdown() {
    if (_showDrop) setState(() => _showDrop = false);
    if (_portalController.isShowing) _portalController.hide();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.length < 2) { _hideDropdown(); return; }
    _debounce = Timer(const Duration(milliseconds: 320), () => _search(value));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    final res = await _maps.autocomplete(q, sessionToken: _token);
    if (!mounted) return;
    setState(() {
      _suggestions = res;
      _loading = false;
    });
    if (res.isNotEmpty) {
      _showDropdown();
    } else {
      _hideDropdown();
    }
  }

  Future<void> _pick(PlaceSuggestion s) async {
    _ignoreUpdates = true;
    _ctrl.text = s.mainText;
    
    setState(() { 
      _suggestions = []; 
      _loading = true; 
    });
    
    _hideDropdown();
    _focus.unfocus();

    try {
      final place = await _maps.getPlaceDetails(
        s.placeId,
        sessionToken: _token,
        address: s.description,
      );
      if (!mounted) return;
      
      if (place != null) {
        _ctrl.text = place.displayName;
        _token = _newToken();
        widget.onPlaceSelected?.call(place);
      } else {
        // FALLBACK: If details fail, create a Place with 0,0 or dummy coords
        // so the 'Get Prices' button can at least be pressed.
        _dbg('Fallback for: ${s.description}');
        final fallback = Place(
          name: s.mainText,
          address: s.description,
          lat: 0.0,
          lng: 0.0,
        );
        widget.onPlaceSelected?.call(fallback);
      }
    } catch (e) {
      _dbg('Error in _pick: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _ignoreUpdates = false;
      });
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: _buildOverlayDropdown,
        child: _buildField(),
      );

  Widget _buildOverlayDropdown(BuildContext ctx) {
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();
    final size   = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final bg      = _dropBg;
    final divider = _dropDivider;
    final primary   = _suggPrimary;
    final secondary = _suggSecondary;
    final iconCol   = _suggIcon;
    final suggs     = List<PlaceSuggestion>.from(_suggestions);

    return Positioned(
      left:  offset.dx,
      top:   offset.dy + size.height + 2,
      width: size.width,
      child: Material(
        color: bg,
        elevation: 4,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 260),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: divider),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < suggs.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, thickness: 1, color: divider),
                  // Use Listener (lower-level than GestureDetector) for reliable
                  // tap detection inside OverlayPortal on Flutter web.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) {
                      _pick(suggs[i]);
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 16, color: iconCol),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    suggs[i].mainText,
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 13,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (suggs[i].secondaryText.isNotEmpty)
                                    Text(
                                      suggs[i].secondaryText,
                                      style: TextStyle(
                                        color: secondary,
                                        fontSize: 11,
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.w300,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField() => Container(
        key: _fieldKey,
        decoration: BoxDecoration(
          color: _fieldBg,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: _focus.hasFocus ? _focusBorder : _borderColor,
          ),
        ),
        child: Row(
          children: [
            if (widget.prefixIcon != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(widget.prefixIcon, size: 16, color: _iconColor),
              ),
            Expanded(
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                onChanged: _onChanged,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 13,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint ?? widget.label,
                  hintStyle: TextStyle(
                    color: _hintColor,
                    fontSize: 13,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w300,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                ),
              ),
            ),
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.2, color: _iconColor),
                ),
              )
            else if (_ctrl.text.isNotEmpty)
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerUp: (_) {
                  _ctrl.clear();
                  setState(() => _suggestions = []);
                  _hideDropdown();
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(Icons.close, size: 14, color: _iconColor),
                ),
              ),
          ],
        ),
      );
}
