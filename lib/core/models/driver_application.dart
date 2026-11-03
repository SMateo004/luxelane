import '../../l10n/l10n.dart';

/// Registro de chóferes: las mismas listas cerradas que el servidor
/// (functions/src/driver_application.ts). Qué documentos son obligatorios
/// y cuáles vencen NO está aquí: sale de config/ops.driverRequirements y
/// llega con la solicitud (getDriverApplication).

/// Tipos de documento. [pdf]: el servidor también admite PDF (la app solo
/// sube fotos: no hay selector de archivos). [cameraOnly]: solo cámara,
/// sin galería (decisión 3). [frontCamera]: se abre la cámara frontal.
enum DriverDocType {
  profilePhoto('profile_photo'),
  livePhoto('live_photo', cameraOnly: true, frontCamera: true),
  nationalIdFront('national_id_front'),
  nationalIdBack('national_id_back'),
  licenseFront('license_front'),
  licenseBack('license_back'),
  criminalRecord('criminal_record', pdf: true),
  vehicleOwnership('vehicle_ownership', pdf: true),
  vehicleSoat('vehicle_soat', pdf: true),
  vehicleInspection('vehicle_inspection', pdf: true),
  vehicleInsurance('vehicle_insurance', pdf: true),
  vehiclePermit('vehicle_permit', pdf: true),
  ownerAuthorization('owner_authorization', pdf: true),
  vehiclePhotoFront('vehicle_photo_front', vehiclePhoto: true),
  vehiclePhotoBack('vehicle_photo_back', vehiclePhoto: true),
  vehiclePhotoLeft('vehicle_photo_left', vehiclePhoto: true),
  vehiclePhotoRight('vehicle_photo_right', vehiclePhoto: true),
  vehiclePhotoInteriorFront('vehicle_photo_interior_front', vehiclePhoto: true),
  vehiclePhotoInteriorBack('vehicle_photo_interior_back', vehiclePhoto: true),
  vehiclePhotoPlate('vehicle_photo_plate', vehiclePhoto: true);

  const DriverDocType(
    this.wire, {
    this.pdf = false,
    this.cameraOnly = false,
    this.frontCamera = false,
    this.vehiclePhoto = false,
  });

  final String wire;
  final bool pdf;
  final bool cameraOnly;
  final bool frontCamera;
  final bool vehiclePhoto;

  static DriverDocType? fromWire(Object? raw) =>
      values.where((t) => t.wire == raw).firstOrNull;

  String get label {
    final t = L10n.current;
    return switch (this) {
      profilePhoto => t.regDocTypeProfilePhoto,
      livePhoto => t.regDocTypeLivePhoto,
      nationalIdFront => t.regDocTypeNationalIdFront,
      nationalIdBack => t.regDocTypeNationalIdBack,
      licenseFront => t.regDocTypeLicenseFront,
      licenseBack => t.regDocTypeLicenseBack,
      criminalRecord => t.regDocTypeCriminalRecord,
      vehicleOwnership => t.regDocTypeVehicleOwnership,
      vehicleSoat => t.regDocTypeVehicleSoat,
      vehicleInspection => t.regDocTypeVehicleInspection,
      vehicleInsurance => t.regDocTypeVehicleInsurance,
      vehiclePermit => t.regDocTypeVehiclePermit,
      ownerAuthorization => t.regDocTypeOwnerAuthorization,
      vehiclePhotoFront => t.regDocTypeVehiclePhotoFront,
      vehiclePhotoBack => t.regDocTypeVehiclePhotoBack,
      vehiclePhotoLeft => t.regDocTypeVehiclePhotoLeft,
      vehiclePhotoRight => t.regDocTypeVehiclePhotoRight,
      vehiclePhotoInteriorFront => t.regDocTypeVehiclePhotoInteriorFront,
      vehiclePhotoInteriorBack => t.regDocTypeVehiclePhotoInteriorBack,
      vehiclePhotoPlate => t.regDocTypeVehiclePhotoPlate,
    };
  }
}

enum DriverAppStatus {
  draft('draft'),
  submitted('submitted'),
  inReview('in_review'),
  needsChanges('needs_changes'),
  approved('approved'),
  rejected('rejected');

  const DriverAppStatus(this.wire);
  final String wire;

  static DriverAppStatus fromWire(Object? raw) =>
      values.where((s) => s.wire == raw).firstOrNull ?? draft;

  /// El chófer aún puede cambiar datos y documentos.
  bool get editable => this == draft || this == needsChanges;

  String get label {
    final t = L10n.current;
    return switch (this) {
      draft => t.regAppStatusDraft,
      submitted => t.regAppStatusSubmitted,
      inReview => t.regAppStatusInReview,
      needsChanges => t.regAppStatusNeedsChanges,
      approved => t.regAppStatusApproved,
      rejected => t.regAppStatusRejected,
    };
  }
}

