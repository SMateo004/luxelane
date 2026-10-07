import 'package:cloud_firestore/cloud_firestore.dart';

/// Documents a chauffeur must have approved to receive rides
/// (mirrors functions/src/documents.ts).
enum DriverDocType {
  license(expires: true),
  idCard(expires: true),
  criminalRecord(expires: true),
  soat(expires: true),
  vehicleRegistration(expires: false);

  const DriverDocType({required this.expires});

  /// Whether the document carries an expiry date.
  final bool expires;

  static DriverDocType? fromName(String name) {
    for (final t in values) {
      if (t.name == name) return t;
    }
    return null;
  }
}

enum DriverDocStatus { missing, pending, approved, rejected, expired }

class DriverDocument {
  const DriverDocument({
    required this.type,
    required this.status,
    this.storagePath,
    this.fileName,
    this.contentType,
    this.expiresAt,
    this.uploadedAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  /// Placeholder for a document that has not been uploaded.
  const DriverDocument.missing(this.type)
      : status = DriverDocStatus.missing,
        storagePath = null,
        fileName = null,
        contentType = null,
        expiresAt = null,
        uploadedAt = null,
        reviewedAt = null,
        rejectionReason = null;

  final DriverDocType type;
  final DriverDocStatus status;
  final String? storagePath;
  final String? fileName;
  final String? contentType;
  final DateTime? expiresAt;
  final DateTime? uploadedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  static const expiringWindow = Duration(days: 30);

  factory DriverDocument.fromJson(DriverDocType type, Map<String, dynamic> j) => DriverDocument(
        type: type,
        status: DriverDocStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => DriverDocStatus.pending,
        ),
        storagePath: j['storagePath'] as String?,
        fileName: j['fileName'] as String?,
        contentType: j['contentType'] as String?,
        expiresAt: (j['expiresAt'] as Timestamp?)?.toDate(),
        uploadedAt: (j['uploadedAt'] as Timestamp?)?.toDate(),
        reviewedAt: (j['reviewedAt'] as Timestamp?)?.toDate(),
        rejectionReason: j['rejectionReason'] as String?,
      );

  /// Status as of [now]: an approved document past its date is expired even
  /// before the daily job marks it.
  DriverDocStatus statusAt(DateTime now) =>
      status == DriverDocStatus.approved && expiresAt != null && !expiresAt!.isAfter(now)
          ? DriverDocStatus.expired
          : status;

  /// Approved and expiring within [expiringWindow].
  bool expiringSoon(DateTime now) =>
      statusAt(now) == DriverDocStatus.approved &&
      expiresAt != null &&
      expiresAt!.difference(now) <= expiringWindow;

  /// Whether the chauffeur should (re)upload this document.
  bool needsUpload(DateTime now) => switch (statusAt(now)) {
        DriverDocStatus.missing || DriverDocStatus.rejected || DriverDocStatus.expired => true,
        _ => expiringSoon(now),
      };
}

/// Where a chauffeur stands, for banners and the admin list.
class DocumentsSummary {
  DocumentsSummary(Map<DriverDocType, DriverDocument> docs, DateTime now)
      : documents = [for (final t in DriverDocType.values) docs[t] ?? DriverDocument.missing(t)],
        _now = now;

  final List<DriverDocument> documents;
  final DateTime _now;

  Iterable<DriverDocument> _with(DriverDocStatus s) => documents.where((d) => d.statusAt(_now) == s);

  int get approved => _with(DriverDocStatus.approved).length;
  int get pending => _with(DriverDocStatus.pending).length;
  int get toUpload => documents.where((d) => d.needsUpload(_now) && !d.expiringSoon(_now)).length;
  List<DriverDocument> get expiringSoon => documents.where((d) => d.expiringSoon(_now)).toList();
  bool get complete => approved == documents.length;
}

/// Error codes from reviewDriverDocument / uploads.
abstract final class DriverDocErrorCodes {
  static const expiryRequired = 'documents/expiry-required';
  static const alreadyExpired = 'documents/already-expired';
  static const reasonRequired = 'documents/reason-required';
  static const tooLarge = 'documents/too-large';
  static const failed = 'documents/failed';

  static String fromMessage(String? m) => [expiryRequired, alreadyExpired, reasonRequired]
      .firstWhere((c) => (m ?? '').contains(c), orElse: () => failed);
}
