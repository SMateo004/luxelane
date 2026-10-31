import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxelane/core/config/driver_documents.dart';
import 'package:luxelane/core/design/lux_promise.dart';
import 'package:luxelane/l10n/l10n.dart';

/// Idiomas, B1: los textos compartidos que seguían como const en español
/// (promesas de la reserva y el aviso de documentos bloqueados) salen en el
/// idioma activo.
void main() {
  tearDown(() => L10n.use(const Locale('es')));

  test('las promesas y el aviso, en inglés y en portugués', () {
    L10n.use(const Locale('en'));
    expect(LuxPromise.fixedPrice, L10n.current.commonPromiseFixedPrice);
    expect(LuxPromise.fixedPrice, isNot('Precio fijo al reservar'));
    expect(LuxAssurance.chauffeurs.title, L10n.current.commonPromiseChauffeurs);
    expect(LuxAssurance.fixedPrice.detail,
        L10n.current.commonPromiseFixedPriceLong);
    expect(kLockedDocumentsMessage, contains('operations team'));
    L10n.use(const Locale('pt'));
    expect(LuxPromise.chauffeursLong, L10n.current.commonPromiseChauffeursLong);
    expect(LuxPromise.chauffeursLong, isNot(contains('Luxelane revisa')));
  });

  test('en español, el texto de siempre', () {
    expect(LuxPromise.fixedPrice, 'Precio fijo al reservar');
    expect(LuxAssurance.fixedPrice.title, 'Precio fijo al reservar');
    expect(kLockedDocumentsMessage,
        'Para cambiar estos datos, contacta con central.');
  });
}
