/// Company and contact details used by the legal, contact and footer pages.
///
/// ⚠ Fill these in before launch. While any value still starts with "[",
/// the legal pages show a "borrador" banner so placeholder text is never
/// mistaken for a reviewed policy.
abstract class LegalInfo {
  static const brand = 'Luxelane';
  static const companyName = '[Razón social de la empresa]';
  static const nit = '[NIT]';
  static const address = '[Dirección comercial, Santa Cruz de la Sierra, Bolivia]';
  static const city = 'Santa Cruz de la Sierra';

  /// Support channels. Leave empty to hide a channel.
  static const supportEmail = '[correo@dominio.bo]';
  static const supportWhatsApp = '[+591 7XXXXXXX]';

  static const lastUpdated = '7 de octubre de 2026';

  /// Retention of trip records for accounting/tax purposes.
  static const recordRetention = '[N] años';

  static bool get isDraft => [
        companyName,
        nit,
        address,
        supportEmail,
        supportWhatsApp,
        recordRetention,
      ].any((v) => v.contains('['));

  static bool get hasEmail => supportEmail.isNotEmpty && !supportEmail.startsWith('[');
  static bool get hasWhatsApp => supportWhatsApp.isNotEmpty && !supportWhatsApp.startsWith('[');
}
