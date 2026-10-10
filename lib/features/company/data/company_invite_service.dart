import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A rider's pending company invite (companyInvite callable). Joining needs
/// a verified e-mail, so nobody can claim an invite for someone else's
/// address.
class CompanyInviteStatus {
  const CompanyInviteStatus({this.company, this.verified = false});
  static const none = CompanyInviteStatus();

  final String? company;
  final bool verified;
}

abstract class CompanyInviteService {
  Future<CompanyInviteStatus> status();

  /// Joins; returns an error code ('company/email-not-verified', …) or null.
  Future<String?> join();
  Future<void> sendVerificationEmail();
}

class CompanyInviteServiceImpl implements CompanyInviteService {
  CompanyInviteServiceImpl(this._fn, this._auth);
  final FirebaseFunctions _fn;
  final FirebaseAuth _auth;

  @override
  Future<CompanyInviteStatus> status() async {
    try {
      final r = await _fn.httpsCallable('companyInvite').call({'action': 'status'});
      final m = Map<String, dynamic>.from(r.data as Map);
      return CompanyInviteStatus(company: m['company'] as String?, verified: m['verified'] == true);
    } catch (_) {
      return CompanyInviteStatus.none;
    }
  }

  @override
  Future<String?> join() async {
    try {
      await _fn.httpsCallable('companyInvite').call({'action': 'join'});
      return null;
    } on FirebaseFunctionsException catch (e) {
      return RegExp(r'company/[a-z-]+').firstMatch(e.message ?? '')?.group(0) ?? 'company/failed';
    } catch (_) {
      return 'company/failed';
    }
  }

  @override
  Future<void> sendVerificationEmail() async => _auth.currentUser?.sendEmailVerification();
}
