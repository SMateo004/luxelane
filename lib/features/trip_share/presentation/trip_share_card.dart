import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/env.dart';
import '../../../core/di/injection.dart';
import '../../../core/widgets/components.dart';
import '../../../l10n/l10n.dart';
import '../data/trip_share_repository.dart';
import 'trip_share_cubit.dart';

/// Dirección pública del enlace: en la web, la de la propia página; en el
/// móvil, PUBLIC_WEB_BASE_URL. Vacía: no se ofrece compartir.
String tripShareBaseUrl() =>
    kIsWeb ? Uri.base.origin : AppConfig.publicWebBaseUrl.trim();

/// «Compartir viaje» en el viaje del pasajero (Prompt 18, C1): explica qué
/// verá quien reciba el enlace, abre la hoja del sistema y muestra «Enlace
/// activo» con «Dejar de compartir».
class TripShareCard extends StatelessWidget {
  const TripShareCard({
    super.key,
    required this.bookingId,
    this.repository,
    this.baseUrl,
    this.onShare,
  });

  final String bookingId;
  final TripShareRepository? repository;

  /// Para pruebas: dirección pública y hoja de compartir.
  final String? baseUrl;
  final Future<void> Function(String text)? onShare;

  @override
  Widget build(BuildContext context) {
    final repo = repository ??
        (sl.isRegistered<TripShareRepository>()
            ? sl<TripShareRepository>()
            : null);
    if (repo == null) return const SizedBox.shrink();
    return BlocProvider(
      key: ValueKey('trip-share-$bookingId'),
      create: (_) => TripShareCubit(repo, bookingId)..load(),
      child: _Card(
          base: baseUrl ?? tripShareBaseUrl(),
          onShare: onShare ?? (t) => Share.share(t)),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.base, required this.onShare});
  final String base;
  final Future<void> Function(String text) onShare;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return BlocConsumer<TripShareCubit, TripShareState>(
      listenWhen: (a, b) => b.shareSeq != a.shareSeq && b.sharePath != null,
      listener: (context, s) =>
          onShare(t.tripShareMessage('$base${s.sharePath}')),
      builder: (context, s) {
        final cubit = context.read<TripShareCubit>();
        final busy = s.status == TripShareStatus.working;
        final children = <Widget>[
          Semantics(
            header: true,
            child: Text(t.tripShareTitle, style: LuxTypography.titleMedium),
          ),
          const SizedBox(height: LuxSpacing.sm),
        ];
        if (base.isEmpty) {
          children.add(
              Text(t.tripShareUnavailable, style: LuxTypography.bodyMedium));
        } else if (s.status == TripShareStatus.loading) {
          children.add(Semantics(
            liveRegion: true,
            child: Text(t.tripShareLoading, style: LuxTypography.bodyMedium),
          ));
        } else if (s.status == TripShareStatus.error) {
          children.addAll([
            Semantics(
              liveRegion: true,
              child: Text(s.message ?? '', style: LuxTypography.bodyMedium),
            ),
            const SizedBox(height: LuxSpacing.sm),
            LuxOutlinedButton(label: t.rideRetry, onPressed: cubit.load),
          ]);
        } else if (s.status == TripShareStatus.active) {
          children.addAll([
            Semantics(
              liveRegion: true,
              child: Row(children: [
                const ExcludeSemantics(
                  child: Icon(Icons.link_rounded,
                      size: 18, color: LuxColors.success),
                ),
                const SizedBox(width: LuxSpacing.xs),
                Text(t.tripShareActive, style: LuxTypography.titleMedium),
              ]),
            ),
            const SizedBox(height: LuxSpacing.xs),
            Text(t.tripShareActiveBody, style: LuxTypography.bodyMedium),
            const SizedBox(height: LuxSpacing.md),
            LuxOutlinedButton(
              label: t.tripShareStop,
              onPressed: busy ? null : cubit.stop,
            ),
            const SizedBox(height: LuxSpacing.sm),
            LuxButton.ghost(
              label: t.tripShareNew,
              onPressed: busy ? null : cubit.share,
            ),
            Text(t.tripShareNewNote, style: LuxTypography.caption),
          ]);
        } else {
          children.addAll([
            Text(t.tripShareExplain, style: LuxTypography.bodyMedium),
            const SizedBox(height: LuxSpacing.md),
            LuxButton(
              label: t.tripShareButton,
              icon: Icons.ios_share_rounded,
              loading: busy,
              onPressed: busy ? null : cubit.share,
            ),
          ]);
        }
        return LuxCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        );
      },
    );
  }
}
