import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/features/special/domain/special_models.dart';

void main() {
  test('rutas y estados', () {
    expect(SpecialKindX.parse('aerotaxi'), SpecialKind.aerotaxi);
    expect(SpecialKindX.parse('paseo'), SpecialKind.cityTour);
    expect(SpecialKindX.parse('submarino'), isNull);
    expect(SpecialKind.cityTour.slug, 'paseo');
    expect(SpecialStatusX.parse('quoted').isOpen, isTrue);
    expect(SpecialStatusX.parse('confirmed').isOpen, isFalse);
    expect(SpecialStatusX.parse(null), SpecialStatus.newRequest);
  });

  test('la solicitud solo lleva los campos que aceptan las reglas', () {
    const allowed = {
      'riderId', 'riderName', 'riderEmail', 'riderPhone', 'kind', 'date', //
      'passengers', 'from', 'to', 'pickup', 'durationHours', 'language',
      'notes', 'status', 'createdAt', 'updatedAt',
    };
    final aero = SpecialRequest.newRequestJson(
      riderId: 'u',
      riderName: 'Ana',
      riderEmail: 'a@b.bo',
      riderPhone: '+591 7',
      kind: SpecialKind.aerotaxi,
      date: DateTime(2030),
      passengers: 2,
      from: 'Santa Cruz',
      to: 'Uyuni',
      notes: '  maletas  ',
    );
    expect(allowed.containsAll(aero.keys), isTrue);
    expect(aero.containsKey('pickup'), isFalse);
    expect(aero['status'], 'new');
    expect(aero['notes'], 'maletas');

    final tour = SpecialRequest.newRequestJson(
      riderId: 'u',
      riderName: 'x' * 100,
      riderEmail: '',
      riderPhone: '',
      kind: SpecialKind.cityTour,
      date: DateTime(2030),
      passengers: 1,
      pickup: 'Hotel',
      durationHours: 4,
    );
    expect(allowed.containsAll(tour.keys), isTrue);
    expect(tour.containsKey('from'), isFalse);
    expect(tour['language'], 'es');
    expect((tour['riderName'] as String).length, 80);
  });
}
