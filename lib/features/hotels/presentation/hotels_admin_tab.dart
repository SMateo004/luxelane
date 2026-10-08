import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/env.dart';
import '../../../core/di/injection.dart';
import '../../../core/models/place_model.dart';
import '../../../core/widgets/components.dart';
import '../../../core/widgets/place_autocomplete_field.dart';
import '../../../l10n/l10n.dart';
import '../data/hotel_repository.dart';
import '../domain/partner_hotel.dart';

String localizedHotelError(AppLocalizations l, String code) => switch (code) {
      'hotel/name' => l.hotelErrorName,
      'hotel/place' => l.hotelErrorPlace,
      'hotel/meeting-point' => l.hotelErrorMeetingPoint,
      _ => l.adminActionFailed,
    };

/// Admin panel → Hoteles: partner hotels shown on the hotel transfers page,
/// each with a link for a QR code at reception.
class HotelsAdminTab extends StatelessWidget {
  const HotelsAdminTab({super.key, this.repository, this.baseUrl});
  final HotelRepository? repository;

  /// Base of the shared links; defaults to this site on web.
  final String? baseUrl;

  String get _base => baseUrl ?? (kIsWeb ? Uri.base.origin : AppConfig.riderWebUrl);

  @override
  Widget build(BuildContext context) {
    final repo = repository ?? sl<HotelRepository>();
    final l = context.l10n;
    return StreamBuilder<List<PartnerHotel>>(
      stream: repo.watchAll(),
      builder: (context, snap) {
        final hotels = snap.data ?? const <PartnerHotel>[];
        return ListView(
          padding: const EdgeInsets.all(LuxSpacing.lg),
          children: [
            SectionHeader(title: l.hotelAdminTitle),
            const SizedBox(height: LuxSpacing.sm),
            Text(l.hotelAdminIntro, style: LuxTypography.bodyMedium),
            const SizedBox(height: LuxSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: LuxButton(
                label: l.hotelAdminAdd,
                icon: Icons.add_rounded,
                width: 220,
                height: 44,
                onPressed: () => showDialog<void>(context: context, builder: (_) => HotelEditDialog(repo: repo)),
              ),
            ),
            const SizedBox(height: LuxSpacing.lg),
            if (!snap.hasData && !snap.hasError)
              const Center(child: CircularProgressIndicator(color: LuxColors.accent))
            else if (hotels.isEmpty)
              EmptyState(icon: Icons.hotel_outlined, message: l.hotelAdminEmpty)
            else
              for (final h in hotels) _HotelTile(hotel: h, repo: repo, link: HotelTransfers.link(_base, h.id)),
          ],
        );
      },
    );
  }
}

class _HotelTile extends StatelessWidget {
  const _HotelTile({required this.hotel, required this.repo, required this.link});
  final PartnerHotel hotel;
  final HotelRepository repo;
  final String link;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final h = hotel;
    return Padding(
      padding: const EdgeInsets.only(bottom: LuxSpacing.sm),
      child: LuxCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.hotel_outlined, color: LuxColors.accent),
            const SizedBox(width: LuxSpacing.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: LuxSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(h.name, style: LuxTypography.titleMedium),
                  Text(h.active ? l.hotelAdminVisible : l.hotelAdminHidden,
                      style: LuxTypography.caption.copyWith(color: LuxColors.whiteSecondary)),
                ]),
                const SizedBox(height: 2),
                Text(h.address, maxLines: 2, overflow: TextOverflow.ellipsis, style: LuxTypography.bodyMedium),
                if (h.meetingPoint.isNotEmpty) Text(l.hotelMeetingPoint(h.meetingPoint), style: LuxTypography.caption),
              ]),
            ),
            Tooltip(
              message: h.active ? l.hotelAdminHide : l.hotelAdminShow,
              child: Switch(
                value: h.active,
                activeColor: LuxColors.accent,
                onChanged: (v) async {
                  try {
                    await repo.setActive(h.id, v);
                  } catch (_) {
                    if (context.mounted) showLuxSnackbar(context, l.adminActionFailed, isError: true);
                  }
                },
              ),
            ),
            IconButton(
              tooltip: l.hotelAdminEdit,
              icon: const Icon(Icons.edit_outlined, color: LuxColors.whiteSecondary),
              onPressed: () =>
                  showDialog<void>(context: context, builder: (_) => HotelEditDialog(repo: repo, initial: h)),
            ),
          ]),
          const SizedBox(height: LuxSpacing.sm),
          Row(children: [
            Expanded(
              child: SelectableText(link, maxLines: 1, style: LuxTypography.caption.copyWith(color: LuxColors.white)),
            ),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (context.mounted) showLuxSnackbar(context, l.hotelAdminLinkCopied);
              },
              icon: const Icon(Icons.link_rounded, size: 16, color: LuxColors.accent),
              label: Text(l.hotelAdminCopyLink, style: const TextStyle(color: LuxColors.accent)),
            ),
          ]),
        ]),
      ),
    );
  }
}

class HotelEditDialog extends StatefulWidget {
  const HotelEditDialog({super.key, required this.repo, this.initial});
  final HotelRepository repo;
  final PartnerHotel? initial;

  @override
  State<HotelEditDialog> createState() => _HotelEditDialogState();
}

class _HotelEditDialogState extends State<HotelEditDialog> {
  late final PartnerHotel? _i = widget.initial;
  late final _name = TextEditingController(text: _i?.name ?? '');
  late final _meeting = TextEditingController(text: _i?.meetingPoint ?? '');
  late Place? _place = _i == null ? null : Place(address: _i.address, lat: _i.lat, lng: _i.lng);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _meeting.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final error = HotelTransfers.validate(name: _name.text, place: _place, meetingPoint: _meeting.text);
    if (error != null) {
      setState(() => _error = localizedHotelError(l, error));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repo.save(PartnerHotel(
        id: _i?.id ?? '',
        name: _name.text.trim(),
        address: _place!.address,
        lat: _place!.lat,
        lng: _place!.lng,
        meetingPoint: _meeting.text.trim(),
        active: _i?.active ?? true,
      ));
      if (!mounted) return;
      Navigator.of(context).pop();
      showLuxSnackbar(context, l.hotelAdminSaved);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l.adminActionFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      backgroundColor: LuxColors.blackElevated,
      title: Text(_i == null ? l.hotelAdminAdd : l.hotelAdminEditTitle(_i.name), style: LuxTypography.titleLarge),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LuxTextField(
                controller: _name,
                label: l.hotelAdminName,
                inputFormatters: [LengthLimitingTextInputFormatter(HotelTransfers.maxName)],
              ),
              const SizedBox(height: LuxSpacing.md),
              PlaceAutocompleteField(
                label: l.hotelAdminAddress,
                hint: l.hotelAdminAddressHint,
                prefixIcon: Icons.place_outlined,
                initialValue: _place,
                onPlaceSelected: (p) => setState(() => _place = p),
              ),
              const SizedBox(height: LuxSpacing.md),
              LuxTextField(
                controller: _meeting,
                label: l.hotelAdminMeetingPoint,
                hint: l.hotelAdminMeetingPointHint,
                inputFormatters: [LengthLimitingTextInputFormatter(HotelTransfers.maxMeetingPoint)],
              ),
              if (_error != null) ...[
                const SizedBox(height: LuxSpacing.sm),
                Text(_error!, style: LuxTypography.bodyMedium.copyWith(color: LuxColors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l.commonCancel)),
        TextButton(
          onPressed: _busy ? null : _save,
          child: Text(l.hotelAdminSave, style: const TextStyle(color: LuxColors.accent, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
