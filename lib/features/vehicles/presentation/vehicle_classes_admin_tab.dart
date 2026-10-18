import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../../core/enums/enums.dart';
import '../../../core/vehicles/vehicle_catalog.dart';
import '../../../core/widgets/components.dart';
import '../../../l10n/l10n.dart';
import '../data/vehicle_class_repository.dart';

/// A photo chosen by the admin.
typedef PickedImage = ({Uint8List bytes, String contentType});

/// Opens the system picker for a PNG, JPG or WebP photo.
Future<PickedImage?> pickVehicleImage() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    withData: true,
  );
  final f = result?.files.singleOrNull;
  final bytes = f?.bytes;
  if (f == null || bytes == null) return null;
  final ext = (f.extension ?? '').toLowerCase();
  return (bytes: bytes, contentType: 'image/${ext == 'jpg' ? 'jpeg' : ext}');
}

/// Text for an error key from validateVehicleClass or saveVehicleClass.
String vehicleErrorText(AppLocalizations l, String key) => switch (key.replaceFirst('vehicle/', '')) {
      'id' => l.vehErrId,
      'name' => l.vehErrName,
      'length' => l.vehErrLength,
      'capacity' || 'numbers' => l.vehErrCapacity,
      'services' => l.vehErrServices,
      'price' => l.vehErrPrice,
      'slides' => l.vehErrSlides,
      'exists' => l.vehErrExists,
      _ => l.vehErrFailed,
    };

String _langName(AppLocalizations l, String lang) => switch (lang) {
      'en' => l.vehLangEn,
      'pt' => l.vehLangPt,
      _ => l.vehLangEs,
    };

/// Admin → Tipos y precios: every vehicle type, with what it costs, carries
/// and looks like; create new ones and edit or archive any of them.
class VehicleClassesAdminTab extends StatelessWidget {
  const VehicleClassesAdminTab({super.key, this.repository, this.pickImage});
  final VehicleClassRepository? repository;
  final Future<PickedImage?> Function()? pickImage;

  VehicleClassRepository get _repo => repository ?? sl<VehicleClassRepository>();

  Future<void> _open(BuildContext context, VehicleClassInfo? existing) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => VehicleClassEditor(existing: existing, repository: _repo, pickImage: pickImage ?? pickVehicleImage),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: VehicleCatalog.instance,
        builder: (context, _) {
          final l = context.l10n;
          final all = VehicleCatalog.instance.all;
          return ListView(
            padding: const EdgeInsets.all(LuxSpacing.lg),
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: LuxSpacing.md,
                runSpacing: LuxSpacing.sm,
                children: [
                  SectionHeader(title: l.vehAdminTitle),
                  FilledButton.icon(
                    onPressed: () => _open(context, null),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l.vehAdminNew),
                  ),
                ],
              ),
              const SizedBox(height: LuxSpacing.sm),
              Text(l.vehAdminIntro, style: LuxTypography.caption),
              const SizedBox(height: LuxSpacing.lg),
              for (final v in all)
                Padding(
                  padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
                  child: _VehicleClassCard(info: v, onEdit: () => _open(context, v)),
                ),
            ],
          );
        },
      );
}

