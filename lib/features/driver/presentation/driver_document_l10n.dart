import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../domain/driver_document.dart';

extension DriverDocTypeL10n on DriverDocType {
  String localizedName(AppLocalizations l) => switch (this) {
        DriverDocType.license => l.docLicense,
        DriverDocType.idCard => l.docIdCard,
        DriverDocType.criminalRecord => l.docCriminalRecord,
        DriverDocType.soat => l.docSoat,
        DriverDocType.vehicleRegistration => l.docVehicleRegistration,
      };

  String localizedHint(AppLocalizations l) => switch (this) {
        DriverDocType.license => l.docLicenseHint,
        DriverDocType.idCard => l.docIdCardHint,
        DriverDocType.criminalRecord => l.docCriminalRecordHint,
        DriverDocType.soat => l.docSoatHint,
        DriverDocType.vehicleRegistration => l.docVehicleRegistrationHint,
      };

  IconData get icon => switch (this) {
        DriverDocType.license => Icons.badge_outlined,
        DriverDocType.idCard => Icons.perm_identity_rounded,
        DriverDocType.criminalRecord => Icons.gavel_rounded,
        DriverDocType.soat => Icons.health_and_safety_outlined,
        DriverDocType.vehicleRegistration => Icons.directions_car_outlined,
      };
}

String localizedDocError(AppLocalizations l, String code) => switch (code) {
      DriverDocErrorCodes.expiryRequired => l.docErrorExpiryRequired,
      DriverDocErrorCodes.alreadyExpired => l.docErrorAlreadyExpired,
      DriverDocErrorCodes.reasonRequired => l.docErrorReasonRequired,
      DriverDocErrorCodes.tooLarge => l.docErrorTooLarge,
      _ => l.docErrorFailed,
    };
