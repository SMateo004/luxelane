import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/app/theme/app_theme.dart';
import 'package:luxelane/core/models/models.dart';
import 'package:luxelane/features/admin/domain/admin_driver_applications.dart';

/// Datos de PRUEBA, ficticios. Repositorio falso del panel de solicitudes
/// de chófer: responde lo que se le fija y anota cada llamada.
class FakeDriverAppsRepo implements DriverApplicationsRepository {
  Map<DriverAppStatus, Either<DriverAppFailure, DriverAppInbox>> inboxes = {};
  Either<DriverAppFailure, DriverAppDetail>? detailAnswer;
  Either<DriverAppFailure, DocumentLink> linkAnswer = Right(
    DocumentLink(
      url: kFakeSignedUrl,
      expiresAt: DateTime(2030),
      contentType: 'image/jpeg',
    ),
  );
  Either<DriverAppFailure, void> reviewAnswer = const Right(null);
  List<Either<DriverAppFailure, void>> decideAnswers = [];
  Either<DriverAppFailure, List<DocAccessEntry>> logAnswer = const Right([]);
  Either<DriverAppFailure, DocExpiries> expiriesAnswer =
      const Right(DocExpiries(items: []));
  Either<DriverAppFailure, void> allowAnswer = const Right(null);

  final inboxCalls = <DriverAppStatus>[];
  final detailCalls = <String>[];
  final urlCalls = <(String, DriverDocType)>[];
  final reviewCalls = <Map<String, Object?>>[];
  final decideCalls = <Map<String, Object?>>[];
  final logCalls = <String>[];
  final expiriesCalls = <int>[];
  final allowCalls = <Map<String, Object?>>[];

  @override
  Future<Either<DriverAppFailure, DriverAppInbox>> inbox(
    DriverAppStatus status,
  ) async {
    inboxCalls.add(status);
    return inboxes[status] ?? const Right(DriverAppInbox(items: []));
  }

  @override
  Future<Either<DriverAppFailure, DriverAppDetail>> detail(
    String driverId,
  ) async {
    detailCalls.add(driverId);
    return detailAnswer ?? Right(fakeDetail());
  }

  @override
  Future<Either<DriverAppFailure, DocumentLink>> documentUrl(
    String driverId,
    DriverDocType type,
  ) async {
    urlCalls.add((driverId, type));
    return linkAnswer;
  }

  @override
  Future<Either<DriverAppFailure, void>> reviewDocument({
    required String driverId,
    required DriverDocType type,
    required int version,
    required bool approve,
    DocRejectReason? rejectReason,
    String? note,
  }) async {
    reviewCalls.add({
      'driverId': driverId,
      'type': type,
      'version': version,
      'approve': approve,
      'rejectReason': rejectReason,
      'note': note,
    });
    return reviewAnswer;
  }

  @override
  Future<Either<DriverAppFailure, void>> decide({
    required String driverId,
    required DriverAppDecision decision,
    required String reason,
  }) async {
    decideCalls.add({
      'driverId': driverId,
      'decision': decision,
      'reason': reason,
    });
    return decideAnswers.isEmpty
        ? const Right(null)
        : decideAnswers.removeAt(0);
  }

  @override
  Future<Either<DriverAppFailure, List<DocAccessEntry>>> accessLog(
    String driverId,
  ) async {
    logCalls.add(driverId);
    return logAnswer;
  }

  @override
  Future<Either<DriverAppFailure, DocExpiries>> expiries(int days) async {
    expiriesCalls.add(days);
    return expiriesAnswer;
  }

  @override
  Future<Either<DriverAppFailure, void>> allowOnline({
    required String driverId,
    required String reason,
  }) async {
    allowCalls.add({'driverId': driverId, 'reason': reason});
    return allowAnswer;
  }
}

/// Enlace firmado ficticio: nunca debe verse como texto.
const kFakeSignedUrl =
    'https://storage.example.test/firmado/doc.jpg?X-Goog-Signature=ficticia';

DriverAppSummary fakeSummary(
  String id, {
  DriverAppStatus status = DriverAppStatus.submitted,
  String? name,
  String? email,
  DateTime? submittedAt,
}) =>
    DriverAppSummary(
      driverId: id,
      status: status,
      name: name,
      email: email,
      submittedAt: submittedAt,
    );

DriverAppDetail fakeDetail({
  bool requirementsConfigured = true,
  DriverAppStatus status = DriverAppStatus.submitted,
  Map<DriverDocType, DriverDocument>? documents,
  Map<DriverDocType, DriverDocFileInfo>? files,
}) =>
    DriverAppDetail(
      driverId: 'chofer-1',
      status: status,
      name: 'Luis Prueba',
      email: 'luis@example.com',
      submittedAt: DateTime(2026, 10, 20, 9, 30),
      requirementsConfigured: requirementsConfigured,
      requirements: requirementsConfigured
          ? const [
              DriverRequirement(
                type: DriverDocType.licenseFront,
                required: true,
                expires: true,
              ),
              DriverRequirement(
                type: DriverDocType.criminalRecord,
                required: true,
                expires: false,
              ),
              DriverRequirement(
                type: DriverDocType.vehicleSoat,
                required: false,
                expires: true,
              ),
            ]
          : const [],
      personal: DriverPersonalData(
        fullName: 'Luis Prueba Ficticio',
        nationalIdNumber: '0000000 LP',
        licenseNumber: 'LIC-PRUEBA-1',
        licenseExpiry: DateTime(2028, 5, 31),
      ),
      vehicle: const DriverVehicleData(
        make: 'MarcaX',
        model: 'ModeloY',
        year: 2022,
        color: VehicleColorOption.black,
        plate: '0000-ZZZ',
        bodyType: VehicleBodyType.sedan,
        passengers: 4,
        vehicleClass: 'business',
      ),
      documents: documents ??
          {
            DriverDocType.licenseFront: DriverDocument(
              type: DriverDocType.licenseFront,
              status: DriverDocStatus.uploaded,
              version: 2,
              expiresAt: DateTime(2028, 5, 31),
            ),
            DriverDocType.criminalRecord: const DriverDocument(
              type: DriverDocType.criminalRecord,
              status: DriverDocStatus.rejected,
              version: 1,
              rejectReason: DocRejectReason.illegible,
              rejectNote: 'Se ve borroso',
            ),
          },
      files: files ??
          const {
            DriverDocType.licenseFront: DriverDocFileInfo(
              contentType: 'image/jpeg',
              version: 2,
            ),
            DriverDocType.criminalRecord: DriverDocFileInfo(
              contentType: 'application/pdf',
              version: 1,
            ),
          },
    );

/// Monta [child] a [width] px (y [textScale]) con el tema de la app.
Future<void> pumpPanel(
  WidgetTester t,
  Widget child, {
  double width = 1280,
  double height = 1000,
  double textScale = 1,
}) async {
  t.view.physicalSize = Size(width, height);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: luxTheme,
      // Encima del Navigator: también los diálogos van con [textScale].
      builder: (context, nav) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: nav!,
      ),
      home: Scaffold(body: child),
    ),
  );
  await t.pumpAndSettle();
}
