import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/partner_hotel.dart';

/// Partner hotels (hotels/{id}). Anyone can read active hotels (the public
/// page works for guests); only admins see inactive ones and write.
abstract class HotelRepository {
  Stream<List<PartnerHotel>> watchActive();
  Stream<List<PartnerHotel>> watchAll();
  Future<void> save(PartnerHotel hotel);
  Future<void> setActive(String id, bool active);
}

class HotelRepositoryImpl implements HotelRepository {
  HotelRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('hotels');

  static List<PartnerHotel> _sorted(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map((d) => PartnerHotel.fromJson(d.id, d.data())).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  @override
  Stream<List<PartnerHotel>> watchActive() => _col.where('active', isEqualTo: true).snapshots().map(_sorted);

  @override
  Stream<List<PartnerHotel>> watchAll() => _col.snapshots().map(_sorted);

  @override
  Future<void> save(PartnerHotel hotel) {
    final doc = hotel.id.isEmpty ? _col.doc() : _col.doc(hotel.id);
    return doc.set({...hotel.toJson(), 'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> setActive(String id, bool active) =>
      _col.doc(id).update({'active': active, 'updatedAt': FieldValue.serverTimestamp()});
}
