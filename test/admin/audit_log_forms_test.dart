import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/models/models.dart';

/// A9: no hace falta migrar admin_logs. El panel lee igual la forma antigua
/// (escrita por el cliente) y la nueva (escrita por el servidor, con los
/// mismos campos más operación, actor, cambios y motivo).
void main() {
  final at = Timestamp.fromDate(DateTime(2026, 10, 25, 12));

  test('forma antigua', () {
    final l = AuditLog.fromJson({
      'id': 'a',
      'adminId': 'jefa',
      'adminEmail': 'jefa@example.com',
      'action': 'cancel_booking',
      'targetId': 'b1',
      'targetType': 'booking',
      'details': 'Confirmada → Cancelada · Pedido por el pasajero',
      'createdAt': at,
    });
    expect(l.action, 'cancel_booking');
    expect(l.details, contains('Pedido por el pasajero'));
  });

  test('forma nueva del servidor (Parte A)', () {
    final l = AuditLog.fromJson({
      'id': 'n',
      'adminId': 'jefa',
      'adminEmail': null,
      'action': 'cancel_booking',
      'targetId': 'b1',
      'targetType': 'booking',
      'details': 'confirmed → cancelled · Motivo: Pedido por el pasajero',
      'operation': 'cancel_booking',
      'actor': {'uid': 'jefa', 'role': 'admin'},
      'collection': 'bookings',
      'docPath': 'bookings/b1',
      'changes': {
        'status': {'before': 'confirmed', 'after': 'cancelled'},
      },
      'reason': 'Pedido por el pasajero',
      'source': 'server',
      'createdAt': at,
    });
    expect(l.adminId, 'jefa');
    expect(l.action, 'cancel_booking');
    expect(l.targetId, 'b1');
    expect(l.details, contains('Motivo: Pedido por el pasajero'));
    expect(l.createdAt, DateTime(2026, 10, 25, 12));
  });
}
