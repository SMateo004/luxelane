import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';

import '../../../core/error/function_errors.dart';
import '../../../core/models/models.dart';
import '../../../l10n/l10n.dart';
import '../domain/admin_driver_applications.dart';

/// Máximo de solicitudes por estado y de entradas de la bitácora que se
/// leen. Sin índice compuesto: se filtra por igualdad y se ordena aquí.
const kDriverAppInboxLimit = 200;
const kDocAccessLogLimit = 200;

/// Motivos del servidor (functions/src/driver_application.ts) en el texto
/// del panel. Nunca el texto técnico.
String driverAppErrorMessage(String code, Object? details) {
  final common = commonFunctionError(code, details);
  if (common != null) return common;
  final t = L10n.current;
  return switch (functionErrorReason(details)) {
    'documents_not_approved' => _docsNotApproved(details),
    'stale_version' => t.adminDrvAppErrStaleVersion,
    'not_reviewable' => t.adminDrvAppErrNotReviewable,
    'not_decidable' || 'application_closed' => t.adminDrvAppErrNotDecidable,
    'requirements_not_configured' => t.adminDrvAppErrRequirements,
    'steps_incomplete' => t.adminDrvAppErrStepsIncomplete,
    'document_not_found' || 'driver_not_found' => t.adminDrvAppErrNotFound,
    'invalid_request' => t.adminDrvAppErrInvalid,
    // El resto de motivos del registro: el catálogo común (B1).
    final r? when kRegistrationReasons.contains(r) =>
      registrationErrorMessage(code, details),
    _ => switch (code) {
        'permission-denied' => t.adminDrvAppErrPermission,
        'not-found' => t.adminDrvAppErrNotFound,
        'invalid-argument' => t.adminDrvAppErrInvalid,
        _ => t.adminDrvAppErrGeneric,
      },
  };
}

String _docsNotApproved(Object? details) {
  final t = L10n.current;
  final fields = (details is Map ? details['fields'] : null);
  final names = [
    if (fields is List)
      for (final f in fields)
        DriverDocType.fromWire(f)?.label ?? (f is String ? f : ''),
  ].where((s) => s.isNotEmpty).toList();
  return names.isEmpty
      ? t.adminDrvAppErrDocsNotApprovedAny
      : t.adminDrvAppErrDocsNotApproved(names.join(', '));
}

DateTime? _date(Object? v) => switch (v) {
      Timestamp() => v.toDate(),
      num() => DateTime.fromMillisecondsSinceEpoch(v.toInt()),
      _ => null,
    };

int? _ms(Object? v) => _date(v)?.millisecondsSinceEpoch;

String? _str(Object? v) => v is String && v.trim().isNotEmpty ? v : null;

