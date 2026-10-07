import '../../../l10n/l10n.dart';
import '../domain/company.dart';

extension CompanyRoleL10n on CompanyRole {
  String localizedLabel(AppLocalizations l) => switch (this) {
        CompanyRole.admin => l.corpRoleAdmin,
        CompanyRole.member => l.corpRoleMember,
      };
}

String localizedCompanyError(AppLocalizations l, String code) => switch (code) {
      CompanyErrorCodes.invalidName => l.corpErrorInvalidName,
      CompanyErrorCodes.invalidTaxId => l.corpErrorInvalidTaxId,
      CompanyErrorCodes.invalidEmail || CompanyErrorCodes.invalidAdminEmail => l.corpErrorInvalidEmail,
      CompanyErrorCodes.notARider => l.corpErrorNotARider,
      CompanyErrorCodes.otherCompany => l.corpErrorOtherCompany,
      CompanyErrorCodes.lastAdmin => l.corpErrorLastAdmin,
      CompanyErrorCodes.costCentersEmpty => l.corpErrorCostCentersEmpty,
      CompanyErrorCodes.inactive => l.corpErrorCompanyInactive,
      _ => l.adminActionFailed,
    };