class _VehicleClassCard extends StatelessWidget {
  const _VehicleClassCard({required this.info, required this.onEdit});
  final VehicleClassInfo info;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = l.localeName;
    String money(double v) => LuxMoney.format(v, cents: v % 1 != 0);
    final ow = info.oneWay;
    final bh = info.byTheHour;
    Widget badge(String text, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(LuxRadius.sm),
          ),
          child: Text(text, style: LuxTypography.caption.copyWith(color: color)),
        );
    final edit = TextButton(onPressed: onEdit, child: Text(l.vehAdminEdit, style: const TextStyle(color: LuxColors.sapphire)));
    return LuxCard(
      child: LayoutBuilder(builder: (context, c) {
        final narrow = c.maxWidth < 520;
        final details = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: LuxSpacing.sm, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(info.nameIn(lang), style: LuxTypography.titleMedium),
            badge(info.active ? l.vehAdminActive : l.vehAdminArchived, info.active ? LuxColors.success : LuxColors.inkTertiary),
            if (info.builtIn && !VehicleCatalog.instance.isCustomized(info.id)) badge(l.vehAdminDefault, LuxColors.sapphireLight),
          ]),
          if (info.descriptionIn(lang).isNotEmpty) Text(info.descriptionIn(lang), style: LuxTypography.caption),
          const SizedBox(height: 4),
          Text(
            l.vehAdminCapacityLine(l.unitPassengers(info.capacity), l.unitBags(info.carryOn + info.checked + info.extraLarge)),
            style: LuxTypography.caption,
          ),
          Text(
            ow != null
                ? l.vehAdminOneWayLine(money(ow.base), money(ow.perKm), money(ow.min))
                : l.vehAdminNotOffered(ServiceType.oneWay.localizedLabel(l)),
            style: LuxTypography.caption,
          ),
          Text(
            bh != null
                ? l.vehAdminHourlyLine(money(bh.perHour), money(bh.min))
                : l.vehAdminNotOffered(ServiceType.byTheHour.localizedLabel(l)),
            style: LuxTypography.caption,
          ),
        ]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          VehicleThumb(info: info, width: narrow ? 72 : 88, height: narrow ? 48 : 56),
          const SizedBox(width: LuxSpacing.md),
          Expanded(
            // On phones the button goes under the details, so they keep the width.
            child: narrow
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    details,
                    Align(alignment: Alignment.centerRight, child: edit),
                  ])
                : details,
          ),
          if (!narrow) edit,
        ]);
      }),
    );
  }
}

/// Small picture of a vehicle type: uploaded photo, bundled image or icon.
class VehicleThumb extends StatelessWidget {
  const VehicleThumb({super.key, required this.info, this.url, this.width = 88, this.height = 56});
  final VehicleClassInfo info;

  /// Shows this URL instead (photos in the editor).
  final String? url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget icon() => Icon(info.iconData, color: LuxColors.sapphire, size: height * 0.5);
    Widget asset() => info.asset == null ? icon() : Image.asset(info.asset!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => icon());
    final src = url ?? info.imageUrl;
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LuxColors.surfaceMuted,
        borderRadius: BorderRadius.circular(LuxRadius.sm),
      ),
      clipBehavior: Clip.antiAlias,
      child: src == null ? asset() : Image.network(src, fit: BoxFit.contain, errorBuilder: (_, __, ___) => url == null ? asset() : icon()),
    );
  }
}

const _swatches = [
  Color(0xFF3A7BD5),
  Color(0xFF7B4DB5),
  Color(0xFF2E6AC8),
  Color(0xFF2A9E72),
  Color(0xFF1B4F8A),
  Color(0xFFB3261E),
  Color(0xFF5F6B7A),
  Color(0xFF0B1220),
];

class _SlideDraft {
  _SlideDraft(this.url, Map<String, String> caption)
      : captions = {for (final lang in vehicleLangs) lang: TextEditingController(text: caption[lang] ?? '')};
  final String url;
  final Map<String, TextEditingController> captions;

  VehicleSlide toSlide() => VehicleSlide(url: url, caption: {
        for (final e in captions.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
      });

  void dispose() {
    for (final c in captions.values) {
      c.dispose();
    }
  }
}

/// Creates or edits a vehicle type: names, photos, capacity, services and
/// prices, look and availability.
class VehicleClassEditor extends StatefulWidget {
  const VehicleClassEditor({super.key, this.existing, required this.repository, required this.pickImage});
  final VehicleClassInfo? existing;
  final VehicleClassRepository repository;
  final Future<PickedImage?> Function() pickImage;

  @override
  State<VehicleClassEditor> createState() => _VehicleClassEditorState();
}

class _VehicleClassEditorState extends State<VehicleClassEditor> {
  late final VehicleClassInfo _start = widget.existing ??
      VehicleClassInfo(
        id: '',
        name: const {},
        order: VehicleCatalog.instance.all.fold<int>(0, (m, v) => v.order >= 9000 ? m : (v.order >= m ? v.order + 1 : m)),
        color: const Color(0xFF1B4F8A),
        oneWay: builtInVehicleClasses['business']!.oneWay,
        byTheHour: builtInVehicleClasses['business']!.byTheHour,
      );
  bool get _creating => widget.existing == null;

