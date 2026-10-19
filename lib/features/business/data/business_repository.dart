import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

import '../../../core/error/failures.dart';
import '../../../core/models/models.dart';
import '../domain/business_models.dart';

/// Acceso al programa para empresas. Las lecturas son streams en vivo de
/// Firestore; toda escritura pasa por Cloud Functions, que validan permisos
/// y reglas de negocio (la app no escribe nada de la empresa directamente).
class BusinessRepository {
  BusinessRepository({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _db = firestore,
        _fn = functions;

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;

  // ── Lecturas ──────────────────────────────────────────────────────────────

  Stream<Company?> watchCompany(String companyId) => _db
      .collection('companies')
      .doc(companyId)
      .snapshots()
      .map((d) => d.exists ? Company.fromDoc(d.id, d.data()!) : null);

  Stream<List<Company>> watchAllCompanies() =>
      _db.collection('companies').snapshots().map((s) {
        final list = s.docs.map((d) => Company.fromDoc(d.id, d.data())).toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0)));
        return list;
      });

  Stream<CompanyMember?> watchMember(String companyId, String uid) => _db
      .collection('companies')
      .doc(companyId)
      .collection('members')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? CompanyMember.fromDoc(d.id, d.data()!) : null);

  Stream<List<CompanyMember>> watchMembers(String companyId) => _db
      .collection('companies')
      .doc(companyId)
      .collection('members')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => CompanyMember.fromDoc(d.id, d.data())).toList()
            ..sort((a, b) => a.displayName.compareTo(b.displayName)));

  Stream<List<CompanyInvite>> watchCompanyInvites(String companyId) => _db
      .collection('companyInvites')
      .where('companyId', isEqualTo: companyId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.docs.map((d) => CompanyInvite.fromDoc(d.data())).toList());

  /// Invitaciones pendientes para el correo del usuario.
  Stream<List<CompanyInvite>> watchMyInvites(String email) => _db
      .collection('companyInvites')
      .where('email', isEqualTo: email.trim().toLowerCase())
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.docs.map((d) => CompanyInvite.fromDoc(d.data())).toList());

  /// Extractos de la empresa. Sin [includeDrafts] (vista de la empresa)
  /// solo los emitidos: las reglas no le dejan leer borradores.
  Stream<List<CompanyStatement>> watchStatements(String companyId,
          {bool includeDrafts = false}) =>
      (includeDrafts
              ? _db
                  .collection('companyStatements')
                  .where('companyId', isEqualTo: companyId)
              : _db
                  .collection('companyStatements')
                  .where('companyId', isEqualTo: companyId)
                  .where('status', whereIn: ['issued', 'paid']))
          .snapshots()
          .map((s) => s.docs
              .map((d) => CompanyStatement.fromDoc(d.id, d.data()))
              .toList()
            ..sort((a, b) => b.period.compareTo(a.period)));

  /// Viajes de la empresa en un mes (para su panel).
  Stream<List<Booking>> watchCompanyBookings(String companyId, String period) {
    final (start, end) = periodRange(period);
    return _db
        .collection('bookings')
        .where('companyId', isEqualTo: companyId)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledAt', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((s) {
      final out = <Booking>[];
      for (final d in s.docs) {
        try {
          out.add(Booking.fromJson({...d.data(), 'id': d.id}));
        } catch (_) {}
      }
      out.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return out;
    });
  }

  // ── Acciones (Cloud Functions) ────────────────────────────────────────────

  Future<Either<Failure, Map<String, dynamic>>> _call(
      String name, Map<String, dynamic> data) async {
    try {
      final r = await _fn.httpsCallable(name).call<dynamic>(data);
      return Right(Map<String, dynamic>.from((r.data as Map?) ?? const {}));
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[Business] $name: ${e.code} ${e.message}');
      // El servidor ya responde en español para los errores de negocio.
      final msg = switch (e.code) {
        'unavailable' ||
        'deadline-exceeded' =>
          'Sin conexión. Inténtalo de nuevo.',
        'unauthenticated' => 'Inicia sesión para continuar.',
        'internal' => 'Algo salió mal. Inténtalo de nuevo.',
        _ => e.message ?? 'Algo salió mal. Inténtalo de nuevo.',
      };
      return Left(ServerFailure(msg));
    } catch (e) {
      debugPrint('[Business] $name: $e');
      return const Left(ServerFailure('Algo salió mal. Inténtalo de nuevo.'));
    }
  }

  Future<Either<Failure, String>> registerCompany({
    required String name,
    required String taxId,
    required String billingEmail,
    required String contactName,
    required String phone,
    required String address,
  }) async =>
      (await _call('registerCompany', {
        'name': name,
        'taxId': taxId,
        'billingEmail': billingEmail,
        'contactName': contactName,
        'phone': phone,
        'address': address,
      }))
          .map((r) => r['companyId'] as String? ?? '');

  Future<Either<Failure, bool>> invite(
          {required String email, bool admin = false, double? limitBs}) async =>
      (await _call('inviteCompanyMember', {
        'email': email,
        'role': admin ? 'admin' : 'employee',
        'monthlyLimitBs': limitBs,
      }))
          .map((r) => r['registered'] == true);

  Future<Either<Failure, void>> revokeInvite(String email) async =>
      (await _call('revokeCompanyInvite', {'email': email})).map((_) {});

  Future<Either<Failure, void>> respondInvite(String companyId,
      {required bool accept}) async {
    // El servidor exige el correo verificado en el token: si el usuario
    // acaba de verificarlo, se refresca antes de llamar.
    try {
      final u = fb.FirebaseAuth.instance.currentUser;
      await u?.reload();
      await fb.FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (_) {}
    return (await _call(
            'respondCompanyInvite', {'companyId': companyId, 'accept': accept}))
        .map((_) {});
  }

  /// ¿El correo de la sesión está verificado? (consulta a Firebase Auth).
  Future<bool> refreshEmailVerified() async {
    try {
      await fb.FirebaseAuth.instance.currentUser?.reload();
      return fb.FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    } catch (_) {
      return false;
    }
  }

  bool get emailVerified =>
      fb.FirebaseAuth.instance.currentUser?.emailVerified ?? false;

  Future<void> resendVerification() async {
    try {
      await fb.FirebaseAuth.instance.currentUser?.sendEmailVerification();
    } catch (_) {}
  }

  Future<Either<Failure, void>> updateMember(String uid,
          {bool? active,
          double? limitBs,
          bool clearLimit = false,
          bool? admin}) async =>
      (await _call('updateCompanyMember', {
        'uid': uid,
        if (active != null) 'active': active,
        if (limitBs != null || clearLimit) 'monthlyLimitBs': limitBs,
        if (admin != null) 'role': admin ? 'admin' : 'employee',
      }))
          .map((_) {});

  Future<Either<Failure, void>> removeMember(String uid) async =>
      (await _call('removeCompanyMember', {'uid': uid})).map((_) {});

  Future<Either<Failure, void>> setBudget(double? budgetBs) async =>
      (await _call('updateCompanyBudget', {'monthlyBudgetBs': budgetBs}))
          .map((_) {});

  // ── Administración de Luxelane ────────────────────────────────────────────

  Future<Either<Failure, void>> adminUpdateCompany(
    String companyId,
    String action, {
    String? reason,
    double? discountPct,
    int? paymentTermsDays,
    double? monthlyBudgetBs,
    bool clearBudget = false,
  }) async =>
      (await _call('adminUpdateCompany', {
        'companyId': companyId,
        'action': action,
        if (reason != null) 'reason': reason,
        if (discountPct != null) 'discountPct': discountPct,
        if (paymentTermsDays != null) 'paymentTermsDays': paymentTermsDays,
        if (monthlyBudgetBs != null || clearBudget)
          'monthlyBudgetBs': monthlyBudgetBs,
      }))
          .map((_) {});

  Future<Either<Failure, void>> generateStatement(
          String companyId, String period) async =>
      (await _call('generateCompanyStatement',
              {'companyId': companyId, 'period': period}))
          .map((_) {});

  Future<Either<Failure, void>> addAdjustment(
          String statementId, String concept, double amountBs) async =>
      (await _call('addStatementAdjustment', {
        'statementId': statementId,
        'concept': concept,
        'amountBs': amountBs,
      }))
          .map((_) {});

  Future<Either<Failure, void>> removeAdjustment(
          String statementId, String adjustmentId) async =>
      (await _call('removeStatementAdjustment',
              {'statementId': statementId, 'adjustmentId': adjustmentId}))
          .map((_) {});

  Future<Either<Failure, void>> issueStatement(String statementId) async =>
      (await _call('issueCompanyStatement', {'statementId': statementId}))
          .map((_) {});

  Future<Either<Failure, void>> markPaid(
          String statementId, String reference) async =>
      (await _call('markStatementPaid',
              {'statementId': statementId, 'reference': reference}))
          .map((_) {});
}