enum DriverDocStatus {
  pendingUpload('pending_upload'),
  uploaded('uploaded'),
  approved('approved'),
  rejected('rejected'),
  expired('expired');

  const DriverDocStatus(this.wire);
  final String wire;

  static DriverDocStatus fromWire(Object? raw) =>
      values.where((s) => s.wire == raw).firstOrNull ?? pendingUpload;

  /// Hay que (volver a) subirlo.
  bool get needsUpload =>
      this == pendingUpload || this == rejected || this == expired;

  String get label {
    final t = L10n.current;
    return switch (this) {
      pendingUpload => t.regDocStatusPendingUpload,
      uploaded => t.regDocStatusUploaded,
      approved => t.regDocStatusApproved,
      rejected => t.regDocStatusRejected,
      expired => t.regDocStatusExpired,
    };
  }
}

enum DocRejectReason {
  illegible('illegible'),
  expired('expired'),
  wrongDocument('wrong_document'),
  incomplete('incomplete'),
  dataMismatch('data_mismatch'),
  lowQuality('low_quality'),
  other('other');

  const DocRejectReason(this.wire);
  final String wire;

  static DocRejectReason? fromWire(Object? raw) =>
      values.where((r) => r.wire == raw).firstOrNull;

  String get label {
    final t = L10n.current;
    return switch (this) {
      illegible => t.regRejectIllegible,
      expired => t.regRejectExpired,
      wrongDocument => t.regRejectWrongDocument,
      incomplete => t.regRejectIncomplete,
      dataMismatch => t.regRejectDataMismatch,
      lowQuality => t.regRejectLowQuality,
      other => t.regRejectOther,
    };
  }
}

enum VehicleColorOption {
  black('black'),
  white('white'),
  silver('silver'),
  gray('gray'),
  blue('blue'),
  red('red'),
  green('green'),
  beige('beige'),
  brown('brown'),
  other('other');

  const VehicleColorOption(this.wire);
  final String wire;

  static VehicleColorOption? fromWire(Object? raw) =>
      values.where((c) => c.wire == raw).firstOrNull;

  String get label {
    final t = L10n.current;
    return switch (this) {
      black => t.regColorBlack,
      white => t.regColorWhite,
      silver => t.regColorSilver,
      gray => t.regColorGray,
      blue => t.regColorBlue,
      red => t.regColorRed,
      green => t.regColorGreen,
      beige => t.regColorBeige,
      brown => t.regColorBrown,
      other => t.regColorOther,
    };
  }
}

enum VehicleBodyType {
  sedan('sedan'),
  suv('suv'),
  van('van');

  const VehicleBodyType(this.wire);
  final String wire;

  static VehicleBodyType? fromWire(Object? raw) =>
      values.where((b) => b.wire == raw).firstOrNull;

  String get label {
    final t = L10n.current;
    return switch (this) {
      sedan => t.regBodySedan,
      suv => t.regBodySuv,
      van => t.regBodyVan,
    };
  }
}

/// Un requisito de config/ops.driverRequirements.
class DriverRequirement {
  const DriverRequirement({
    required this.type,
    required this.required,
    required this.expires,
  });

  final DriverDocType type;
  final bool required;
  final bool expires;

  static DriverRequirement? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final type = DriverDocType.fromWire(raw['type']);
    if (type == null) return null;
    return DriverRequirement(
      type: type,
      required: raw['required'] == true,
      expires: raw['expires'] == true,
    );
  }
}

/// Estado de un documento (sin ruta ni URL: el chófer no los ve).
class DriverDocument {
  const DriverDocument({
    required this.type,
    required this.status,
    required this.version,
    this.expiresAt,
    this.rejectReason,
    this.rejectNote,
  });

  final DriverDocType type;
  final DriverDocStatus status;
  final int version;
  final DateTime? expiresAt;
  final DocRejectReason? rejectReason;
  final String? rejectNote;

  static DateTime? _ms(Object? v) =>
      v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;

  static DriverDocument? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final type = DriverDocType.fromWire(raw['type']);
    if (type == null) return null;
    final note = raw['rejectNote'];
    return DriverDocument(
      type: type,
      status: DriverDocStatus.fromWire(raw['status']),
      version: (raw['version'] as num?)?.toInt() ?? 0,
      expiresAt: _ms(raw['expiresAt']),
      rejectReason: DocRejectReason.fromWire(raw['rejectReason']),
      rejectNote: note is String && note.isNotEmpty ? note : null,
    );
  }
}

/// Datos personales guardados (solo los recupera el propio chófer).
class DriverPersonalData {
  const DriverPersonalData({
    required this.fullName,
    required this.nationalIdNumber,
    required this.licenseNumber,
    required this.licenseExpiry,
  });

  final String fullName;
  final String nationalIdNumber;
  final String licenseNumber;
  final DateTime licenseExpiry;