  late final _id = TextEditingController(text: _start.id);
  late final _names = {for (final l in vehicleLangs) l: TextEditingController(text: _start.name[l] ?? '')};
  late final _descs = {for (final l in vehicleLangs) l: TextEditingController(text: _start.description[l] ?? '')};
  late final _capacity = TextEditingController(text: '${_start.capacity}');
  late final _carryOn = TextEditingController(text: '${_start.carryOn}');
  late final _checked = TextEditingController(text: '${_start.checked}');
  late final _extraLarge = TextEditingController(text: '${_start.extraLarge}');
  late final _order = TextEditingController(text: '${_start.order}');
  late final _owBase = TextEditingController(text: _num(_start.oneWay?.base ?? 50));
  late final _owKm = TextEditingController(text: _num(_start.oneWay?.perKm ?? 3));
  late final _owMin = TextEditingController(text: _num(_start.oneWay?.min ?? 50));
  late final _bhHour = TextEditingController(text: _num(_start.byTheHour?.perHour ?? 80));
  late final _bhMin = TextEditingController(text: _num(_start.byTheHour?.min ?? 160));
  late bool _oneWayOn = _start.oneWay != null;
  late bool _hourlyOn = _start.byTheHour != null;
  late bool _childSeat = _start.childSeat;
  late bool _active = _start.active;
  late String _icon = _start.icon;
  late Color _color = _start.color;
  late String? _imageUrl = _start.imageUrl;
  late final List<_SlideDraft> _slides = [for (final s in _start.slides) _SlideDraft(s.url, s.caption)];
  bool _uploading = false;
  bool _saving = false;
  String? _error;

  static String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';

  @override
  void dispose() {
    for (final c in [
      _id,
      _capacity,
      _carryOn,
      _checked,
      _extraLarge,
      _order,
      _owBase,
      _owKm,
      _owMin,
      _bhHour,
      _bhMin,
      ..._names.values,
      ..._descs.values
    ]) {
      c.dispose();
    }
    for (final s in _slides) {
      s.dispose();
    }
    super.dispose();
  }

  double _d(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.')) ?? -1;
  int _i(TextEditingController c) => int.tryParse(c.text.trim()) ?? -1;

  Map<String, String> _texts(Map<String, TextEditingController> m) => {
        for (final e in m.entries)
          if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
      };

  VehicleClassInfo _build() => VehicleClassInfo(
        id: _id.text.trim(),
        name: _texts(_names),
        description: _texts(_descs),
        active: _active,
        order: _i(_order).clamp(0, 9999),
        capacity: _i(_capacity),
        carryOn: _i(_carryOn),
        checked: _i(_checked),
        extraLarge: _i(_extraLarge),
        childSeat: _childSeat,
        icon: _icon,
        color: _color,
        imageUrl: _imageUrl,
        asset: _start.asset,
        slides: [for (final s in _slides) s.toSlide()],
        oneWay: _oneWayOn ? PriceRule(base: _d(_owBase), perKm: _d(_owKm), min: _d(_owMin)) : null,
        byTheHour: _hourlyOn ? PriceRule(perHour: _d(_bhHour), min: _d(_bhMin)) : null,
        builtIn: _start.builtIn,
      );

  String? _localError(VehicleClassInfo v) {
    if ([v.carryOn, v.checked, v.extraLarge].any((n) => n < 0 || n > 60)) return 'capacity';
    for (final r in [v.oneWay, v.byTheHour]) {
      if (r != null && [r.base, r.perKm, r.perHour, r.min].any((n) => n < 0)) return 'price';
    }
    if (v.slides.any((s) => s.caption.values.any((c) => c.length > 120))) return 'length';
    return validateVehicleClass(v);
  }

  Future<String?> _upload() async {
    final l = context.l10n;
    final id = _id.text.trim();
    if (!vehicleIdPattern.hasMatch(id)) {
      setState(() => _error = l.vehEdIdFirst);
      return null;
    }
    final picked = await widget.pickImage();
    if (picked == null || !mounted) return null;
    setState(() {
      _uploading = true;
      _error = null;
    });
    final url = await widget.repository.uploadImage(id, picked.bytes, picked.contentType);
    if (!mounted) return null;
    setState(() {
      _uploading = false;
      if (url == null) _error = l.vehEdUploadFailed;
    });
    return url;
  }

  Future<void> _save() async {
    final l = context.l10n;
    final v = _build();
    final local = _localError(v);
    if (local != null) return setState(() => _error = vehicleErrorText(l, local));
    setState(() {
      _saving = true;
      _error = null;
    });
    final err = await widget.repository.save(v, create: _creating);
    if (!mounted) return;
    if (err != null) {
      return setState(() {
        _saving = false;
        _error = vehicleErrorText(l, err);
      });
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    Navigator.of(context).pop();
    messenger?.showSnackBar(SnackBar(content: Text(l.vehEdSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final digits = [FilteringTextInputFormatter.digitsOnly];
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    Widget section(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(top: LuxSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title.toUpperCase(), style: LuxTypography.caption.copyWith(color: LuxColors.sapphire, letterSpacing: 1.6)),
            const SizedBox(height: LuxSpacing.sm),
            ...children,
          ]),
        );
    Widget field(TextEditingController c, String label, {List<TextInputFormatter>? fmt, String? hint, int maxLines = 1}) => Padding(
          padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
          child: LuxTextField(
            controller: c,
            label: label,
            hint: hint,
            maxLines: maxLines,
            inputFormatters: fmt,
            keyboardType: fmt == null ? null : const TextInputType.numberWithOptions(decimal: true),
          ),
        );
    Widget row(List<Widget> children) => LayoutBuilder(
          builder: (context, c) => c.maxWidth < 420
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final (i, w) in children.indexed) ...[if (i > 0) const SizedBox(width: LuxSpacing.sm), Expanded(child: w)],
                ]),
        );
    Widget toggle(String label, bool value, ValueChanged<bool> onChanged, {String? hint}) => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: LuxColors.sapphire,
          title: Text(label, style: LuxTypography.bodyMedium),
          subtitle: hint == null ? null : Text(hint, style: LuxTypography.caption),
          value: value,
          onChanged: onChanged,
        );

