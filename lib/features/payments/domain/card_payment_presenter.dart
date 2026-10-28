/// Cobro con tarjeta en la app nativa, detrás de una interfaz: el proveedor
/// no está decidido (pagos, decisión 5). El servidor crea el cobro con su
/// importe (startPayment) y lo confirma por el webhook; la app solo muestra
/// el formulario del proveedor con el secreto que recibe.
///
/// Sin implementación registrada, la app no ofrece la tarjeta. En la web
/// nunca se registra: allí solo hay pago manual (E38).
abstract class CardPaymentPresenter {
  Future<CardSheetResult> present(String clientSecret);
}

enum CardSheetOutcome { completed, cancelled, failed }

class CardSheetResult {
  const CardSheetResult(this.outcome, [this.message]);
  final CardSheetOutcome outcome;

  /// Motivo del proveedor, para el aviso (sin códigos técnicos).
  final String? message;
}
