import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/error/function_errors.dart';
import '../../../core/models/models.dart';

/// Solicitudes de chófer en el panel (B2). El panel lee Firestore
/// directamente (reglas: solo admin) y escribe solo por las callables, que
/// piden segundo factor y, para decidir, una identificación reciente.
///
/// Los datos personales (documento, licencia) se muestran al admin pero
/// nunca se escriben en logs; la URL firmada de un documento tampoco.

/// Motivo de las decisiones del admin: lo mismo que reasonSchema del
/// servidor (functions/src/admin_audit.ts).
const kDriverAppReasonMin = 10;
const kDriverAppReasonMax = 500;

/// Lo que dura el enlace firmado de un documento (URL_TTL_MS del servidor).
const kDocumentLinkMinutes = 5;

/// Fallo de una acción del panel de solicitudes. [needsReauth]: el servidor
/// pidió volver a identificarse (reauth_required).
class DriverAppFailure extends Failure {
  const DriverAppFailure(super.message);

  bool get needsReauth => message == kReauthRequiredMessage;
}

/// Una fila de la bandeja.
class DriverAppSummary {
  const DriverAppSummary({
    required this.driverId,
    required this.status,
    this.name,
    this.email,
    this.submittedAt,
    this.updatedAt,
  });

  final String driverId;
  final DriverAppStatus status;
  final String? name;
  final String? email;
  final DateTime? submittedAt;
  final DateTime? updatedAt;

  /// Orden de la bandeja: lo más reciente primero.
  DateTime get sortKey =>
      submittedAt ?? updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
}

class DriverAppInbox {
  const DriverAppInbox({required this.items, this.truncated = false});
  final List<DriverAppSummary> items;
  final bool truncated;
}

/// Metadatos del archivo de un documento. Sin ruta ni URL: no se muestran.
class DriverDocFileInfo {
  const DriverDocFileInfo({this.contentType, this.size, this.version});
  final String? contentType;
  final int? size;
  final int? version;

  bool get isPdf => contentType == 'application/pdf';
}

/// Una fila de la lista de documentos del detalle.
class DriverDocRow {
  const DriverDocRow({
    required this.type,
    this.requirement,
    this.document,
    this.file,
  });

  final DriverDocType type;

  /// null: el documento está subido pero no figura en los requisitos.
  final DriverRequirement? requirement;
  final DriverDocument? document;
  final DriverDocFileInfo? file;

  DriverDocStatus get status =>
      document?.status ?? DriverDocStatus.pendingUpload;
  int get version => document?.version ?? 0;

  /// Hay un archivo que ver.
  bool get viewable => file != null || version > 0;

  /// El servidor revisa uploaded, approved y rejected (adminReviewDocument).
  bool get canApprove =>
      version > 0 &&
      (status == DriverDocStatus.uploaded ||
          status == DriverDocStatus.rejected);
  bool get canReject =>
      version > 0 &&
      (status == DriverDocStatus.uploaded ||
          status == DriverDocStatus.approved);
}

class DriverAppDetail {
  const DriverAppDetail({
    required this.driverId,
    required this.status,
    this.name,
    this.email,
    this.submittedAt,
    this.updatedAt,
    this.pendingVehicleId,
    required this.requirementsConfigured,
    this.requirements = const [],
    this.personal,
    this.vehicle,
    this.documents = const {},
    this.files = const {},
    this.docsBlocked = false,
  });

  final String driverId;
  final DriverAppStatus status;
  final String? name;
  final String? email;
  final DateTime? submittedAt;
  final DateTime? updatedAt;
  final String? pendingVehicleId;
  final bool requirementsConfigured;
  final List<DriverRequirement> requirements;
  final DriverPersonalData? personal;
  final DriverVehicleData? vehicle;
  final Map<DriverDocType, DriverDocument> documents;
  final Map<DriverDocType, DriverDocFileInfo> files;
  final bool docsBlocked;

  /// Solo estas admiten decisión final (adminDecideApplication).
  bool get decidable =>
      status == DriverAppStatus.submitted ||
      status == DriverAppStatus.inReview ||
      status == DriverAppStatus.needsChanges;

  /// Los requisitos en su orden y, después, lo subido que no figura en ellos.
  List<DriverDocRow> get rows {
    final listed = {for (final r in requirements) r.type};
    return [
      for (final r in requirements)
        DriverDocRow(
          type: r.type,
          requirement: r,
          document: documents[r.type],
          file: files[r.type],
        ),
      for (final t in DriverDocType.values)
        if (!listed.contains(t) && (documents[t] != null || files[t] != null))
          DriverDocRow(type: t, document: documents[t], file: files[t]),
    ];
  }
}

/// Enlace firmado de pocos minutos. No se guarda ni se imprime: toString
/// lo oculta para que no acabe en un log por descuido.
class DocumentLink {
  const DocumentLink({
    required this.url,
    required this.expiresAt,
    this.contentType,
  });

  final String url;
  final DateTime expiresAt;
  final String? contentType;

  bool get isPdf => contentType == 'application/pdf';

  @override
  String toString() => 'DocumentLink(oculto)'; // i18n-ignore: solo depuración
}

/// Una apertura de documento (driverDocAccessLogs).
class DocAccessEntry {
  const DocAccessEntry({
    required this.adminId,
    this.adminEmail,
    this.type,
    this.typeWire,
    this.version,
    this.at,
  });

  final String adminId;
  final String? adminEmail;
  final DriverDocType? type;
  final String? typeWire;
  final int? version;
  final DateTime? at;
}

/// Un documento que vence pronto (adminListDocExpiries).
class DocExpiryItem {
  const DocExpiryItem({
    required this.driverId,
    required this.type,
    required this.status,
    required this.expiresAt,
    this.name,
    this.email,
    this.docsBlocked = false,
  });

  final String driverId;
  final DriverDocType? type;
  final DriverDocStatus status;
  final DateTime expiresAt;
  final String? name;
  final String? email;
  final bool docsBlocked;
}

class DocExpiries {
  const DocExpiries({required this.items, this.truncated = false});
  final List<DocExpiryItem> items;
  final bool truncated;
}

enum DriverAppDecision {
  approve('approve'),
  needsChanges('needs_changes'),
  reject('reject');

  const DriverAppDecision(this.wire);
  final String wire;

  DriverAppStatus get result => switch (this) {
        approve => DriverAppStatus.approved,
        needsChanges => DriverAppStatus.needsChanges,
        reject => DriverAppStatus.rejected,
      };
}

abstract class DriverApplicationsRepository {
  Future<Either<DriverAppFailure, DriverAppInbox>> inbox(
    DriverAppStatus status,
  );

  Future<Either<DriverAppFailure, DriverAppDetail>> detail(String driverId);

  /// adminGetDocumentUrl: cada llamada queda en la bitácora del servidor.
  Future<Either<DriverAppFailure, DocumentLink>> documentUrl(
    String driverId,
    DriverDocType type,
  );

  Future<Either<DriverAppFailure, void>> reviewDocument({
    required String driverId,
    required DriverDocType type,
    required int version,
    required bool approve,
    DocRejectReason? rejectReason,
    String? note,
  });

  Future<Either<DriverAppFailure, void>> decide({
    required String driverId,
    required DriverAppDecision decision,
    required String reason,
  });

  Future<Either<DriverAppFailure, List<DocAccessEntry>>> accessLog(
    String driverId,
  );

  Future<Either<DriverAppFailure, DocExpiries>> expiries(int days);

  Future<Either<DriverAppFailure, void>> allowOnline({
    required String driverId,
    required String reason,
  });
}