/// Lectura directa de Firestore (solo admin) y escrituras por callables.
class FirebaseDriverApplicationsRepository
    implements DriverApplicationsRepository {
  FirebaseDriverApplicationsRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _dbOverride = firestore,
        _fnOverride = functions;

  final FirebaseFirestore? _dbOverride;
  final FirebaseFunctions? _fnOverride;
  FirebaseFirestore get _db => _dbOverride ?? FirebaseFirestore.instance;
  FirebaseFunctions get _fn => _fnOverride ?? FirebaseFunctions.instance;

  /// Correos de administradores ya buscados (bitácora).
  final _adminEmails = <String, String?>{};

  Future<Either<DriverAppFailure, T>> _guard<T>(Future<T> Function() f) async {
    try {
      return Right(await f());
    } on FirebaseFunctionsException catch (e) {
      return Left(DriverAppFailure(driverAppErrorMessage(e.code, e.details)));
    } catch (e) {
      return Left(DriverAppFailure(unexpectedErrorMessage(e)));
    }
  }

  Future<Object?> _call(String name, Map<String, dynamic> data) async =>
      (await _fn.httpsCallable(name).call<Object?>(data)).data;

  Future<Map<String, dynamic>?> _user(String uid) async {
    try {
      return (await _db.collection('users').doc(uid).get()).data();
    } catch (_) {
      // Sin nombre ni correo; la fila se muestra igual.
      return null;
    }
  }

  @override
  Future<Either<DriverAppFailure, DriverAppInbox>> inbox(
    DriverAppStatus status,
  ) =>
      _guard(() async {
        final snap = await _db
            .collection('driverApplications')
            .where('status', isEqualTo: status.wire)
            .limit(kDriverAppInboxLimit)
            .get();
        final items = await Future.wait(
          snap.docs.map((d) async {
            final x = d.data();
            final u = await _user(d.id);
            return DriverAppSummary(
              driverId: d.id,
              status: DriverAppStatus.fromWire(x['status']),
              name: _str(u?['displayName']),
              email: _str(u?['email']),
              submittedAt: _date(x['submittedAt']),
              updatedAt: _date(x['updatedAt']),
            );
          }),
        );
        items.sort((a, b) => b.sortKey.compareTo(a.sortKey));
        return DriverAppInbox(
          items: items,
          truncated: snap.docs.length >= kDriverAppInboxLimit,
        );
      });

  @override
  Future<Either<DriverAppFailure, DriverAppDetail>> detail(String driverId) =>
      _guard(() async {
        final ref = _db.collection('driverApplications').doc(driverId);
        final results = await Future.wait<Object?>([
          ref.get(),
          ref.collection('private').doc('data').get(),
          ref.collection('documents').get(),
          ref.collection('documentFiles').get(),
          _db.collection('config').doc('ops').get(),
          _user(driverId),
          _db
              .collection('driverProfiles')
              .doc(driverId)
              .get()
              .then<Map<String, dynamic>?>((s) => s.data())
              .catchError((Object _) => null),
        ]);
        final app =
            (results[0] as DocumentSnapshot<Map<String, dynamic>>).data() ??
                const <String, dynamic>{};
        final priv =
            (results[1] as DocumentSnapshot<Map<String, dynamic>>).data() ??
                const <String, dynamic>{};
        final docs = results[2] as QuerySnapshot<Map<String, dynamic>>;
        final files = results[3] as QuerySnapshot<Map<String, dynamic>>;
        final ops =
            (results[4] as DocumentSnapshot<Map<String, dynamic>>).data();
        final user = results[5] as Map<String, dynamic>?;
        final profile = results[6] as Map<String, dynamic>?;

        final rawReqs = ops?['driverRequirements'];
        final p = priv['personal'];
        final v = priv['vehicle'];
        return DriverAppDetail(
          driverId: driverId,
          status: DriverAppStatus.fromWire(app['status']),
          name: _str(user?['displayName']),
          email: _str(user?['email']),
          submittedAt: _date(app['submittedAt']),
          updatedAt: _date(app['updatedAt']),
          pendingVehicleId: _str(app['pendingVehicleId']),
          requirementsConfigured: rawReqs is List,
          requirements: rawReqs is List
              ? rawReqs
                  .map(DriverRequirement.fromJson)
                  .whereType<DriverRequirement>()
                  .toList()
              : const [],
          personal: p is Map
              ? DriverPersonalData.fromJson({
                  ...p,
                  'licenseExpiry': _ms(p['licenseExpiry']),
                })
              : null,
          // En Firestore el vehículo guarda capacity y class (saveDriverStep).
          vehicle: v is Map
              ? DriverVehicleData.fromJson({
                  ...v,
                  'passengers': v['capacity'] ?? v['passengers'],
                  'vehicleClass': v['class'] ?? v['vehicleClass'],
                })
              : null,
          documents: {
            for (final d in docs.docs)
              if (DriverDocument.fromJson({
                ...d.data(),
                'type': d.data()['type'] ?? d.id,
                'expiresAt': _ms(d.data()['expiresAt']),
              })
                  case final doc?)
                doc.type: doc,
          },
          files: {
            for (final f in files.docs)
              if (DriverDocType.fromWire(f.id) case final type?)
                type: DriverDocFileInfo(
                  contentType: _str(f.data()['contentType']),
                  size: (f.data()['size'] as num?)?.toInt(),
                  version: (f.data()['version'] as num?)?.toInt(),
                ),
          },
          docsBlocked: profile?['docsBlocked'] == true,
        );
      });

  @override
  Future<Either<DriverAppFailure, DocumentLink>> documentUrl(
    String driverId,
    DriverDocType type,
  ) =>
      _guard(() async {
        final d = await _call('adminGetDocumentUrl', {
          'driverId': driverId,
          'type': type.wire,
        });
        final m = d is Map ? d : const {};
        final url = m['url'];
        if (url is! String || url.isEmpty) {
          throw StateError('sin enlace'); // i18n-ignore: no se muestra
        }
        return DocumentLink(
          url: url,
          expiresAt: _date(m['expiresAt']) ??
              DateTime.now().add(const Duration(minutes: kDocumentLinkMinutes)),
          contentType: _str(m['contentType']),
        );
      });

  @override
  Future<Either<DriverAppFailure, void>> reviewDocument({
    required String driverId,
    required DriverDocType type,
    required int version,
    required bool approve,
    DocRejectReason? rejectReason,
    String? note,
  }) =>
      _guard(() async {
        final n = note?.trim() ?? '';
        await _call('adminReviewDocument', {
          'driverId': driverId,
          'type': type.wire,
          'version': version,
          'decision': approve ? 'approve' : 'reject',
          if (!approve && rejectReason != null)
            'rejectReason': rejectReason.wire,
          if (!approve && n.isNotEmpty) 'note': n,
        });
      });

  @override
  Future<Either<DriverAppFailure, void>> decide({
    required String driverId,
    required DriverAppDecision decision,
    required String reason,
  }) =>
      _guard(() async {
        await _call('adminDecideApplication', {
          'driverId': driverId,
          'decision': decision.wire,
          'reason': reason.trim(),
        });
      });

  @override
  Future<Either<DriverAppFailure, List<DocAccessEntry>>> accessLog(
    String driverId,
  ) =>
      _guard(() async {
        final snap = await _db
            .collection('driverDocAccessLogs')
            .where('driverId', isEqualTo: driverId)
            .limit(kDocAccessLogLimit)
            .get();
        final out = <DocAccessEntry>[];
        for (final d in snap.docs) {
          final x = d.data();
          final adminId = (x['adminId'] as String?) ?? '';
          var email = _str(x['adminEmail']);
          if (email == null && adminId.isNotEmpty) {
            email = _adminEmails.containsKey(adminId)
                ? _adminEmails[adminId]
                : _adminEmails[adminId] =
                    _str((await _user(adminId))?['email']);
          }
          out.add(
            DocAccessEntry(
              adminId: adminId,
              adminEmail: email,
              type: DriverDocType.fromWire(x['type']),
              typeWire: _str(x['type']),
              version: (x['version'] as num?)?.toInt(),
              at: _date(x['at']),
            ),
          );
        }
        final zero = DateTime.fromMillisecondsSinceEpoch(0);
        out.sort((a, b) => (b.at ?? zero).compareTo(a.at ?? zero));
        return out;
      });

  @override
  Future<Either<DriverAppFailure, DocExpiries>> expiries(int days) =>
      _guard(() async {
        final d = await _call('adminListDocExpiries', {'days': days});
        final m = d is Map ? d : const {};
        final raw = m['items'] is List ? m['items'] as List : const [];
        final ids = {
          for (final i in raw)
            if (i is Map && i['driverId'] is String) i['driverId'] as String,
        };
        final info = {
          for (final e in await Future.wait(
            ids.map((id) async {
              final u = await _user(id);
              Map<String, dynamic>? p;
              try {
                p = (await _db.collection('driverProfiles').doc(id).get())
                    .data();
              } catch (_) {
                p = null;
              }
              return MapEntry(id, (u, p));
            }),
          ))
            e.key: e.value,
        };
        return DocExpiries(
          truncated: m['truncated'] == true,
          items: [
            for (final i in raw)
              if (i is Map &&
                  i['driverId'] is String &&
                  _date(i['expiresAt']) != null)
                DocExpiryItem(
                  driverId: i['driverId'] as String,
                  type: DriverDocType.fromWire(i['type']),
                  status: DriverDocStatus.fromWire(i['status']),
                  expiresAt: _date(i['expiresAt'])!,
                  name: _str(info[i['driverId']]?.$1?['displayName']),
                  email: _str(info[i['driverId']]?.$1?['email']),
                  docsBlocked: info[i['driverId']]?.$2?['docsBlocked'] == true,
                ),
          ],
        );
      });

  @override
  Future<Either<DriverAppFailure, void>> allowOnline({
    required String driverId,
    required String reason,
  }) =>
      _guard(() async {
        await _call('adminAllowDriverOnline', {
          'driverId': driverId,
          'reason': reason.trim(),
        });
      });
}