    final preview = _build();
    return Dialog(
      backgroundColor: LuxColors.surface,
      insetPadding: const EdgeInsets.all(LuxSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(LuxSpacing.lg, LuxSpacing.md, LuxSpacing.sm, 0),
            child: Row(children: [
              Expanded(
                child: Text(
                  _creating ? l.vehEdNewTitle : l.vehEdEditTitle(_start.nameIn(l.localeName)),
                  style: LuxTypography.titleLarge,
                ),
              ),
              IconButton(
                tooltip: l.commonCancel,
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(LuxSpacing.lg, 0, LuxSpacing.lg, LuxSpacing.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                section(l.vehEdSectionIdentity, [
                  if (_creating)
                    field(_id, l.vehEdId, hint: l.vehEdIdHint)
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
                      child: Text('${l.vehEdId}: ${_start.id}', style: LuxTypography.caption),
                    ),
                  for (final lang in vehicleLangs)
                    row([
                      field(_names[lang]!, l.vehEdName(_langName(l, lang))),
                      field(_descs[lang]!, l.vehEdDescription(_langName(l, lang))),
                    ]),
                ]),
                section(l.vehEdSectionPhotos, [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    VehicleThumb(info: preview, width: 160, height: 100),
                    const SizedBox(width: LuxSpacing.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l.vehEdMainPhoto, style: LuxTypography.titleMedium),
                        Text(l.vehEdMainPhotoHint, style: LuxTypography.caption),
                        const SizedBox(height: LuxSpacing.xs),
                        Wrap(spacing: LuxSpacing.sm, children: [
                          OutlinedButton.icon(
                            onPressed: _uploading
                                ? null
                                : () async {
                                    final url = await _upload();
                                    if (url != null) setState(() => _imageUrl = url);
                                  },
                            icon: const Icon(Icons.upload_rounded, size: 18),
                            label: Text(_uploading ? l.vehEdUploading : (_imageUrl == null ? l.vehEdUpload : l.vehEdReplace)),
                          ),
                          if (_imageUrl != null) TextButton(onPressed: () => setState(() => _imageUrl = null), child: Text(l.vehEdRemove)),
                        ]),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: LuxSpacing.md),
                  Text(l.vehEdGallery, style: LuxTypography.titleMedium),
                  Text(l.vehEdGalleryHint, style: LuxTypography.caption),
                  const SizedBox(height: LuxSpacing.sm),
                  for (final (i, s) in _slides.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        VehicleThumb(info: preview, url: s.url, width: 96, height: 64),
                        const SizedBox(width: LuxSpacing.sm),
                        Expanded(
                          child: Column(children: [
                            for (final lang in vehicleLangs) field(s.captions[lang]!, l.vehEdCaption(_langName(l, lang))),
                          ]),
                        ),
                        IconButton(
                          tooltip: l.vehEdRemove,
                          onPressed: () => setState(() => _slides.removeAt(i).dispose()),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ]),
                    ),
                  if (_slides.length < 8)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _uploading
                            ? null
                            : () async {
                                final url = await _upload();
                                if (url != null) setState(() => _slides.add(_SlideDraft(url, const {})));
                              },
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                        label: Text(_uploading ? l.vehEdUploading : l.vehEdAddSlide),
                      ),
                    ),
                ]),
                section(l.vehEdSectionCapacity, [
                  row([field(_capacity, l.vehEdPassengers, fmt: digits), field(_carryOn, l.vehEdCarryOn, fmt: digits)]),
                  row([field(_checked, l.vehEdChecked, fmt: digits), field(_extraLarge, l.vehEdExtraLarge, fmt: digits)]),
                  toggle(l.vehEdChildSeat, _childSeat, (v) => setState(() => _childSeat = v)),
                ]),
                section(l.vehEdSectionPrices, [
                  Text(l.vehEdPricesHint, style: LuxTypography.caption),
                  toggle(l.vehEdOneWay, _oneWayOn, (v) => setState(() => _oneWayOn = v)),
                  if (_oneWayOn)
                    row([
                      field(_owBase, l.vehEdBase, fmt: decimal),
                      field(_owKm, l.vehEdPerKm, fmt: decimal),
                      field(_owMin, l.vehEdMin, fmt: decimal),
                    ]),
                  toggle(l.vehEdHourly, _hourlyOn, (v) => setState(() => _hourlyOn = v)),
                  if (_hourlyOn) row([field(_bhHour, l.vehEdPerHour, fmt: decimal), field(_bhMin, l.vehEdMin, fmt: decimal)]),
                ]),
                section(l.vehEdSectionLook, [
                  Text(l.vehEdIcon, style: LuxTypography.caption),
                  const SizedBox(height: LuxSpacing.xs),
                  Wrap(spacing: LuxSpacing.sm, runSpacing: LuxSpacing.sm, children: [
                    for (final e in vehicleIcons.entries)
                      ChoiceChip(
                        label: Icon(e.value, size: 20, color: _icon == e.key ? LuxColors.onAccent : LuxColors.ink),
                        selected: _icon == e.key,
                        selectedColor: LuxColors.sapphire,
                        onSelected: (_) => setState(() => _icon = e.key),
                      ),
                  ]),
                  const SizedBox(height: LuxSpacing.md),
                  Text(l.vehEdColor, style: LuxTypography.caption),
                  const SizedBox(height: LuxSpacing.xs),
                  Wrap(spacing: LuxSpacing.sm, runSpacing: LuxSpacing.sm, children: [
                    for (final c in {..._swatches, _color})
                      Semantics(
                        button: true,
                        selected: c.toARGB32() == _color.toARGB32(),
                        label: hexColor(c),
                        child: InkWell(
                          onTap: () => setState(() => _color = c),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: c.toARGB32() == _color.toARGB32() ? LuxColors.ink : LuxColors.border,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ]),
                ]),
                section(l.vehEdSectionStatus, [
                  toggle(l.vehEdActive, _active, (v) => setState(() => _active = v), hint: l.vehEdActiveHint),
                  field(_order, l.vehEdOrder, fmt: digits),
                ]),
              ]),
            ),
          ),
          const Divider(height: 1, color: LuxColors.border),
          Padding(
            padding: const EdgeInsets.all(LuxSpacing.md),
            child: Row(children: [
              Expanded(
                child:
                    _error == null ? const SizedBox.shrink() : Text(_error!, style: LuxTypography.caption.copyWith(color: LuxColors.error)),
              ),
              const SizedBox(width: LuxSpacing.sm),
              FilledButton(
                onPressed: _saving || _uploading ? null : _save,
                child:
                    _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l.vehEdSave),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
