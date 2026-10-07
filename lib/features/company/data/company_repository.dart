import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/models/models.dart';
import '../domain/company.dart';

/// Corporate accounts. Reads come straight from Firestore (rules restrict
/// them to members, company admins and Luxelane admins); every write goes
/// through a Cloud Function. Mutations return null on success or a
/// [CompanyErrorCodes] value.
abstract class CompanyRepository {
  /// Live membership of [uid] (null when the rider has no company). Read from
  /// the user document so changes made by an admin show up without signing in
  /// again.
  Stream<CompanyMembership?> watchMembership(String uid);
  Stream<Company?> watchCompany(String companyId);
  Stream<List<Company>> watchAllCompanies();
  Stream<List<CompanyMember>> watchMembers(String companyId);
  Stream<List<CompanyInvite>> watchInvites(String companyId);

  /// Bookings billed to the company with pickup in [from, to).
  Stream<List<Booking>> watchBookings(String companyId, DateTime from, DateTime to);

  Future<String?> createCompany({
    required String name,
    required String taxId,
    required String billingEmail,
    required String adminEmail,
  });
  Future<String?> updateCompany(
    String companyId, {
    String? name,
    String? taxId,
    String? billingEmail,
    List<String>? costCenters,
    bool? requireCostCenter,
    bool? active,
  });
  Future<String?> addMember(String companyId, String email, CompanyRole role);
  Future<String?> setMemberRole(String companyId, String uid, CompanyRole role);
  Future<String?> removeMember(String companyId, String uid);
  Future<String?> cancelInvite(String email);
}

class CompanyRepositoryImpl implements CompanyRepository {
  CompanyRepositoryImpl(this._db, this._fn);

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;

  CollectionReference<Map<String, dynamic>> get _companies => _db.collection('companies');

  @override
  Stream<CompanyMembership?> watchMembership(String uid) =>
      _db.collection('users').doc(uid).snapshots().map((d) {
        final id = d.data()?['companyId'] as String?;
        if (id == null || id.isEmpty) return null;
        return CompanyMembership(id, companyRoleFrom(d.data()?['companyRole'] as String?));
      });

  @override
  Stream<Company?> watchCompany(String companyId) => _companies
      .doc(companyId)
      .snapshots()
      .map((d) => d.exists ? Company.fromJson(d.id, d.data()!) : null);

  @override
  Stream<List<Company>> watchAllCompanies() => _companies
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map((d) => Company.fromJson(d.id, d.data())).toList());

  @override
  Stream<List<CompanyMember>> watchMembers(String companyId) => _companies
      .doc(companyId)
      .collection('members')
      .snapshots()
      .map((s) => s.docs.map((d) => CompanyMember.fromJson(d.id, d.data())).toList()
        ..sort((a, b) {
          if (a.role != b.role) return a.role == CompanyRole.admin ? -1 : 1;
          return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
        }));

  @override
  Stream<List<CompanyInvite>> watchInvites(String companyId) => _db
      .collection('companyInvites')
      .where('companyId', isEqualTo: companyId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => CompanyInvite.fromJson(d.data())).toList());

  @override
  Stream<List<Booking>> watchBookings(String companyId, DateTime from, DateTime to) => _db
      .collection('bookings')
      .where('companyId', isEqualTo: companyId)
      .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
      .where('scheduledAt', isLessThan: Timestamp.fromDate(to))
      .orderBy('scheduledAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Booking.fromJson({...d.data(), 'id': d.id})).toList());

  Future<String?> _call(String name, Map<String, dynamic> data) async {
    try {
      await _fn.httpsCallable(name).call(data);
      return null;
    } on FirebaseFunctionsException catch (e) {
      return CompanyErrorCodes.fromMessage(e.message);
    } catch (_) {
      return CompanyErrorCodes.failed;
    }
  }

  @override
  Future<String?> createCompany({
    required String name,
    required String taxId,
    required String billingEmail,
    required String adminEmail,
  }) =>
      _call('createCompany', {
        'name': name,
        'taxId': taxId,
        'billingEmail': billingEmail,
        'adminEmail': adminEmail,
      });

  @override
  Future<String?> updateCompany(
    String companyId, {
    String? name,
    String? taxId,
    String? billingEmail,
    List<String>? costCenters,
    bool? requireCostCenter,
    bool? active,
  }) =>
      _call('updateCompany', {
        'companyId': companyId,
        if (name != null) 'name': name,
        if (taxId != null) 'taxId': taxId,
        if (billingEmail != null) 'billingEmail': billingEmail,
        if (costCenters != null) 'costCenters': costCenters,
        if (requireCostCenter != null) 'requireCostCenter': requireCostCenter,
        if (active != null) 'active': active,
      });

  @override
  Future<String?> addMember(String companyId, String email, CompanyRole role) =>
      _call('addCompanyMember', {'companyId': companyId, 'email': email, 'role': role.name});

  @override
  Future<String?> setMemberRole(String companyId, String uid, CompanyRole role) =>
      _call('updateCompanyMember', {'companyId': companyId, 'uid': uid, 'role': role.name});

  @override
  Future<String?> removeMember(String companyId, String uid) =>
      _call('updateCompanyMember', {'companyId': companyId, 'uid': uid, 'remove': true});

  @override
  Future<String?> cancelInvite(String email) => _call('cancelCompanyInvite', {'email': email});
}
