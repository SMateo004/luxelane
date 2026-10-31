import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../di/injection.dart';
import '../models/place_model.dart';
import '../services/maps_service.dart';
import '../utils/service_area.dart';
import 'components.dart';

class PlaceAutocompleteField extends StatefulWidget {
  const PlaceAutocompleteField({
    super.key,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.initialValue,
    this.onPlaceSelected,
    this.onMapPick,
    this.sameCityAs,
    this.glass = false, // true → transparent/glass look for hero bar
    this.bare = false,
  });

  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Place? initialValue;
  final ValueChanged<Place>? onPlaceSelected;
  final VoidCallback? onMapPick;

  /// For destination fields: the pickup. Suggestions are limited to its city
  /// and a place in another city is rejected with a message instead of
  /// reaching [onPlaceSelected].
  final Place? sameCityAs;
  final bool glass;

  /// Sin caja ni borde: para ir dentro de una tarjeta que agrupa recogida y
  /// destino (la tarjeta pone el marco).
  final bool bare;

  @override
  State<PlaceAutocompleteField> createState() => _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<PlaceAutocompleteField> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _maps = sl<MapsService>();
  final _fieldKey = GlobalKey();

  /// La lista va en una entrada propia del Overlay raíz (E34): con
  /// OverlayPortal su nodo de accesibilidad quedaba entre los de la página y,
  /// en web, los chips de recientes lo tapaban (un clic en la sugerencia
  /// elegía el chip). Una entrada del Overlay va por encima de toda la ruta.
  OverlayEntry? _dropEntry;

  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _loading = false;
  bool _showDrop = false;
  bool _ignoreUpdates = false;
  String? _token;

  // ── theme helpers ──────────────────────────────────────────────────────────
  // glass=true → fully transparent field that sits inside the hero liquid-glass bar
  bool get _plain => widget.glass || widget.bare;
  Color get _fieldBg => _plain ? Colors.transparent : LuxColors.surface;
  Color get _borderColor => _plain ? Colors.transparent : LuxColors.border;
  Color get _focusBorder => _plain ? Colors.transparent : LuxColors.sapphire;
  Color get _iconColor =>
      widget.glass ? const Color(0x99FFFFFF) : LuxColors.inkTertiary;
  Color get _textColor => widget.glass ? Colors.white : LuxColors.ink;
  Color get _hintColor =>
      widget.glass ? const Color(0x66FFFFFF) : LuxColors.inkTertiary;
  Color get _dropBg => LuxColors.surface;
  Color get _dropDivider => LuxColors.border;
  Color get _suggPrimary => LuxColors.ink;
  Color get _suggSecondary => LuxColors.inkTertiary;
  Color get _suggIcon => LuxColors.sapphire;