  Map<String, dynamic> toStep() => {
        'step': 'personal',
        'fullName': fullName,
        'nationalIdNumber': nationalIdNumber,
        'licenseNumber': licenseNumber,
        'licenseExpiry': licenseExpiry.millisecondsSinceEpoch,
      };

  static DriverPersonalData? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final exp = raw['licenseExpiry'];
    return DriverPersonalData(
      fullName: (raw['fullName'] as String?) ?? '',
      nationalIdNumber: (raw['nationalIdNumber'] as String?) ?? '',
      licenseNumber: (raw['licenseNumber'] as String?) ?? '',
      licenseExpiry: exp is num
          ? DateTime.fromMillisecondsSinceEpoch(exp.toInt())
          : DateTime.now(),
    );
  }
}

class DriverVehicleData {
  const DriverVehicleData({
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    this.colorOther,
    required this.plate,
    required this.bodyType,
    required this.passengers,
    required this.vehicleClass,
  });

  final String make;
  final String model;
  final int year;
  final VehicleColorOption color;
  final String? colorOther;
  final String plate;
  final VehicleBodyType bodyType;
  final int passengers;

  /// Clase de servicio (wire de VehicleClass: business, first, …).
  final String vehicleClass;

  String get colorLabel =>
      color == VehicleColorOption.other && (colorOther ?? '').isNotEmpty
          ? colorOther!
          : color.label;

  Map<String, dynamic> toStep() => {
        'step': 'vehicle',
        'make': make,
        'model': model,
        'year': year,
        'color': color.wire,
        if (color == VehicleColorOption.other) 'colorOther': colorOther ?? '',
        'plate': plate,
        'bodyType': bodyType.wire,
        'passengers': passengers,
        'vehicleClass': vehicleClass,
      };

  static DriverVehicleData? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final other = raw['colorOther'];
    return DriverVehicleData(
      make: (raw['make'] as String?) ?? '',
      model: (raw['model'] as String?) ?? '',
      year: (raw['year'] as num?)?.toInt() ?? 0,
      color:
          VehicleColorOption.fromWire(raw['color']) ?? VehicleColorOption.other,
      colorOther: other is String && other.isNotEmpty ? other : null,
      plate: (raw['plate'] as String?) ?? '',
      bodyType:
          VehicleBodyType.fromWire(raw['bodyType']) ?? VehicleBodyType.sedan,
      passengers: (raw['passengers'] as num?)?.toInt() ?? 1,
      vehicleClass: (raw['vehicleClass'] as String?) ?? 'business',
    );
  }
}

/// Lo que devuelve getDriverApplication.
class DriverApplication {
  const DriverApplication({
    required this.status,
    required this.step,
    required this.requirementsConfigured,
    required this.requirements,
    this.personal,
    this.vehicle,
    required this.documents,
  });

  static const empty = DriverApplication(
    status: DriverAppStatus.draft,
    step: 'personal',
    requirementsConfigured: false,
    requirements: [],
    documents: {},
  );

  final DriverAppStatus status;
  final String step;
  final bool requirementsConfigured;
  final List<DriverRequirement> requirements;
  final DriverPersonalData? personal;
  final DriverVehicleData? vehicle;
  final Map<DriverDocType, DriverDocument> documents;

  DriverDocument? doc(DriverDocType t) => documents[t];

  /// Versión que toca subir para [t] (la actual + 1).
  int nextVersion(DriverDocType t) => (documents[t]?.version ?? 0) + 1;

  /// Tipos que se piden: los configurados, en el orden de la lista.
  List<DriverDocType> get requestedTypes =>
      [for (final r in requirements) r.type];

  DriverRequirement? requirementFor(DriverDocType t) =>
      requirements.where((r) => r.type == t).firstOrNull;

  /// Obligatorios que faltan o hay que volver a subir.
  List<DriverDocType> get missingRequired => [
        for (final r in requirements)
          if (r.required &&
              (documents[r.type] == null ||
                  documents[r.type]!.status.needsUpload))
            r.type,
      ];

  bool get canSubmit =>
      requirementsConfigured &&
      status.editable &&
      personal != null &&
      vehicle != null &&
      missingRequired.isEmpty;

  factory DriverApplication.fromJson(Object? raw) {
    if (raw is! Map) return empty;
    final reqs = raw['requirements'];
    final docs = raw['documents'];
    return DriverApplication(
      status: DriverAppStatus.fromWire(raw['status']),
      step: (raw['step'] as String?) ?? 'personal',
      requirementsConfigured: raw['requirementsConfigured'] == true,
      requirements: reqs is List
          ? reqs
              .map(DriverRequirement.fromJson)
              .whereType<DriverRequirement>()
              .toList()
          : const [],
      personal: DriverPersonalData.fromJson(raw['personal']),
      vehicle: DriverVehicleData.fromJson(raw['vehicle']),
      documents: {
        if (docs is List)
          for (final d
              in docs.map(DriverDocument.fromJson).whereType<DriverDocument>())
            d.type: d,
      },
    );
  }
}
