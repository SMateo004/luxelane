import 'package:cloud_firestore/cloud_firestore.dart';

/// Solicitud de una empresa interesada en Luxelane para Empresas.
class BusinessLead {
  const BusinessLead({
    required this.id,
    required this.company,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.travellers,
    required this.message,
    required this.handled,
    required this.createdAt,
  });

  final String id;
  final String company;
  final String contactName;
  final String email;
  final String phone;

  /// Cuántas personas viajarían (rango elegido en el formulario).
  final String travellers;
  final String message;
  final bool handled;
  final DateTime createdAt;

  factory BusinessLead.fromJson(String id, Map<String, dynamic> j) =>
      BusinessLead(
        id: id,
        company: j['company'] as String? ?? '',
        contactName: j['contactName'] as String? ?? '',
        email: j['email'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        travellers: j['travellers'] as String? ?? '',
        message: j['message'] as String? ?? '',
        handled: j['handled'] == true,
        createdAt: (j['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

/// Las empresas dejan su solicitud (sin cuenta) y el admin las atiende.
class BusinessLeadRepository {
  BusinessLeadRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('businessLeads');

  Future<void> submit({
    required String company,
    required String contactName,
    required String email,
    required String phone,
    required String travellers,
    required String message,
  }) =>
      _col.add({
        'company': company.trim(),
        'contactName': contactName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'travellers': travellers,
        'message': message.trim(),
        'handled': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Stream<List<BusinessLead>> watchAll() =>
      _col.orderBy('createdAt', descending: true).limit(200).snapshots().map(
            (s) => s.docs
                .map((d) => BusinessLead.fromJson(d.id, d.data()))
                .toList(),
          );

  Future<void> setHandled(String id, bool handled) =>
      _col.doc(id).update({'handled': handled});
}