  void _log(String msg) => debugPrint('[PAF] $msg');

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null)
      _ctrl.text = widget.initialValue!.displayName;
    _token = _newToken();
    _focus.addListener(() {
      if (!_focus.hasFocus) _hideDropdown();
    });
  }

  @override
  void didUpdateWidget(PlaceAutocompleteField old) {
    super.didUpdateWidget(old);
    if (_ignoreUpdates) return;
    if (widget.initialValue != old.initialValue) {
      // Null means the parent cleared the place (e.g. a destination left in
      // another city after the pickup changed).
      _ctrl.text = widget.initialValue?.displayName ?? '';
      _hideDropdown();
    }
  }

  @override
  void dispose() {
    _dropEntry?.remove();
    _dropEntry = null;
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _newToken() => DateTime.now().millisecondsSinceEpoch.toString();

  void _showDropdown() {
    if (!_showDrop) setState(() => _showDrop = true);
    if (_dropEntry == null) {
      _dropEntry = OverlayEntry(builder: _buildOverlayDropdown);
      Overlay.of(context, rootOverlay: true).insert(_dropEntry!);
    } else {
      _dropEntry!.markNeedsBuild();
    }
  }

  void _hideDropdown() {
    if (_showDrop && mounted) setState(() => _showDrop = false);
    _dropEntry?.remove();
    _dropEntry = null;
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.length < 2) {
      _hideDropdown();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () => _search(value));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    final res = await _maps.autocomplete(
      q,
      sessionToken: _token,
      restrictTo: ServiceArea.destinationAreaFor(widget.sameCityAs),
    );
    _log('autocomplete("$q") → ${res.length} results');
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

      // Sin coordenadas no se puede recoger ni calcular el precio: mejor
      // pedir otra dirección que guardar un lugar en (0,0).
      if (place == null) {
        _log('Place details failed for: ${s.description}');
        _ctrl.text = widget.initialValue?.displayName ?? '';
        showLuxSnackbar(
          context,
          context.l10n.commonAddressNotFound,
          isError: true,
        );
        return;
      }
      final picked = place;
      _token = _newToken();

      final origin = widget.sameCityAs;
      final error =
          origin == null ? null : ServiceArea.destinationError(origin, picked);
      if (error != null) {
        _ctrl.text = widget.initialValue?.displayName ?? '';
        showLuxSnackbar(context, error, isError: true);
        return;
      }
      _ctrl.text = place.displayName;
      widget.onPlaceSelected?.call(picked);
    } catch (e) {
      _log('Error in _pick: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _ignoreUpdates = false;
      });
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => _buildField();

  Widget _buildOverlayDropdown(BuildContext ctx) {
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    // Flip the dropdown above the field when there isn't enough space below.
    final screenH = MediaQuery.sizeOf(ctx).height;
    final dropHeight = (_suggestions.length * 50.0).clamp(0.0, 260.0);
    final spaceBelow = screenH - (offset.dy + size.height + 2);
    final showAbove = spaceBelow < dropHeight + 8;
    final topPos =
        showAbove ? offset.dy - dropHeight - 4 : offset.dy + size.height + 2;

    final bg = _dropBg;
    final divider = _dropDivider;
    final primary = _suggPrimary;
    final secondary = _suggSecondary;
    final iconCol = _suggIcon;
    final suggs = List<PlaceSuggestion>.from(_suggestions);

    return Positioned(
      left: offset.dx,
      top: topPos,
      width: size.width,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 260),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(LuxRadius.md),
            border: Border.all(color: divider),
            boxShadow: LuxElevation.high,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < suggs.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: divider),
                  // Use Listener (lower-level than GestureDetector) for reliable
                  // tap detection inside OverlayPortal on Flutter web.
                  Semantics(
                    button: true,
                    label: [
                      suggs[i].mainText,
                      if (suggs[i].secondaryText.isNotEmpty)
                        suggs[i].secondaryText,
                    ].join(', '),
                    onTap: () => _pick(suggs[i]),
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) {
                        _pick(suggs[i]);
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: iconCol,
                              ),
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
                                        fontFamily: LuxTypography.sansFamily,
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
                                          fontFamily: LuxTypography.sansFamily,
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
          // glass mode: larger radius so it looks rounded inside the glass bar
          borderRadius: BorderRadius.circular(widget.glass ? 10 : LuxRadius.md),
          border:
              Border.all(color: _focus.hasFocus ? _focusBorder : _borderColor),
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
                  fontSize: widget.bare ? 15 : 13,
                  fontFamily: LuxTypography.sansFamily,
                  fontWeight: widget.bare ? FontWeight.w500 : FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint ?? widget.label,
                  hintStyle: TextStyle(
                    color: _hintColor,
                    fontSize: widget.bare ? 15 : 13,
                    fontFamily: LuxTypography.sansFamily,
                    fontWeight: FontWeight.w300,
                  ),
                  // glass mode: explicitly clear any theme-injected fill
                  filled: _plain ? true : null,
                  fillColor: _plain ? Colors.transparent : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
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
                    strokeWidth: 1.2,
                    color: _iconColor,
                  ),
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
