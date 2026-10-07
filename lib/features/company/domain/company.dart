import 'package:cloud_firestore/cloud_firestore.dart';

/// Corporate account: rides of its members are invoiced to it monthly.
class Company {
  const Company({
    required this.id,
    required this.name,
    required this.taxId,
    required this.billingEmail,
    this.active = true,
    this.costCenters = const [],
    this.requireCostCenter = false,
    this.createdAt,
  });

  final String id;
  final String name;

  /// NIT used on the monthly invoice.
  final String taxId;
  final String billingEmail;
  final bool active;
  final List<String> costCenters;
  final bool requireCostCenter;
  final DateTime? createdAt;

  factory Company.fromJson(String id, Map<String, dynamic> j) => Company(
        id: id,
        name: j['name'] as String? ?? '',
        taxId: j['taxId'] as String? ?? '',
        billingEmail: j['billingEmail'] as String? ?? '',
        active: j['active'] as bool? ?? true,
        costCenters: List<String>.from(j['costCenters'] as List? ?? const []),
        requireCostCenter: j['requireCostCenter'] as bool? ?? false,
        createdAt: (j['createdAt'] as Timestamp?)?.toDate(),
      );
}

enum CompanyRole { admin, member }

/// The signed-in rider's link to a company (users/{uid}.companyId/companyRole).
class CompanyMembership {
  const CompanyMembership(this.companyId, this.role);
  final String companyId;
  final CompanyRole role;
  bool get isAdmin => role == CompanyRole.admin;
}

CompanyRole companyRoleFrom(String? v) =>
    v == 'admin' ? CompanyRole.admin : CompanyRole.member;

class CompanyMember {
  const CompanyMember({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.addedAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final CompanyRole role;
  final DateTime? addedAt;

  factory CompanyMember.fromJson(String uid, Map<String, dynamic> j) =>
      CompanyMember(
        uid: uid,
        email: j['email'] as String? ?? '',
        displayName: j['displayName'] as String? ?? '',
        role: companyRoleFrom(j['role'] as String?),
        addedAt: (j['addedAt'] as Timestamp?)?.toDate(),
      );
}

/// Someone invited by e-mail who has not created an account yet.
class CompanyInvite {
  const CompanyInvite({required this.email, required this.role, this.createdAt});

  final String email;
  final CompanyRole role;
  final DateTime? createdAt;

  factory CompanyInvite.fromJson(Map<String, dynamic> j) => CompanyInvite(
        email: j['email'] as String? ?? '',
        role: companyRoleFrom(j['role'] as String?),
        createdAt: (j['createdAt'] as Timestamp?)?.toDate(),
      );
}

/// Error codes returned by the corporate callables (functions/src/corporate.ts).
abstract final class CompanyErrorCodes {
  static const invalidName = 'company/invalid-name';
  static const invalidTaxId = 'company/invalid-tax-id';
  static const invalidEmail = 'company/invalid-email';
  static const invalidAdminEmail = 'company/invalid-admin-email';
  static const notARider = 'company/not-a-rider';
  static const otherCompany = 'company/user-in-other-company';
  static const lastAdmin = 'company/last-admin';
  static const costCentersEmpty = 'company/cost-center-required-without-list';
  static const inactive = 'billing/company-inactive';
  static const failed = 'company/failed';

  static const all = [
    invalidName,
    invalidTaxId,
    invalidEmail,
    invalidAdminEmail,
    notARider,
    otherCompany,
    lastAdmin,
    costCentersEmpty,
    inactive,
  ];

  /// First known code found in a server message, else [failed].
  static String fromMessage(String? message) =>
      all.firstWhere((c) => (message ?? '').contains(c), orElse: () => failed);
}
