import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/enums/enums.dart';
import 'package:luxelane/features/admin/domain/admin_operations.dart';
import 'package:luxelane/features/admin/presentation/bloc/admin_bloc.dart';

void main() {
  group('AdminState avisos', () {
    test('el mismo error dos veces produce dos estados distintos', () {
      const s0 = AdminState();
      final s1 = s0.copyWith(error: 'Permiso denegado');
      final s2 = s1.copyWith(error: 'Permiso denegado');
      expect(s1.messageSeq, 1);
      expect(s2.messageSeq, 2);
      expect(s1 == s2, isFalse);
    });

    test('una actualización de datos no cuenta como aviso', () {
      final s1 = const AdminState().copyWith(successMessage: 'Guardado');
      final s2 = s1.copyWith(isLoading: false);
      expect(s2.messageSeq, s1.messageSeq);
      expect(s2.successMessage, isNull);
    });
  });

  test('los estados de pago se muestran en español', () {
    expect(PaymentStatus.pending.displayLabel, 'Pendiente');
    expect(PaymentStatus.captured.displayLabel, 'Cobrado');
    expect(PaymentStatus.refunded.displayLabel, 'Reembolsado');
    expect(PaymentStatus.failed.displayLabel, 'Fallido');
  });
}
