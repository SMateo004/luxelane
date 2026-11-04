import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// Panel, solicitudes de chófer: nombre de la sección en la barra lateral y las pestañas.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes de chófer'**
  String get adminDrvAppSection;

  /// Panel, solicitudes de chófer: subtítulo de la sección.
  ///
  /// In es, this message translates to:
  /// **'Datos, vehículo y documentos de quienes quieren conducir.'**
  String get adminDrvAppSectionSubtitle;

  /// Panel, solicitudes de chófer: pestaña de la bandeja de solicitudes.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get adminDrvAppTabInbox;

  /// Panel, solicitudes de chófer: pestaña de documentos que vencen pronto.
  ///
  /// In es, this message translates to:
  /// **'Vencimientos próximos'**
  String get adminDrvAppTabExpiries;

  /// Panel, solicitudes de chófer: botón de recargar.
  ///
  /// In es, this message translates to:
  /// **'Recargar'**
  String get adminDrvAppReload;

  /// Panel, solicitudes de chófer: botón para reintentar tras un error.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get adminDrvAppRetry;

  /// Panel, solicitudes de chófer: etiqueta accesible del filtro por estado.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por estado'**
  String get adminDrvAppStatusFilter;

  /// Panel, solicitudes de chófer: bandeja vacía.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes en este estado'**
  String get adminDrvAppInboxEmpty;

  /// Panel, solicitudes de chófer: pista bajo la bandeja vacía.
  ///
  /// In es, this message translates to:
  /// **'Elige otro estado arriba para ver más.'**
  String get adminDrvAppInboxEmptyHint;

  /// Panel, solicitudes de chófer: no se pudo cargar la bandeja.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las solicitudes.'**
  String get adminDrvAppInboxError;

  /// Panel, solicitudes de chófer: aviso de que la lista está recortada; {count} es el máximo mostrado.
  ///
  /// In es, this message translates to:
  /// **'Se muestran las {count} más recientes.'**
  String adminDrvAppInboxTruncated(String count);

  /// Panel, solicitudes de chófer: fecha de envío de la solicitud.
  ///
  /// In es, this message translates to:
  /// **'Enviada el {date}'**
  String adminDrvAppSubmittedAt(String date);

  /// Panel, solicitudes de chófer: fecha de la última actualización (sin envío).
  ///
  /// In es, this message translates to:
  /// **'Actualizada el {date}'**
  String adminDrvAppUpdatedAt(String date);

  /// Panel, solicitudes de chófer: chófer sin nombre en su cuenta.
  ///
  /// In es, this message translates to:
  /// **'Sin nombre'**
  String get adminDrvAppNoName;

  /// Panel, solicitudes de chófer: etiqueta accesible para abrir una solicitud; {name} es el chófer.
  ///
  /// In es, this message translates to:
  /// **'Abrir la solicitud de {name}'**
  String adminDrvAppOpen(String name);

  /// Panel, solicitudes de chófer: botón para abrir la solicitud desde vencimientos.
  ///
  /// In es, this message translates to:
  /// **'Ver solicitud'**
  String get adminDrvAppOpenShort;

  /// Panel, solicitudes de chófer: volver del detalle a la bandeja.
  ///
  /// In es, this message translates to:
  /// **'Volver a la bandeja'**
  String get adminDrvAppBack;

  /// Panel, solicitudes de chófer: no se pudo cargar el detalle.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la solicitud.'**
  String get adminDrvAppDetailError;

  /// Panel, solicitudes de chófer: título de los datos personales.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get adminDrvAppPersonalTitle;

  /// Panel, solicitudes de chófer: el chófer no completó los datos personales.
  ///
  /// In es, this message translates to:
  /// **'Aún no completó sus datos personales.'**
  String get adminDrvAppPersonalMissing;

  /// Panel, solicitudes de chófer: campo nombre completo.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get adminDrvAppFullName;

  /// Panel, solicitudes de chófer: campo número del documento de identidad.
  ///
  /// In es, this message translates to:
  /// **'Número de documento'**
  String get adminDrvAppNationalId;

  /// Panel, solicitudes de chófer: campo número de licencia.
  ///
  /// In es, this message translates to:
  /// **'Número de licencia'**
  String get adminDrvAppLicenseNumber;

  /// Panel, solicitudes de chófer: campo vencimiento de la licencia.
  ///
  /// In es, this message translates to:
  /// **'Vencimiento de la licencia'**
  String get adminDrvAppLicenseExpiry;

  /// Panel, solicitudes de chófer: campo correo de la cuenta.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get adminDrvAppEmail;

  /// Panel, solicitudes de chófer: campo estado de la solicitud.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get adminDrvAppStatus;

  /// Panel, solicitudes de chófer: título del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get adminDrvAppVehicleTitle;

  /// Panel, solicitudes de chófer: el chófer no completó el vehículo.
  ///
  /// In es, this message translates to:
  /// **'Aún no registró el vehículo.'**
  String get adminDrvAppVehicleMissing;

  /// Panel, solicitudes de chófer: campo marca.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get adminDrvAppMake;

  /// Panel, solicitudes de chófer: campo modelo.
  ///
  /// In es, this message translates to:
  /// **'Modelo'**
  String get adminDrvAppModel;

  /// Panel, solicitudes de chófer: campo año.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get adminDrvAppYear;

  /// Panel, solicitudes de chófer: campo color.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get adminDrvAppColor;

  /// Panel, solicitudes de chófer: campo placa.
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get adminDrvAppPlate;

  /// Panel, solicitudes de chófer: campo carrocería.
  ///
  /// In es, this message translates to:
  /// **'Carrocería'**
  String get adminDrvAppBodyType;

  /// Panel, solicitudes de chófer: campo número de pasajeros.
  ///
  /// In es, this message translates to:
  /// **'Pasajeros'**
  String get adminDrvAppPassengers;

  /// Panel, solicitudes de chófer: campo clase de servicio.
  ///
  /// In es, this message translates to:
  /// **'Clase'**
  String get adminDrvAppClass;

  /// Panel, solicitudes de chófer: aviso de vehículo nuevo en revisión tras aprobar.
  ///
  /// In es, this message translates to:
  /// **'Cambio de vehículo pendiente de revisión.'**
  String get adminDrvAppPendingVehicle;

  /// Panel, solicitudes de chófer: título de la lista de documentos.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get adminDrvAppDocsTitle;

  /// Panel, solicitudes de chófer: banner: config/ops.driverRequirements no existe.
  ///
  /// In es, this message translates to:
  /// **'Requisitos sin configurar'**
  String get adminDrvAppRequirementsMissing;

  /// Panel, solicitudes de chófer: explicación del banner de requisitos sin configurar.
  ///
  /// In es, this message translates to:
  /// **'Falta la lista driverRequirements en config/ops: el chófer no puede enviar la solicitud y no se puede aprobar. Se muestran los documentos subidos.'**
  String get adminDrvAppRequirementsMissingBody;

  /// Panel, solicitudes de chófer: documento obligatorio.
  ///
  /// In es, this message translates to:
  /// **'Obligatorio'**
  String get adminDrvAppRequired;

  /// Panel, solicitudes de chófer: documento opcional.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get adminDrvAppOptional;

  /// Panel, solicitudes de chófer: documento subido que no está en los requisitos.
  ///
  /// In es, this message translates to:
  /// **'Fuera de los requisitos'**
  String get adminDrvAppNotRequested;

  /// Panel, solicitudes de chófer: versión del documento.
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String adminDrvAppDocVersion(String version);

  /// Panel, solicitudes de chófer: fecha de vencimiento futura.
  ///
  /// In es, this message translates to:
  /// **'Vence el {date}'**
  String adminDrvAppDocExpires(String date);

  /// Panel, solicitudes de chófer: fecha de vencimiento pasada.
  ///
  /// In es, this message translates to:
  /// **'Venció el {date}'**
  String adminDrvAppDocExpired(String date);

  /// Panel, solicitudes de chófer: el documento vence pero no tiene fecha.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha de vencimiento'**
  String get adminDrvAppDocExpiryMissing;

  /// Panel, solicitudes de chófer: motivo del rechazo de un documento.
  ///
  /// In es, this message translates to:
  /// **'Motivo del rechazo: {reason}'**
  String adminDrvAppDocRejectReason(String reason);

  /// Panel, solicitudes de chófer: nota del rechazo.
  ///
  /// In es, this message translates to:
  /// **'Nota: {note}'**
  String adminDrvAppDocNote(String note);

  /// Panel, solicitudes de chófer: el documento no se subió.
  ///
  /// In es, this message translates to:
  /// **'Sin subir'**
  String get adminDrvAppDocNotUploaded;

  /// Panel, solicitudes de chófer: botón para abrir el visor.
  ///
  /// In es, this message translates to:
  /// **'Ver documento'**
  String get adminDrvAppViewDoc;

  /// Panel, solicitudes de chófer: etiqueta accesible del botón ver; {document} es el tipo.
  ///
  /// In es, this message translates to:
  /// **'Ver documento: {document}'**
  String adminDrvAppViewDocLabel(String document);

  /// Panel, solicitudes de chófer: botón aprobar documento.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get adminDrvAppApproveDoc;

  /// Panel, solicitudes de chófer: etiqueta accesible del botón aprobar.
  ///
  /// In es, this message translates to:
  /// **'Aprobar documento: {document}'**
  String adminDrvAppApproveDocLabel(String document);

  /// Panel, solicitudes de chófer: botón rechazar documento.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get adminDrvAppRejectDoc;

  /// Panel, solicitudes de chófer: etiqueta accesible del botón rechazar.
  ///
  /// In es, this message translates to:
  /// **'Rechazar documento: {document}'**
  String adminDrvAppRejectDocLabel(String document);

  /// Panel, solicitudes de chófer: título del diálogo para aprobar un documento.
  ///
  /// In es, this message translates to:
  /// **'¿Aprobar {document}?'**
  String adminDrvAppApproveTitle(String document);

  /// Panel, solicitudes de chófer: texto del diálogo para aprobar.
  ///
  /// In es, this message translates to:
  /// **'Se aprueba la versión {version}. Queda en la auditoría con tu cuenta.'**
  String adminDrvAppApproveBody(String version);

  /// Panel, solicitudes de chófer: confirmar aprobación de documento.
  ///
  /// In es, this message translates to:
  /// **'Aprobar documento'**
  String get adminDrvAppApproveConfirm;

  /// Panel, solicitudes de chófer: aviso tras aprobar un documento.
  ///
  /// In es, this message translates to:
  /// **'Documento aprobado.'**
  String get adminDrvAppDocApproved;

  /// Panel, solicitudes de chófer: aviso tras rechazar un documento.
  ///
  /// In es, this message translates to:
  /// **'Documento rechazado. El chófer verá el motivo.'**
  String get adminDrvAppDocRejected;

  /// Panel, solicitudes de chófer: título del diálogo para rechazar un documento.
  ///
  /// In es, this message translates to:
  /// **'Rechazar {document}'**
  String adminDrvAppRejectTitle(String document);

  /// Panel, solicitudes de chófer: etiqueta de la lista de motivos.
  ///
  /// In es, this message translates to:
  /// **'Motivo del rechazo'**
  String get adminDrvAppRejectReasonLabel;

  /// Panel, solicitudes de chófer: texto de la lista sin elegir.
  ///
  /// In es, this message translates to:
  /// **'Elige un motivo'**
  String get adminDrvAppRejectReasonHint;

  /// Panel, solicitudes de chófer: error: falta elegir el motivo.
  ///
  /// In es, this message translates to:
  /// **'Elige un motivo para rechazar.'**
  String get adminDrvAppRejectReasonRequired;

  /// Panel, solicitudes de chófer: nota opcional para el chófer.
  ///
  /// In es, this message translates to:
  /// **'Nota para el chófer (opcional)'**
  String get adminDrvAppRejectNoteLabel;

  /// Panel, solicitudes de chófer: confirmar rechazo de documento.
  ///
  /// In es, this message translates to:
  /// **'Rechazar documento'**
  String get adminDrvAppRejectConfirm;

  /// Panel, solicitudes de chófer: cancelar un diálogo.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get adminDrvAppCancel;

  /// Panel, solicitudes de chófer: cerrar el visor o un diálogo.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get adminDrvAppClose;

  /// Panel, solicitudes de chófer: el visor pide el enlace.
  ///
  /// In es, this message translates to:
  /// **'Abriendo el documento…'**
  String get adminDrvAppViewerLoading;

  /// Panel, solicitudes de chófer: aviso del visor: el enlace dura 5 minutos.
  ///
  /// In es, this message translates to:
  /// **'El enlace caduca en 5 minutos. Si caduca, cierra el visor y vuelve a abrirlo.'**
  String get adminDrvAppViewerExpiry;

  /// Panel, solicitudes de chófer: aviso: cada apertura se registra.
  ///
  /// In es, this message translates to:
  /// **'Cada apertura queda en la bitácora de accesos.'**
  String get adminDrvAppViewerLogged;

  /// Panel, solicitudes de chófer: el documento es un PDF.
  ///
  /// In es, this message translates to:
  /// **'Este documento es un PDF.'**
  String get adminDrvAppViewerPdf;

  /// Panel, solicitudes de chófer: botón para abrir el PDF en otra pestaña.
  ///
  /// In es, this message translates to:
  /// **'Abrir PDF en otra pestaña'**
  String get adminDrvAppViewerOpenPdf;

  /// Panel, solicitudes de chófer: no se pudo abrir el PDF.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el PDF. Cierra el visor y vuelve a intentarlo.'**
  String get adminDrvAppViewerPdfError;

  /// Panel, solicitudes de chófer: no se pudo mostrar la imagen.
  ///
  /// In es, this message translates to:
  /// **'No se pudo mostrar la imagen. Si el enlace caducó, cierra el visor y vuelve a abrirlo.'**
  String get adminDrvAppViewerImageError;

  /// Panel, solicitudes de chófer: etiqueta accesible de la imagen del documento.
  ///
  /// In es, this message translates to:
  /// **'Imagen del documento: {document}'**
  String adminDrvAppViewerImageLabel(String document);

  /// Panel, solicitudes de chófer: no se pudo pedir el enlace.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el documento.'**
  String get adminDrvAppViewerError;

  /// Panel, solicitudes de chófer: botón que abre la decisión final.
  ///
  /// In es, this message translates to:
  /// **'Decisión final'**
  String get adminDrvAppDecide;

  /// Panel, solicitudes de chófer: título del diálogo de decisión final.
  ///
  /// In es, this message translates to:
  /// **'Decisión final de la solicitud'**
  String get adminDrvAppDecisionTitle;

  /// Panel, solicitudes de chófer: texto del diálogo de decisión.
  ///
  /// In es, this message translates to:
  /// **'Aprobar exige todos los documentos obligatorios aprobados y vigentes. El chófer recibe un aviso con el resultado.'**
  String get adminDrvAppDecisionBody;

  /// Panel, solicitudes de chófer: opción aprobar la solicitud.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get adminDrvAppDecisionApprove;

  /// Panel, solicitudes de chófer: opción pedir cambios.
  ///
  /// In es, this message translates to:
  /// **'Pedir cambios'**
  String get adminDrvAppDecisionNeedsChanges;

  /// Panel, solicitudes de chófer: opción rechazar la solicitud.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get adminDrvAppDecisionReject;

  /// Panel, solicitudes de chófer: etiqueta del motivo.
  ///
  /// In es, this message translates to:
  /// **'Motivo (queda en la auditoría)'**
  String get adminDrvAppDecisionReasonLabel;

  /// Panel, solicitudes de chófer: pista del campo motivo.
  ///
  /// In es, this message translates to:
  /// **'Entre {min} y {max} caracteres'**
  String adminDrvAppDecisionReasonHint(String min, String max);

  /// Panel, solicitudes de chófer: error: motivo demasiado corto.
  ///
  /// In es, this message translates to:
  /// **'Escribe al menos {min} caracteres.'**
  String adminDrvAppDecisionReasonShort(String min);

  /// Panel, solicitudes de chófer: confirmar la decisión.
  ///
  /// In es, this message translates to:
  /// **'Confirmar decisión'**
  String get adminDrvAppDecisionConfirm;

  /// Panel, solicitudes de chófer: la solicitud no admite decisión en su estado.
  ///
  /// In es, this message translates to:
  /// **'Solo se decide una solicitud enviada, en revisión o con cambios pedidos.'**
  String get adminDrvAppDecisionNotDecidable;

  /// Panel, solicitudes de chófer: aviso tras guardar la decisión.
  ///
  /// In es, this message translates to:
  /// **'Decisión guardada: {status}.'**
  String adminDrvAppDecisionDone(String status);

  /// Panel, solicitudes de chófer: error al aprobar: faltan documentos; {documents} es la lista.
  ///
  /// In es, this message translates to:
  /// **'No se puede aprobar: estos documentos obligatorios no están aprobados o vigentes: {documents}.'**
  String adminDrvAppErrDocsNotApproved(String documents);

  /// Panel, solicitudes de chófer: error al aprobar sin lista de documentos.
  ///
  /// In es, this message translates to:
  /// **'No se puede aprobar: hay documentos obligatorios sin aprobar o vencidos.'**
  String get adminDrvAppErrDocsNotApprovedAny;

  /// Panel, solicitudes de chófer: error: el chófer subió otra versión.
  ///
  /// In es, this message translates to:
  /// **'El chófer subió una versión nueva; recarga la solicitud.'**
  String get adminDrvAppErrStaleVersion;

  /// Panel, solicitudes de chófer: error: el documento no se puede revisar.
  ///
  /// In es, this message translates to:
  /// **'Este documento no se puede revisar en su estado actual.'**
  String get adminDrvAppErrNotReviewable;

  /// Panel, solicitudes de chófer: error: la solicitud no admite decisión.
  ///
  /// In es, this message translates to:
  /// **'Esta solicitud ya no admite decisión; recarga.'**
  String get adminDrvAppErrNotDecidable;

  /// Panel, solicitudes de chófer: error: requisitos sin configurar.
  ///
  /// In es, this message translates to:
  /// **'Requisitos sin configurar: no se puede aprobar.'**
  String get adminDrvAppErrRequirements;

  /// Panel, solicitudes de chófer: error: faltan pasos.
  ///
  /// In es, this message translates to:
  /// **'Faltan pasos de la solicitud (datos personales o vehículo).'**
  String get adminDrvAppErrStepsIncomplete;

  /// Panel, solicitudes de chófer: error: documento o chófer no encontrado.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el documento o el chófer; recarga.'**
  String get adminDrvAppErrNotFound;

  /// Panel, solicitudes de chófer: error: datos inválidos.
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos: el motivo necesita entre 10 y 500 caracteres.'**
  String get adminDrvAppErrInvalid;

  /// Panel, solicitudes de chófer: error: sin permiso de admin.
  ///
  /// In es, this message translates to:
  /// **'Permiso denegado: se necesita rol de administrador.'**
  String get adminDrvAppErrPermission;

  /// Panel, solicitudes de chófer: error genérico.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar. Inténtalo de nuevo en unos minutos.'**
  String get adminDrvAppErrGeneric;

  /// Panel, solicitudes de chófer: botón que abre la bitácora de accesos.
  ///
  /// In es, this message translates to:
  /// **'Bitácora de accesos'**
  String get adminDrvAppAccessLog;

  /// Panel, solicitudes de chófer: explicación de la bitácora.
  ///
  /// In es, this message translates to:
  /// **'Quién abrió cada documento de esta solicitud y cuándo, de lo más reciente a lo más antiguo.'**
  String get adminDrvAppAccessLogHint;

  /// Panel, solicitudes de chófer: bitácora vacía.
  ///
  /// In es, this message translates to:
  /// **'Nadie abrió todavía los documentos de esta solicitud.'**
  String get adminDrvAppAccessLogEmpty;

  /// Panel, solicitudes de chófer: no se pudo cargar la bitácora.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la bitácora de accesos.'**
  String get adminDrvAppAccessLogError;

  /// Panel, solicitudes de chófer: línea de la bitácora: documento y versión.
  ///
  /// In es, this message translates to:
  /// **'{document} · versión {version}'**
  String adminDrvAppAccessLogEntry(String document, String version);

  /// Panel, solicitudes de chófer: línea de la bitácora: quién y cuándo.
  ///
  /// In es, this message translates to:
  /// **'{who} · {date}'**
  String adminDrvAppAccessLogWho(String who, String date);

  /// Panel, solicitudes de chófer: administrador sin correo conocido; {id} es su código corto.
  ///
  /// In es, this message translates to:
  /// **'Administrador {id}'**
  String adminDrvAppUnknownAdmin(String id);

  /// Panel, solicitudes de chófer: chip del periodo de vencimientos.
  ///
  /// In es, this message translates to:
  /// **'Próximos {days} días'**
  String adminDrvAppExpiriesPeriod(String days);

  /// Panel, solicitudes de chófer: sin vencimientos en el periodo.
  ///
  /// In es, this message translates to:
  /// **'Ningún documento vence en los próximos {days} días.'**
  String adminDrvAppExpiriesEmpty(String days);

  /// Panel, solicitudes de chófer: no se pudieron cargar los vencimientos.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los vencimientos.'**
  String get adminDrvAppExpiriesError;

  /// Panel, solicitudes de chófer: la lista de vencimientos se recortó.
  ///
  /// In es, this message translates to:
  /// **'Hay más resultados; se muestran los {count} primeros. Acorta el periodo para ver el resto.'**
  String adminDrvAppExpiriesTruncated(String count);

  /// Panel, solicitudes de chófer: el chófer está bloqueado para ponerse en línea.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado para ponerse en línea'**
  String get adminDrvAppBlocked;

  /// Panel, solicitudes de chófer: botón para autorizar en línea.
  ///
  /// In es, this message translates to:
  /// **'Autorizar en línea'**
  String get adminDrvAppAllowOnline;

  /// Panel, solicitudes de chófer: etiqueta accesible del botón autorizar; {name} es el chófer.
  ///
  /// In es, this message translates to:
  /// **'Autorizar en línea a {name}'**
  String adminDrvAppAllowOnlineLabel(String name);

  /// Panel, solicitudes de chófer: título del diálogo de autorizar en línea.
  ///
  /// In es, this message translates to:
  /// **'Autorizar en línea con documentos vencidos'**
  String get adminDrvAppAllowOnlineTitle;

  /// Panel, solicitudes de chófer: texto del diálogo; {name} es el chófer.
  ///
  /// In es, this message translates to:
  /// **'{name} podrá ponerse en línea pese a los documentos vencidos actuales, hasta que venza otro. Queda en la auditoría con tu motivo.'**
  String adminDrvAppAllowOnlineBody(String name);

  /// Panel, solicitudes de chófer: confirmar autorizar en línea.
  ///
  /// In es, this message translates to:
  /// **'Autorizar'**
  String get adminDrvAppAllowOnlineConfirm;

  /// Panel, solicitudes de chófer: aviso tras autorizar.
  ///
  /// In es, this message translates to:
  /// **'Chófer autorizado para ponerse en línea.'**
  String get adminDrvAppAllowOnlineDone;

  /// Panel, vuelos: nombre de la sección del menú.
  ///
  /// In es, this message translates to:
  /// **'Vuelos'**
  String get adminFlightsSection;

  /// Panel, vuelos: subtítulo de la sección.
  ///
  /// In es, this message translates to:
  /// **'Vuelos de llegada por revisar y aeropuertos con sus puntos de recogida.'**
  String get adminFlightsSectionSubtitle;

  /// Panel, vuelos: pestaña de la bandeja.
  ///
  /// In es, this message translates to:
  /// **'Bandeja'**
  String get adminFlightsTabInbox;

  /// Panel, vuelos: pestaña de aeropuertos.
  ///
  /// In es, this message translates to:
  /// **'Aeropuertos'**
  String get adminFlightsTabAirports;

  /// Panel, vuelos: filtro: vuelos que solo declaró el pasajero.
  ///
  /// In es, this message translates to:
  /// **'Por verificar'**
  String get adminFlightsInboxToVerify;

  /// Panel, vuelos: filtro: vuelos sin datos en vivo o con datos viejos.
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get adminFlightsInboxNoData;

  /// Panel, vuelos: filtro: vuelos cancelados o desviados.
  ///
  /// In es, this message translates to:
  /// **'Cancelados o desviados'**
  String get adminFlightsInboxDisrupted;

  /// Panel, vuelos: la lista está recortada; {count} es el máximo leído.
  ///
  /// In es, this message translates to:
  /// **'Se leyeron las primeras {count} reservas con vuelo: puede haber más.'**
  String adminFlightsInboxTruncated(String count);

  /// Panel, vuelos: bandeja vacía (por verificar).
  ///
  /// In es, this message translates to:
  /// **'No hay vuelos por verificar'**
  String get adminFlightsInboxEmptyToVerify;

  /// Panel, vuelos: bandeja vacía (sin datos).
  ///
  /// In es, this message translates to:
  /// **'No hay vuelos sin datos'**
  String get adminFlightsInboxEmptyNoData;

  /// Panel, vuelos: bandeja vacía (cancelados o desviados).
  ///
  /// In es, this message translates to:
  /// **'No hay vuelos cancelados ni desviados'**
  String get adminFlightsInboxEmptyDisrupted;

  /// Panel, vuelos: explicación bajo la bandeja vacía.
  ///
  /// In es, this message translates to:
  /// **'Aquí aparecen las reservas con vuelo que piden revisión.'**
  String get adminFlightsInboxEmptyHint;

  /// Panel, vuelos: no se pudo leer la bandeja.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la bandeja de vuelos'**
  String get adminFlightsInboxError;

  /// Panel, vuelos: botón para volver a intentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get adminFlightsRetry;

  /// Panel, vuelos: fila: hora a la que el chófer debe estar en el punto.
  ///
  /// In es, this message translates to:
  /// **'Chófer en el punto: {time}'**
  String adminFlightsRowReadyAt(String time);

  /// Panel, vuelos: fila: sin hora de recogida calculada.
  ///
  /// In es, this message translates to:
  /// **'Sin hora de recogida'**
  String get adminFlightsRowNoReadyAt;

  /// Panel, vuelos: lector de pantalla de una fila de la bandeja.
  ///
  /// In es, this message translates to:
  /// **'Reserva {code}, vuelo {flight}, {status}. Abrir el detalle'**
  String adminFlightsRowSemantics(String code, String flight, String status);

  /// Panel, vuelos: título del detalle cuando la reserva no está en la lista del panel.
  ///
  /// In es, this message translates to:
  /// **'Reserva #{code}'**
  String adminFlightsBookingTitle(String code);

  /// Panel, vuelos: botón para cerrar el detalle.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get adminFlightsClose;

  /// Panel, vuelos: título de la tarjeta del vuelo en el detalle de la reserva.
  ///
  /// In es, this message translates to:
  /// **'Vuelo'**
  String get adminFlightCardTitle;

  /// Panel, vuelos: fila: aeropuerto.
  ///
  /// In es, this message translates to:
  /// **'Aeropuerto'**
  String get adminFlightAirport;

  /// Panel, vuelos: fila: aerolínea.
  ///
  /// In es, this message translates to:
  /// **'Aerolínea'**
  String get adminFlightAirline;

  /// Panel, vuelos: fila: número de vuelo.
  ///
  /// In es, this message translates to:
  /// **'Número de vuelo'**
  String get adminFlightNumber;

  /// Panel, vuelos: fila: tipo de vuelo (nacional o internacional).
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get adminFlightType;

  /// Panel, vuelos: fila: fecha del vuelo.
  ///
  /// In es, this message translates to:
  /// **'Fecha del vuelo'**
  String get adminFlightDate;

  /// Panel, vuelos: fila: llegada programada.
  ///
  /// In es, this message translates to:
  /// **'Llegada programada'**
  String get adminFlightScheduled;

  /// Panel, vuelos: fila: llegada estimada.
  ///
  /// In es, this message translates to:
  /// **'Llegada estimada'**
  String get adminFlightEstimated;

  /// Panel, vuelos: fila: llegada real.
  ///
  /// In es, this message translates to:
  /// **'Llegada real'**
  String get adminFlightActual;

  /// Panel, vuelos: fila: estado del vuelo.
  ///
  /// In es, this message translates to:
  /// **'Estado del vuelo'**
  String get adminFlightStatus;

  /// Panel, vuelos: fila: calidad del dato.
  ///
  /// In es, this message translates to:
  /// **'Calidad del dato'**
  String get adminFlightQuality;

  /// Panel, vuelos: calidad del dato: reciente.
  ///
  /// In es, this message translates to:
  /// **'Al día'**
  String get adminFlightQualityOk;

  /// Panel, vuelos: calidad del dato: viejo.
  ///
  /// In es, this message translates to:
  /// **'Desactualizado'**
  String get adminFlightQualityStale;

  /// Panel, vuelos: calidad del dato: solo lo declarado por el pasajero.
  ///
  /// In es, this message translates to:
  /// **'Sin datos en vivo'**
  String get adminFlightQualityNone;

  /// Panel, vuelos: fila: quién dio el último dato.
  ///
  /// In es, this message translates to:
  /// **'Fuente'**
  String get adminFlightSource;

  /// Panel, vuelos: fuente: el pasajero.
  ///
  /// In es, this message translates to:
  /// **'Pasajero'**
  String get adminFlightSourcePassenger;

  /// Panel, vuelos: fuente: un admin de central.
  ///
  /// In es, this message translates to:
  /// **'Central'**
  String get adminFlightSourceManual;

  /// Panel, vuelos: fuente: consulta automática.
  ///
  /// In es, this message translates to:
  /// **'Automático'**
  String get adminFlightSourceAuto;

  /// Panel, vuelos: fila: lleva equipaje facturado.
  ///
  /// In es, this message translates to:
  /// **'Equipaje facturado'**
  String get adminFlightCheckedBag;

  /// Panel, vuelos: sí.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get adminFlightYes;

  /// Panel, vuelos: no.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get adminFlightNo;

  /// Panel, vuelos: fila: último cambio del vuelo.
  ///
  /// In es, this message translates to:
  /// **'Último cambio'**
  String get adminFlightLastChange;

  /// Panel, vuelos: fila: última vez que se leyó el dato.
  ///
  /// In es, this message translates to:
  /// **'Último dato leído'**
  String get adminFlightLastObserved;

  /// Panel, vuelos: aclaración de la zona horaria de las horas.
  ///
  /// In es, this message translates to:
  /// **'Horas de Bolivia (La Paz, UTC−4).'**
  String get adminFlightTimesNote;

  /// Panel, vuelos: hora a la que el chófer debe estar en el punto de recogida.
  ///
  /// In es, this message translates to:
  /// **'El chófer debe estar a las {time}'**
  String adminFlightReadyAt(String time);

  /// Panel, vuelos: sin hora de recogida calculada.
  ///
  /// In es, this message translates to:
  /// **'Sin hora de recogida calculada'**
  String get adminFlightNoReadyAt;

  /// Panel, vuelos: indicador de bloqueo manual activo.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo manual: las fuentes automáticas no cambian estos datos.'**
  String get adminFlightLocked;

  /// Panel, vuelos: sin bloqueo manual.
  ///
  /// In es, this message translates to:
  /// **'Sin bloqueo manual'**
  String get adminFlightUnlocked;

  /// Panel, vuelos: etiqueta corta de bloqueo manual.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo manual'**
  String get adminFlightLockTag;

  /// Panel, vuelos: quién y cuándo fijó los datos a mano.
  ///
  /// In es, this message translates to:
  /// **'Fijado por {who} el {date}'**
  String adminFlightSetBy(String who, String date);

  /// Panel, vuelos: quién y cuándo quitó el bloqueo manual.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo quitado por {who} el {date}'**
  String adminFlightLockClearedBy(String who, String date);

  /// Panel, vuelos: motivo del último cambio manual.
  ///
  /// In es, this message translates to:
  /// **'Motivo: {reason}'**
  String adminFlightChangeReason(String reason);

  /// Panel, vuelos: autor sin correo conocido.
  ///
  /// In es, this message translates to:
  /// **'un administrador'**
  String get adminFlightAdminUnknown;

  /// Panel, vuelos: no se pudo leer el vuelo.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron leer los datos del vuelo'**
  String get adminFlightLoadError;

  /// Panel, vuelos: botón para fijar los datos del vuelo a mano.
  ///
  /// In es, this message translates to:
  /// **'Fijar datos del vuelo'**
  String get adminFlightSetButton;

  /// Panel, vuelos: botón para quitar el bloqueo manual.
  ///
  /// In es, this message translates to:
  /// **'Quitar bloqueo manual'**
  String get adminFlightClearLockButton;

  /// Panel, vuelos: botón para marcar que el pasajero no se presentó.
  ///
  /// In es, this message translates to:
  /// **'Marcar no se presentó'**
  String get adminFlightForceNoShowButton;

  /// Panel, vuelos: título del diálogo para fijar el vuelo.
  ///
  /// In es, this message translates to:
  /// **'Fijar datos del vuelo'**
  String get adminFlightSetTitle;

  /// Panel, vuelos: explicación del diálogo para fijar el vuelo.
  ///
  /// In es, this message translates to:
  /// **'Los datos quedan fijados a mano, con bloqueo manual: ninguna fuente automática los cambia hasta quitar el bloqueo. La hora del chófer se vuelve a calcular.'**
  String get adminFlightSetMessage;

  /// Panel, vuelos: campo: estado del vuelo.
  ///
  /// In es, this message translates to:
  /// **'Estado del vuelo'**
  String get adminFlightSetStatusLabel;

  /// Panel, vuelos: botón para elegir fecha y hora.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha y hora'**
  String get adminFlightSetPick;

  /// Panel, vuelos: botón para dejar la hora vacía.
  ///
  /// In es, this message translates to:
  /// **'Quitar hora'**
  String get adminFlightSetClearTime;

  /// Panel, vuelos: sin hora elegida.
  ///
  /// In es, this message translates to:
  /// **'Sin hora'**
  String get adminFlightSetNoTime;

  /// Panel, vuelos: lector de pantalla del selector de hora.
  ///
  /// In es, this message translates to:
  /// **'{label}: {value}. Cambiar'**
  String adminFlightSetTimeSemantics(String label, String value);

  /// Panel, vuelos: error: con «Aterrizó» la llegada real es obligatoria.
  ///
  /// In es, this message translates to:
  /// **'Con «Aterrizó» la llegada real es obligatoria'**
  String get adminFlightSetActualRequired;

  /// Panel, vuelos: campo de motivo.
  ///
  /// In es, this message translates to:
  /// **'Motivo (de 10 a 500 caracteres)'**
  String get adminFlightReasonLabel;

  /// Panel, vuelos: error: motivo corto.
  ///
  /// In es, this message translates to:
  /// **'El motivo necesita al menos 10 caracteres'**
  String get adminFlightReasonShort;

  /// Panel, vuelos: botón cancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get adminFlightCancel;

  /// Panel, vuelos: botón para confirmar los datos del vuelo.
  ///
  /// In es, this message translates to:
  /// **'Fijar datos'**
  String get adminFlightSetConfirm;

  /// Panel, vuelos: aviso: datos fijados.
  ///
  /// In es, this message translates to:
  /// **'Datos del vuelo fijados'**
  String get adminFlightSetDone;

  /// Panel, vuelos: título: quitar bloqueo manual.
  ///
  /// In es, this message translates to:
  /// **'Quitar bloqueo manual'**
  String get adminFlightClearLockTitle;

  /// Panel, vuelos: explicación de quitar el bloqueo.
  ///
  /// In es, this message translates to:
  /// **'Las fuentes automáticas podrán volver a actualizar este vuelo.'**
  String get adminFlightClearLockMessage;

  /// Panel, vuelos: botón para quitar el bloqueo.
  ///
  /// In es, this message translates to:
  /// **'Quitar bloqueo'**
  String get adminFlightClearLockConfirm;

  /// Panel, vuelos: aviso: bloqueo quitado.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo manual quitado'**
  String get adminFlightClearLockDone;

  /// Panel, vuelos: título: marcar que el pasajero no se presentó.
  ///
  /// In es, this message translates to:
  /// **'Marcar no se presentó'**
  String get adminFlightForceNoShowTitle;

  /// Panel, vuelos: explicación de marcar que no se presentó; {code} es la reserva.
  ///
  /// In es, this message translates to:
  /// **'La reserva #{code} pasará a «No se presentó». No se cobra nada: el pago se decide después en la reserva.'**
  String adminFlightForceNoShowMessage(String code);

  /// Panel, vuelos: botón para confirmar que no se presentó.
  ///
  /// In es, this message translates to:
  /// **'Marcar no se presentó'**
  String get adminFlightForceNoShowConfirm;

  /// Panel, vuelos: aviso: marcada como no se presentó.
  ///
  /// In es, this message translates to:
  /// **'Reserva marcada como no se presentó'**
  String get adminFlightForceNoShowDone;

  /// Panel, vuelos: error flight_config_missing.
  ///
  /// In es, this message translates to:
  /// **'Faltan los minutos de salida del aeropuerto en la configuración de operaciones.'**
  String get adminFlightErrConfigMissing;

  /// Panel, vuelos: error booking_without_flight.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva no tiene vuelo.'**
  String get adminFlightErrNoFlight;

  /// Panel, vuelos: error booking_not_found.
  ///
  /// In es, this message translates to:
  /// **'La reserva ya no existe.'**
  String get adminFlightErrNotFound;

  /// Panel, vuelos: error invalid_transition.
  ///
  /// In es, this message translates to:
  /// **'La reserva ya no está en «Chófer en el punto».'**
  String get adminFlightErrInvalidTransition;

  /// Panel, vuelos: error no_show_disabled.
  ///
  /// In es, this message translates to:
  /// **'«No se presentó» no está habilitado: falta la política de cancelación.'**
  String get adminFlightErrNoShowDisabled;

  /// Panel, vuelos: error de datos no válidos.
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos: alguno no es válido.'**
  String get adminFlightErrInvalid;

  /// Panel, vuelos: error de permiso.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para esta acción.'**
  String get adminFlightErrPermission;

  /// Panel, vuelos: error genérico.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la acción. Inténtalo de nuevo.'**
  String get adminFlightErrGeneric;

  /// Panel, vuelos: botón para crear un aeropuerto.
  ///
  /// In es, this message translates to:
  /// **'Nuevo aeropuerto'**
  String get adminAirportsAdd;

  /// Panel, vuelos: lista de aeropuertos vacía.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay aeropuertos'**
  String get adminAirportsEmpty;

  /// Panel, vuelos: explicación bajo la lista vacía.
  ///
  /// In es, this message translates to:
  /// **'Crea uno para definir sus puntos de recogida.'**
  String get adminAirportsEmptyHint;

  /// Panel, vuelos: no se pudo leer la lista de aeropuertos.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los aeropuertos'**
  String get adminAirportsError;

  /// Panel, vuelos: etiqueta: el aeropuerto tiene punto para ese tipo de vuelo.
  ///
  /// In es, this message translates to:
  /// **'{type}: con punto'**
  String adminAirportPointSet(String type);

  /// Panel, vuelos: etiqueta: el aeropuerto no tiene punto para ese tipo de vuelo.
  ///
  /// In es, this message translates to:
  /// **'{type}: sin punto'**
  String adminAirportPointMissing(String type);

  /// Panel, vuelos: lector de pantalla: editar un aeropuerto.
  ///
  /// In es, this message translates to:
  /// **'Editar el aeropuerto {code}'**
  String adminAirportEditSemantics(String code);

  /// Panel, vuelos: título del editor de un aeropuerto existente.
  ///
  /// In es, this message translates to:
  /// **'Editar aeropuerto {code}'**
  String adminAirportEditTitle(String code);

  /// Panel, vuelos: título del editor de un aeropuerto nuevo.
  ///
  /// In es, this message translates to:
  /// **'Nuevo aeropuerto'**
  String get adminAirportNewTitle;

  /// Panel, vuelos: campo: código del aeropuerto.
  ///
  /// In es, this message translates to:
  /// **'Código (3 letras)'**
  String get adminAirportCode;

  /// Panel, vuelos: error del código.
  ///
  /// In es, this message translates to:
  /// **'Tres letras mayúsculas, por ejemplo VVI'**
  String get adminAirportCodeInvalid;

  /// Panel, vuelos: ayuda: el código no se cambia.
  ///
  /// In es, this message translates to:
  /// **'El código no se cambia una vez creado'**
  String get adminAirportCodeLocked;

  /// Panel, vuelos: campo: nombre del aeropuerto.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get adminAirportName;

  /// Panel, vuelos: error del nombre.
  ///
  /// In es, this message translates to:
  /// **'Entre 2 y 120 caracteres'**
  String get adminAirportNameInvalid;

  /// Panel, vuelos: campo: ciudad.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get adminAirportCity;

  /// Panel, vuelos: error de la ciudad.
  ///
  /// In es, this message translates to:
  /// **'Entre 2 y 80 caracteres'**
  String get adminAirportCityInvalid;

  /// Panel, vuelos: zona horaria fija del aeropuerto.
  ///
  /// In es, this message translates to:
  /// **'Zona horaria: La Paz (UTC−4)'**
  String get adminAirportTimeZone;

  /// Panel, vuelos: título del punto de recogida de un tipo de vuelo.
  ///
  /// In es, this message translates to:
  /// **'Punto de recogida · {type}'**
  String adminAirportPointTitle(String type);

  /// Panel, vuelos: campo: nombre del punto.
  ///
  /// In es, this message translates to:
  /// **'Nombre del punto'**
  String get adminAirportPointName;

  /// Panel, vuelos: error del nombre del punto.
  ///
  /// In es, this message translates to:
  /// **'Entre 1 y 80 caracteres'**
  String get adminAirportPointNameInvalid;

  /// Panel, vuelos: campo: indicaciones del punto.
  ///
  /// In es, this message translates to:
  /// **'Indicaciones'**
  String get adminAirportPointInstructions;

  /// Panel, vuelos: error de las indicaciones.
  ///
  /// In es, this message translates to:
  /// **'Hasta 500 caracteres'**
  String get adminAirportPointInstructionsInvalid;

  /// Panel, vuelos: campo: latitud.
  ///
  /// In es, this message translates to:
  /// **'Latitud'**
  String get adminAirportLat;

  /// Panel, vuelos: campo: longitud.
  ///
  /// In es, this message translates to:
  /// **'Longitud'**
  String get adminAirportLng;

  /// Panel, vuelos: error de la latitud.
  ///
  /// In es, this message translates to:
  /// **'Latitud entre -90 y 90'**
  String get adminAirportLatInvalid;

  /// Panel, vuelos: error de la longitud.
  ///
  /// In es, this message translates to:
  /// **'Longitud entre -180 y 180'**
  String get adminAirportLngInvalid;

  /// Panel, vuelos: error: coordenadas (0, 0).
  ///
  /// In es, this message translates to:
  /// **'Las coordenadas (0, 0) no son válidas'**
  String get adminAirportZeroInvalid;

  /// Panel, vuelos: botón para quitar el punto.
  ///
  /// In es, this message translates to:
  /// **'Quitar punto'**
  String get adminAirportPointRemove;

  /// Panel, vuelos: botón para añadir el punto.
  ///
  /// In es, this message translates to:
  /// **'Añadir punto'**
  String get adminAirportPointAdd;

  /// Panel, vuelos: sin punto definido para ese tipo de vuelo.
  ///
  /// In es, this message translates to:
  /// **'Sin punto: el chófer verá «Punto por confirmar con central».'**
  String get adminAirportPointNone;

  /// Panel, vuelos: el punto se quitará al guardar.
  ///
  /// In es, this message translates to:
  /// **'El punto se quitará al guardar.'**
  String get adminAirportPointWillRemove;

  /// Panel, vuelos: botón guardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get adminAirportSave;

  /// Panel, vuelos: aviso: aeropuerto guardado.
  ///
  /// In es, this message translates to:
  /// **'Aeropuerto guardado'**
  String get adminAirportSaved;

  /// Panel, vuelos: aviso: hay campos con error.
  ///
  /// In es, this message translates to:
  /// **'Revisa los campos marcados'**
  String get adminAirportFixErrors;

  /// Panel, vuelos: error de datos no válidos al guardar el aeropuerto.
  ///
  /// In es, this message translates to:
  /// **'Algún dato no es válido: revisa código, nombre, ciudad y coordenadas.'**
  String get adminAirportErrInvalid;

  /// Panel de admin, detalle de una reserva: el pasajero no dejó preferencias para este viaje.
  ///
  /// In es, this message translates to:
  /// **'Sin preferencias para este viaje'**
  String get adminPrefsEmpty;

  /// Panel de admin: etiqueta de accesibilidad mientras se cargan las preferencias de la reserva.
  ///
  /// In es, this message translates to:
  /// **'Cargando las preferencias del viaje'**
  String get adminPrefsLoadingLabel;

  /// Título de la pantalla de inicio de sesión (web) y botón principal para entrar.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get authLoginTitle;

  /// Subtítulo bajo «Iniciar sesión» en la web.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de nuevo a Luxelane.'**
  String get authLoginWelcomeBack;

  /// Etiqueta de lector de pantalla del logo que lleva al inicio (inicio de sesión y registro).
  ///
  /// In es, this message translates to:
  /// **'Luxelane, ir al inicio'**
  String get authHomeLinkSemantics;

  /// Antetítulo en mayúsculas de la pantalla de inicio de sesión (móvil).
  ///
  /// In es, this message translates to:
  /// **'BIENVENIDO'**
  String get authLoginEyebrow;

  /// Titular grande del inicio de sesión (móvil) y del panel de marca en la web; el salto de línea es intencional.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer,\ncomo lo recuerdas.'**
  String get authLoginHeadline;

  /// Texto bajo el titular del inicio de sesión (móvil).
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para reservar y seguir tus trayectos.'**
  String get authLoginSubtitle;

  /// Etiqueta del campo de correo (inicio de sesión y registro).
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get authEmailLabel;

  /// Error del campo de correo cuando no parece un correo.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo válido'**
  String get authEmailInvalid;

  /// Etiqueta del campo de contraseña.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get authPasswordLabel;

  /// Error del campo de contraseña si es demasiado corta.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get authPasswordMinLength;

  /// Enlace para pedir un enlace de cambio de contraseña.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get authForgotPassword;

  /// Aviso al pedir el cambio de contraseña sin haber escrito el correo.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu correo arriba y te enviaremos un enlace.'**
  String get authResetNeedsEmail;

  /// Texto antes del enlace «Crear una» (el espacio final separa del enlace).
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? '**
  String get authNoAccount;

  /// Enlace a la pantalla de registro, tras «¿No tienes cuenta?».
  ///
  /// In es, this message translates to:
  /// **'Crear una'**
  String get authCreateOne;

  /// Subtítulo del panel de marca de la web en el inicio de sesión.
  ///
  /// In es, this message translates to:
  /// **'Tus direcciones, preferencias y viajes, siempre a mano.'**
  String get authBrandSubtitle;

  /// Punto destacado del panel de marca (web).
  ///
  /// In es, this message translates to:
  /// **'Reserva en menos de 2 minutos'**
  String get authBrandPointBooking;

  /// Punto destacado del panel de marca (web).
  ///
  /// In es, this message translates to:
  /// **'Todos tus viajes en un solo lugar'**
  String get authBrandPointTrips;

  /// Punto destacado del panel de marca (web).
  ///
  /// In es, this message translates to:
  /// **'Seguimiento de tu chófer en tiempo real'**
  String get authBrandPointTracking;

  /// Antetítulo en mayúsculas de la pantalla de registro (móvil).
  ///
  /// In es, this message translates to:
  /// **'CREAR CUENTA'**
  String get authRegisterEyebrow;

  /// Titular grande del registro (móvil y panel de marca web); el salto de línea es intencional.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido\na Luxelane.'**
  String get authRegisterHeadline;

  /// Texto bajo el titular del registro (móvil).
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta en menos de un minuto.'**
  String get authRegisterSubtitle;

  /// Subtítulo del panel de marca de la web en el registro.
  ///
  /// In es, this message translates to:
  /// **'Una cuenta para reservar, seguir y recordar cada trayecto.'**
  String get authRegisterBrandSubtitle;

  /// Título del registro (web) y botón para crear la cuenta.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get authRegisterTitle;

  /// Subtítulo bajo «Crear cuenta» en la web.
  ///
  /// In es, this message translates to:
  /// **'Solo te pediremos lo necesario para tu chófer.'**
  String get authRegisterWebSubtitle;

  /// Botón de registro con la cuenta de Google.
  ///
  /// In es, this message translates to:
  /// **'Registrarte con Google'**
  String get authGoogleRegister;

  /// Etiqueta del campo de nombre en el registro.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get authNameLabel;

  /// Error si el nombre está vacío en el registro.
  ///
  /// In es, this message translates to:
  /// **'Indica tu nombre para que tu chófer pueda recibirte'**
  String get authNameRequired;

  /// Etiqueta del campo de teléfono en el registro.
  ///
  /// In es, this message translates to:
  /// **'Teléfono (con código de país)'**
  String get authPhoneLabel;

  /// Error si el teléfono es demasiado corto en el registro.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer lo necesita para contactarte'**
  String get authPhoneRequired;

  /// Error si no se marcó la casilla de términos al registrarse.
  ///
  /// In es, this message translates to:
  /// **'Acepta los Términos y la Política de privacidad para continuar'**
  String get authTermsRequired;

  /// Nota bajo el botón de registro: para qué se piden nombre y teléfono.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre y teléfono permiten a tu chófer recibirte y contactarte.'**
  String get authRegisterDataNote;

  /// Texto antes del enlace «Inicia sesión» (el espacio final separa del enlace).
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? '**
  String get authHaveAccount;

  /// Enlace a la pantalla de inicio de sesión desde el registro.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get authSignInLink;

  /// Etiqueta de lector de pantalla de la casilla de términos.
  ///
  /// In es, this message translates to:
  /// **'Acepto los Términos y la Política de privacidad'**
  String get authTermsCheckboxSemantics;

  /// Primera parte de «He leído y acepto los Términos y la Política de privacidad.»; sigue el enlace «Términos» (espacio final).
  ///
  /// In es, this message translates to:
  /// **'He leído y acepto los '**
  String get authTermsReadPrefix;

  /// Enlace a los Términos dentro de la frase de la casilla.
  ///
  /// In es, this message translates to:
  /// **'Términos'**
  String get authTermsLink;

  /// Unión entre los enlaces «Términos» y «Política de privacidad» (espacios a ambos lados).
  ///
  /// In es, this message translates to:
  /// **' y la '**
  String get authTermsAnd;

  /// Enlace a la Política de privacidad dentro de la frase de la casilla.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get authPrivacyLink;

  /// Botón para entrar con la cuenta de Google (también en «Confirma que eres tú»).
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get authGoogleContinue;

  /// Separador entre Google y el formulario de correo; se muestra en mayúsculas.
  ///
  /// In es, this message translates to:
  /// **'o con tu correo'**
  String get authOrWithEmail;

  /// Título de la pantalla «Verifica tu correo».
  ///
  /// In es, this message translates to:
  /// **'Verifica tu correo'**
  String get authVerifyTitle;

  /// Encabezado de «Verifica tu correo» cuando no se conoce la dirección.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un enlace a tu correo.'**
  String get authVerifySentGeneric;

  /// Encabezado de «Verifica tu correo» con la dirección.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un enlace a {email}.'**
  String authVerifySentTo(String email);

  /// Explicación de «Verifica tu correo».
  ///
  /// In es, this message translates to:
  /// **'Ábrelo y vuelve aquí. Necesitas el correo verificado para reservar. Si el enlace venció o no llega, pide uno nuevo (revisa también la carpeta de correo no deseado).'**
  String get authVerifyBody;

  /// Aviso tras reenviar el enlace de verificación.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un enlace nuevo.'**
  String get authVerifyResent;

  /// Aviso al comprobar que el correo ya está verificado.
  ///
  /// In es, this message translates to:
  /// **'Correo verificado. Ya puedes reservar.'**
  String get authVerifyDone;

  /// Error si al comprobar el correo aún no está verificado.
  ///
  /// In es, this message translates to:
  /// **'Aún no vemos el correo verificado. Abre el enlace que te enviamos y vuelve a intentarlo.'**
  String get authVerifyNotYet;

  /// Botón de reenvío deshabilitado tras el máximo de reenvíos.
  ///
  /// In es, this message translates to:
  /// **'Límite de reenvíos alcanzado'**
  String get authVerifyResendLimit;

  /// Botón de reenvío mientras corre la espera, con los segundos que faltan.
  ///
  /// In es, this message translates to:
  /// **'Reenviar enlace ({seconds} s)'**
  String authVerifyResendIn(int seconds);

  /// Botón para reenviar el enlace de verificación.
  ///
  /// In es, this message translates to:
  /// **'Reenviar enlace'**
  String get authVerifyResend;

  /// Botón para comprobar que el correo ya se verificó.
  ///
  /// In es, this message translates to:
  /// **'Ya lo verifiqué'**
  String get authVerifyConfirm;

  /// Botón para dejar la verificación del correo para después.
  ///
  /// In es, this message translates to:
  /// **'Más tarde'**
  String get authVerifyLater;

  /// Título de las pantallas de verificación en dos pasos (alta y segundo paso al entrar).
  ///
  /// In es, this message translates to:
  /// **'Verificación en dos pasos'**
  String get authMfaTitle;

  /// Error si el código de la app autenticadora no tiene 6 cifras.
  ///
  /// In es, this message translates to:
  /// **'Escribe las 6 cifras del código.'**
  String get authMfaCodeDigits;

  /// Botón o descripción emergente para cancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get authCancel;

  /// Instrucción del segundo paso al iniciar sesión.
  ///
  /// In es, this message translates to:
  /// **'Abre tu app autenticadora y escribe el código de Luxelane.'**
  String get authMfaSignInPrompt;

  /// Etiqueta del campo del código de 6 cifras.
  ///
  /// In es, this message translates to:
  /// **'Código'**
  String get authMfaCodeLabel;

  /// Botón para entrar con el código del segundo paso.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get authMfaSignInButton;

  /// Ayuda si se perdió la app autenticadora.
  ///
  /// In es, this message translates to:
  /// **'¿Perdiste el acceso a tu app autenticadora? Contacta con central para recuperar la cuenta.'**
  String get authMfaLostAccess;

  /// Mensaje al terminar el alta de la app autenticadora.
  ///
  /// In es, this message translates to:
  /// **'Listo. A partir de ahora, al iniciar sesión te pediremos el código de tu app autenticadora.'**
  String get authMfaEnrollDone;

  /// Botón para volver tras el alta de la app autenticadora.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get authMfaBack;

  /// Explicación antes de empezar el alta de la app autenticadora.
  ///
  /// In es, this message translates to:
  /// **'Protege tu cuenta con una app autenticadora (por ejemplo, la que trae tu teléfono o tu gestor de contraseñas). Te pedirá un código de 6 cifras al iniciar sesión.'**
  String get authMfaEnrollIntro;

  /// Botón para empezar el alta de la app autenticadora.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get authMfaStart;

  /// Paso 1 del alta: escanear el código QR.
  ///
  /// In es, this message translates to:
  /// **'1. Escanea este código con tu app autenticadora.'**
  String get authMfaScanStep;

  /// Etiqueta de lector de pantalla del código QR.
  ///
  /// In es, this message translates to:
  /// **'Código QR para la app autenticadora'**
  String get authMfaQrSemantics;

  /// Botón para abrir el alta directamente en la app autenticadora.
  ///
  /// In es, this message translates to:
  /// **'Abrir en la app autenticadora'**
  String get authMfaOpenInApp;

  /// Clave para escribir a mano si no se puede escanear; {key} es la clave o puntos si está oculta.
  ///
  /// In es, this message translates to:
  /// **'¿No puedes escanear? Escribe esta clave: {key}'**
  String authMfaManualKey(String key);

  /// Botón para ocultar la clave escrita.
  ///
  /// In es, this message translates to:
  /// **'Ocultar clave'**
  String get authMfaHideKey;

  /// Botón para mostrar la clave escrita.
  ///
  /// In es, this message translates to:
  /// **'Mostrar clave'**
  String get authMfaShowKey;

  /// Advertencia de seguridad bajo el código QR.
  ///
  /// In es, this message translates to:
  /// **'No compartas este código ni la clave, y no hagas capturas.'**
  String get authMfaNoShare;

  /// Paso 2 del alta: escribir el código.
  ///
  /// In es, this message translates to:
  /// **'2. Escribe el código que muestra la app.'**
  String get authMfaCodeStep;

  /// Botón para terminar el alta de la app autenticadora.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get authMfaActivate;

  /// Título del aviso para dar de alta la verificación en dos pasos.
  ///
  /// In es, this message translates to:
  /// **'Activa la verificación en dos pasos'**
  String get authMfaReminderTitle;

  /// Detalle del aviso de verificación en dos pasos.
  ///
  /// In es, this message translates to:
  /// **'Pronto será obligatoria para entrar. Tarda un minuto.'**
  String get authMfaReminderBody;

  /// Aviso tras confirmar la identidad: hay que repetir la acción.
  ///
  /// In es, this message translates to:
  /// **'Identidad confirmada. Repite la acción.'**
  String get authReauthConfirmed;

  /// Error si se confirma sin escribir la contraseña.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu contraseña.'**
  String get authReauthPasswordEmpty;

  /// Título del diálogo para volver a identificarse.
  ///
  /// In es, this message translates to:
  /// **'Confirma que eres tú'**
  String get authReauthTitle;

  /// Explicación del diálogo con contraseña.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, escribe tu contraseña para continuar.'**
  String get authReauthPassword;

  /// Explicación del diálogo con cuenta de Google.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, vuelve a entrar con Google para continuar.'**
  String get authReauthGoogle;

  /// Explicación del diálogo sin método disponible.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, cierra sesión y vuelve a entrar para continuar.'**
  String get authReauthNone;

  /// Botón para confirmar la contraseña.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get authConfirm;

  /// Aviso tras aceptar los términos vigentes desde el diálogo.
  ///
  /// In es, this message translates to:
  /// **'Listo. Ya puedes reservar.'**
  String get authTermsAcceptedSnack;

  /// Título del diálogo que pide aceptar los términos vigentes.
  ///
  /// In es, this message translates to:
  /// **'Acepta los términos para reservar'**
  String get authTermsDialogTitle;

  /// Texto del diálogo que pide aceptar los términos vigentes.
  ///
  /// In es, this message translates to:
  /// **'Para reservar necesitamos que aceptes la versión vigente de los Términos y la Política de privacidad.'**
  String get authTermsDialogBody;

  /// Botón para abrir los Términos.
  ///
  /// In es, this message translates to:
  /// **'Leer los Términos'**
  String get authTermsRead;

  /// Botón para abrir la Política de privacidad.
  ///
  /// In es, this message translates to:
  /// **'Leer la Política de privacidad'**
  String get authPrivacyRead;

  /// Botón para cerrar el diálogo sin aceptar.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get authNotNow;

  /// Botón para aceptar los términos vigentes.
  ///
  /// In es, this message translates to:
  /// **'Acepto'**
  String get authAccept;

  /// Error sin conexión al entrar con Google.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu internet e inténtalo de nuevo.'**
  String get authErrorOffline;

  /// Error genérico al entrar con Google.
  ///
  /// In es, this message translates to:
  /// **'No pudimos iniciar sesión con Google. Inténtalo de nuevo.'**
  String get authGoogleGenericError;

  /// Error de Google: ya hay una cuenta con ese correo y contraseña.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes una cuenta con este correo. Inicia sesión con tu contraseña.'**
  String get authGoogleAccountExists;

  /// Error de Google en la web: el navegador bloqueó la ventana.
  ///
  /// In es, this message translates to:
  /// **'Tu navegador bloqueó la ventana de Google. Permite las ventanas emergentes e inténtalo de nuevo.'**
  String get authGooglePopupBlocked;

  /// Error de Google en la web: dominio no autorizado.
  ///
  /// In es, this message translates to:
  /// **'Este dominio no está autorizado para iniciar sesión con Google.'**
  String get authGoogleUnauthorizedDomain;

  /// Error de Google: el inicio de sesión con Google está desactivado.
  ///
  /// In es, this message translates to:
  /// **'El inicio de sesión con Google no está habilitado.'**
  String get authGoogleNotEnabled;

  /// Error al eliminar la cuenta sin respuesta del servidor.
  ///
  /// In es, this message translates to:
  /// **'No pudimos eliminar tu cuenta. Revisa tu conexión.'**
  String get authDeleteAccountError;

  /// Error al enviar el enlace para cambiar la contraseña.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enviar el enlace. Inténtalo de nuevo.'**
  String get authResetLinkError;

  /// Error de verificación del correo: demasiados enlaces seguidos.
  ///
  /// In es, this message translates to:
  /// **'Enviamos varios enlaces seguidos. Espera unos minutos antes de pedir otro.'**
  String get authVerifyTooMany;

  /// Error de verificación del correo sin conexión.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu red e inténtalo de nuevo.'**
  String get authVerifyOffline;

  /// Error genérico de verificación del correo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la verificación. Inténtalo de nuevo.'**
  String get authVerifyFailed;

  /// Precio de una clase sin tarifa configurada: se cotiza al reservar.
  ///
  /// In es, this message translates to:
  /// **'Cotiza al reservar'**
  String get bookingPriceOnRequest;

  /// Precio mínimo de una clase cuando aún no hay ruta («desde Bs 70»).
  ///
  /// In es, this message translates to:
  /// **'desde {price}'**
  String bookingPriceFrom(String price);

  /// Título del diálogo cuando el servidor cambia el precio al reservar.
  ///
  /// In es, this message translates to:
  /// **'El precio cambió'**
  String get bookingPriceChangedTitle;

  /// Texto del diálogo de precio cambiado, con el precio nuevo y el anterior.
  ///
  /// In es, this message translates to:
  /// **'El precio de este viaje es ahora {newPrice} (antes {previousPrice}). ¿Quieres reservar con el precio nuevo?'**
  String bookingPriceChangedBody(String newPrice, String previousPrice);

  /// Botón del diálogo de precio cambiado: no reservar.
  ///
  /// In es, this message translates to:
  /// **'No reservar'**
  String get bookingPriceChangedDecline;

  /// Botón del diálogo de precio cambiado: reservar con el precio nuevo.
  ///
  /// In es, this message translates to:
  /// **'Reservar'**
  String get bookingPriceChangedAccept;

  /// Error: en una recogida en aeropuerto falta el tipo de vuelo.
  ///
  /// In es, this message translates to:
  /// **'Indica si tu vuelo es nacional o internacional.'**
  String get bookingFlightTypeRequired;

  /// Aviso: se perdió la recogida (recarga de página); hay que volver a indicarla.
  ///
  /// In es, this message translates to:
  /// **'Vuelve a indicar tu recogida para reservar.'**
  String get bookingPickupMissing;

  /// Error: la hora de recogida elegida ya pasó.
  ///
  /// In es, this message translates to:
  /// **'La hora de recogida ya pasó. Elige una nueva hora.'**
  String get bookingPickupPast;

  /// Error: no se pudo obtener el precio del servidor.
  ///
  /// In es, this message translates to:
  /// **'No pudimos calcular el precio. Inténtalo de nuevo.'**
  String get bookingQuoteFailed;

  /// Aviso con el precio del viaje recién calculado; nombra el botón «Continuar al pago».
  ///
  /// In es, this message translates to:
  /// **'El precio de tu viaje es {price}. Pulsa Continuar al pago para seguir.'**
  String bookingQuoteReady(String price);

  /// Nombre del destino de una reserva por horas sin destino fijo.
  ///
  /// In es, this message translates to:
  /// **'Servicio por horas'**
  String get bookingHourlyDestination;

  /// Título de la elección de clase de vehículo.
  ///
  /// In es, this message translates to:
  /// **'Elige tu experiencia'**
  String get bookingChooseExperience;

  /// Título del bloque del precio (web).
  ///
  /// In es, this message translates to:
  /// **'Desglose de precio'**
  String get bookingPriceBreakdown;

  /// Etiqueta del total con el precio del servidor.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get bookingTotal;

  /// Etiqueta del total cuando el precio aún es una estimación.
  ///
  /// In es, this message translates to:
  /// **'Total estimado'**
  String get bookingTotalEstimated;

  /// Encabezado de las notas bajo el precio (web).
  ///
  /// In es, this message translates to:
  /// **'Nota importante:'**
  String get bookingImportantNote;

  /// Nota: límites de capacidad del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Los límites de capacidad de pasajeros y equipaje deben respetarse por razones de seguridad. Si se exceden, el chófer podrá rechazar el servicio.'**
  String get bookingNoteCapacity;

  /// Nota: las fotos del vehículo son de referencia.
  ///
  /// In es, this message translates to:
  /// **'Las imágenes del vehículo son solo de referencia. El vehículo real puede variar manteniendo una calidad equivalente o superior.'**
  String get bookingNoteImages;

  /// Nota: necesidades adicionales y grupos grandes. Business Van no se traduce.
  ///
  /// In es, this message translates to:
  /// **'Las necesidades adicionales (silla de ruedas, asiento infantil, artículos extra) pueden añadirse en \"Notas de recogida\". Elige Business Van para grupos más grandes o equipaje adicional.'**
  String get bookingNoteExtras;

  /// Opción: la reserva es para quien la hace.
  ///
  /// In es, this message translates to:
  /// **'Reservar para mí'**
  String get bookingForMe;

  /// Detalle de «Reservar para mí».
  ///
  /// In es, this message translates to:
  /// **'Reserva con la información de tu cuenta'**
  String get bookingForMeDetail;

  /// Opción: la reserva es para otra persona (invitado).
  ///
  /// In es, this message translates to:
  /// **'Reservar para un invitado'**
  String get bookingForGuest;

  /// Detalle de «Reservar para un invitado» sin invitado elegido.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar o añadir un invitado'**
  String get bookingForGuestDetail;

  /// Bajo el precio: es el del servidor.
  ///
  /// In es, this message translates to:
  /// **'Precio final'**
  String get bookingPriceFinal;

  /// Bajo el precio: aún es una estimación.
  ///
  /// In es, this message translates to:
  /// **'Precio estimado'**
  String get bookingPriceEstimated;

  /// Etiqueta del punto de recogida en el resumen.
  ///
  /// In es, this message translates to:
  /// **'Recogida'**
  String get bookingPickup;

  /// Etiqueta de la duración (servicio por horas).
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get bookingDuration;

  /// Duración de un servicio por horas en el resumen.
  ///
  /// In es, this message translates to:
  /// **'{hours} horas a tu disposición'**
  String bookingHoursAtDisposal(int hours);

  /// Etiqueta del destino en el resumen.
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get bookingDestination;

  /// Botón o tooltip para volver atrás.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get bookingBack;

  /// Título del asistente móvil: paso actual de 3, en mayúsculas.
  ///
  /// In es, this message translates to:
  /// **'PASO {step} DE 3'**
  String bookingStepOf(int step);

  /// Paso del asistente y fila del resumen: el vehículo.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get bookingVehicle;

  /// Paso del asistente: detalles del viaje.
  ///
  /// In es, this message translates to:
  /// **'Detalles'**
  String get bookingStepDetails;

  /// Paso del asistente y botón: confirmar.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get bookingConfirm;

  /// Botón para pasar al siguiente paso.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get bookingContinue;

  /// Botón final: crea la reserva y pasa al pago.
  ///
  /// In es, this message translates to:
  /// **'Continuar al pago'**
  String get bookingContinueToPayment;

  /// Encabezado en mayúsculas del paso de detalles.
  ///
  /// In es, this message translates to:
  /// **'DETALLES DEL VIAJE'**
  String get bookingTripDetails;

  /// Etiqueta: número de pasajeros.
  ///
  /// In es, this message translates to:
  /// **'Pasajeros'**
  String get bookingPassengers;

  /// Etiqueta: equipaje.
  ///
  /// In es, this message translates to:
  /// **'Equipaje'**
  String get bookingLuggage;

  /// Campo de notas para el chófer.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes especiales'**
  String get bookingSpecialRequests;

  /// Ejemplo dentro del campo de solicitudes especiales.
  ///
  /// In es, this message translates to:
  /// **'Asiento infantil, letrero de bienvenida…'**
  String get bookingSpecialRequestsHint;

  /// Campo del número de vuelo, obligatorio (recogida en aeropuerto).
  ///
  /// In es, this message translates to:
  /// **'Número de vuelo *'**
  String get bookingFlightNumberRequired;

  /// Campo del número de vuelo, opcional.
  ///
  /// In es, this message translates to:
  /// **'Número de vuelo'**
  String get bookingFlightNumber;

  /// Ejemplo de número de vuelo (obligatorio).
  ///
  /// In es, this message translates to:
  /// **'ej. OB 760'**
  String get bookingFlightNumberHint;

  /// Ejemplo de número de vuelo (opcional).
  ///
  /// In es, this message translates to:
  /// **'ej. OB 760 (opcional)'**
  String get bookingFlightNumberHintOptional;

  /// Encabezado en mayúsculas del resumen de la reserva.
  ///
  /// In es, this message translates to:
  /// **'RESUMEN DE RESERVA'**
  String get bookingSummaryTitle;

  /// Fila del resumen: tipo de servicio.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get bookingSummaryService;

  /// Fila del resumen: origen.
  ///
  /// In es, this message translates to:
  /// **'Desde'**
  String get bookingSummaryFrom;

  /// Fila del resumen: destino.
  ///
  /// In es, this message translates to:
  /// **'Hasta'**
  String get bookingSummaryTo;

  /// Fila del resumen: distancia.
  ///
  /// In es, this message translates to:
  /// **'Distancia'**
  String get bookingSummaryDistance;

  /// Número de horas de un servicio por horas.
  ///
  /// In es, this message translates to:
  /// **'{hours} horas'**
  String bookingHours(int hours);

  /// Fila del resumen: duración estimada del trayecto.
  ///
  /// In es, this message translates to:
  /// **'Duración est.'**
  String get bookingSummaryEstDuration;

  /// Fila del resumen: número de bultos de equipaje.
  ///
  /// In es, this message translates to:
  /// **'{count} bultos'**
  String bookingLuggageItems(int count);

  /// Fila del resumen: vuelo.
  ///
  /// In es, this message translates to:
  /// **'Vuelo'**
  String get bookingSummaryFlight;

  /// Fila del resumen: notas para el chófer.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get bookingSummaryNotes;

  /// Total en mayúsculas con el precio del servidor.
  ///
  /// In es, this message translates to:
  /// **'TOTAL · PRECIO FIJO'**
  String get bookingTotalFixedPrice;

  /// Total en mayúsculas cuando el precio es una estimación.
  ///
  /// In es, this message translates to:
  /// **'TOTAL ESTIMADO'**
  String get bookingTotalEstimatedUpper;

  /// Nota antes del botón: el pago va en el paso siguiente. Sin plazos.
  ///
  /// In es, this message translates to:
  /// **'Pagas en el paso siguiente. Buscamos chófer cuando el pago está confirmado.'**
  String get bookingPayNextNote;

  /// Nota de recogida en aeropuerto.
  ///
  /// In es, this message translates to:
  /// **'Recogida en aeropuerto: indica tu número de vuelo para que tu chófer lo tenga.'**
  String get bookingFlightNote;

  /// Selector obligatorio: vuelo nacional o internacional.
  ///
  /// In es, this message translates to:
  /// **'Tipo de vuelo *'**
  String get bookingFlightType;

  /// Botón por defecto de la barra de precio.
  ///
  /// In es, this message translates to:
  /// **'Confirmar reserva'**
  String get bookingConfirmBooking;

  /// Barra de precio en mayúsculas: estimación.
  ///
  /// In es, this message translates to:
  /// **'PRECIO ESTIMADO'**
  String get bookingPriceEstimatedUpper;

  /// Barra de precio en mayúsculas: precio del servidor.
  ///
  /// In es, this message translates to:
  /// **'PRECIO FINAL'**
  String get bookingPriceFinalUpper;

  /// Botón para volver a pedir el precio.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get bookingRetry;

  /// Título del diálogo de acceso al reservar: crear cuenta.
  ///
  /// In es, this message translates to:
  /// **'Crear una cuenta'**
  String get bookingAuthRegisterTitle;

  /// Título del diálogo de acceso al reservar: iniciar sesión.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para continuar'**
  String get bookingAuthLoginTitle;

  /// Texto del diálogo de acceso: crear cuenta. Luxelane no se traduce.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta de Luxelane para completar la reserva.'**
  String get bookingAuthRegisterBody;

  /// Texto del diálogo de acceso: iniciar sesión.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para confirmar tu reserva.'**
  String get bookingAuthLoginBody;

  /// Campo: nombre completo.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get bookingAuthFullName;

  /// Ejemplo del campo de nombre.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get bookingAuthFullNameHint;

  /// Campo: correo electrónico.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get bookingAuthEmail;

  /// Ejemplo del campo de correo.
  ///
  /// In es, this message translates to:
  /// **'tu@ejemplo.com'**
  String get bookingAuthEmailHint;

  /// Campo: contraseña.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get bookingAuthPassword;

  /// Botón: crear cuenta.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get bookingAuthRegister;

  /// Botón: iniciar sesión.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get bookingAuthLogin;

  /// Enlace para pasar a iniciar sesión.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get bookingAuthHaveAccount;

  /// Enlace para pasar a crear cuenta.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Crear una'**
  String get bookingAuthNoAccount;

  /// Tratamiento del invitado (se guarda «Sr.»).
  ///
  /// In es, this message translates to:
  /// **'Sr.'**
  String get bookingGuestTitleMr;

  /// Tratamiento del invitado (se guarda «Sra.»).
  ///
  /// In es, this message translates to:
  /// **'Sra.'**
  String get bookingGuestTitleMrs;

  /// Tratamiento del invitado (se guarda «Srta.»).
  ///
  /// In es, this message translates to:
  /// **'Srta.'**
  String get bookingGuestTitleMiss;

  /// Tratamiento del invitado (se guarda «Dr.»).
  ///
  /// In es, this message translates to:
  /// **'Dr.'**
  String get bookingGuestTitleDr;

  /// Tratamiento del invitado (se guarda «Prof.»).
  ///
  /// In es, this message translates to:
  /// **'Prof.'**
  String get bookingGuestTitleProf;

  /// Título del diálogo para añadir un invitado.
  ///
  /// In es, this message translates to:
  /// **'Añadir nuevo invitado'**
  String get bookingGuestAddTitle;

  /// Texto del diálogo del invitado: para qué se usan sus datos.
  ///
  /// In es, this message translates to:
  /// **'Ingresa los datos de la persona que viajará. Compartiremos estos datos con el chófer asignado para coordinar la recogida.'**
  String get bookingGuestIntro;

  /// Campo: tratamiento del invitado (Sr., Sra.…).
  ///
  /// In es, this message translates to:
  /// **'Tratamiento'**
  String get bookingGuestSalutation;

  /// Campo: nombre del invitado.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get bookingGuestFirstName;

  /// Ejemplo del campo de nombre del invitado.
  ///
  /// In es, this message translates to:
  /// **'Nombre del invitado'**
  String get bookingGuestFirstNameHint;

  /// Campo: apellido del invitado.
  ///
  /// In es, this message translates to:
  /// **'Apellido'**
  String get bookingGuestLastName;

  /// Ejemplo del campo de apellido del invitado.
  ///
  /// In es, this message translates to:
  /// **'Apellido del invitado'**
  String get bookingGuestLastNameHint;

  /// Campo: móvil del invitado.
  ///
  /// In es, this message translates to:
  /// **'Número de móvil del invitado'**
  String get bookingGuestPhone;

  /// Nota bajo el móvil del invitado.
  ///
  /// In es, this message translates to:
  /// **'El chófer asignado usará este número para coordinar la recogida.'**
  String get bookingGuestPhoneNote;

  /// Campo: idioma del invitado.
  ///
  /// In es, this message translates to:
  /// **'Idioma del invitado (opcional)'**
  String get bookingGuestLanguage;

  /// Ejemplo del campo de idioma del invitado.
  ///
  /// In es, this message translates to:
  /// **'Ej.: español, inglés'**
  String get bookingGuestLanguageHint;

  /// Capacidad de pasajeros de la clase.
  ///
  /// In es, this message translates to:
  /// **'{count} pasajeros'**
  String bookingVehiclePassengers(int count);

  /// Capacidad de maletas de la clase.
  ///
  /// In es, this message translates to:
  /// **'{count} maletas'**
  String bookingVehicleBags(int count);

  /// Encabezado en mayúsculas de los detalles de la clase.
  ///
  /// In es, this message translates to:
  /// **'DETALLES'**
  String get bookingVehicleDetailsEyebrow;

  /// Nota bajo las fotos del maletero.
  ///
  /// In es, this message translates to:
  /// **'Medidas estándar de referencia. Si llevas equipaje especial (palos de golf, cochecito, instrumentos), indícalo en las notas de recogida.'**
  String get bookingLuggageNote;

  /// Nota bajo las fotos de los asientos.
  ///
  /// In es, this message translates to:
  /// **'El asiento infantil se solicita con antelación y está sujeto a disponibilidad. Indica la edad del niño en las notas de recogida.'**
  String get bookingChildSeatNote;

  /// Encabezado en mayúsculas de la capacidad.
  ///
  /// In es, this message translates to:
  /// **'CAPACIDAD'**
  String get bookingCapacityEyebrow;

  /// Título de la sección de capacidad.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto cabe?'**
  String get bookingCapacityTitle;

  /// Capacidad de la clase: pasajeros y maletas facturadas.
  ///
  /// In es, this message translates to:
  /// **'Hasta {passengers} pasajeros y {bags} maletas facturadas'**
  String bookingCapacityDetail(int passengers, int bags);

  /// Pestaña: asientos.
  ///
  /// In es, this message translates to:
  /// **'Asientos'**
  String get bookingSeating;

  /// Tooltip de la flecha del carrusel.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get bookingNext;

  /// Error al guardar la valoración del viaje.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar tu valoración. Inténtalo de nuevo.'**
  String get bookingRatingSaveError;

  /// Error al aceptar (chófer): otro chófer ya lo aceptó.
  ///
  /// In es, this message translates to:
  /// **'Otro chófer ya aceptó este viaje.'**
  String get bookingAcceptTaken;

  /// Error al aceptar (chófer): documentos sin verificar. Luxelane no se traduce.
  ///
  /// In es, this message translates to:
  /// **'Tus documentos aún no están verificados por Luxelane.'**
  String get bookingAcceptNotVerified;

  /// Error al aceptar (chófer): no está disponible.
  ///
  /// In es, this message translates to:
  /// **'Conéctate y termina tu viaje actual antes de aceptar otro.'**
  String get bookingAcceptBusy;

  /// Error al aceptar (chófer): el viaje ya no está disponible.
  ///
  /// In es, this message translates to:
  /// **'Este viaje ya no está disponible.'**
  String get bookingAcceptUnavailable;

  /// Error al aceptar (chófer): sin conexión.
  ///
  /// In es, this message translates to:
  /// **'No se pudo aceptar el viaje. Revisa tu conexión.'**
  String get bookingAcceptConnection;

  /// Error al aceptar (chófer): otro fallo.
  ///
  /// In es, this message translates to:
  /// **'No se pudo aceptar el viaje. Inténtalo de nuevo.'**
  String get bookingAcceptFailed;

  /// Error de conexión al cotizar o reservar.
  ///
  /// In es, this message translates to:
  /// **'No pudimos conectar. Revisa tu conexión e inténtalo de nuevo.'**
  String get bookingConnectionError;

  /// Error del servidor: no hay tarifa para el viaje.
  ///
  /// In es, this message translates to:
  /// **'No pudimos calcular el precio de este viaje ahora. Inténtalo de nuevo en unos minutos.'**
  String get bookingErrorPricingUnavailable;

  /// Error del servidor: destino fuera de la ciudad de la recogida.
  ///
  /// In es, this message translates to:
  /// **'Por ahora solo hacemos viajes dentro de la misma ciudad de la recogida.'**
  String get bookingErrorOutOfArea;

  /// Error del servidor: clase no disponible.
  ///
  /// In es, this message translates to:
  /// **'Esta clase de vehículo no está disponible en este momento. Elige otra.'**
  String get bookingErrorClassUnavailable;

  /// Error del servidor: reservas en pausa por mantenimiento.
  ///
  /// In es, this message translates to:
  /// **'Las reservas están en pausa por mantenimiento. Vuelve a intentarlo en unos minutos.'**
  String get bookingErrorServiceUnavailable;

  /// Error del servidor: horas no enteras.
  ///
  /// In es, this message translates to:
  /// **'Elige un número entero de horas.'**
  String get bookingErrorInvalidHours;

  /// Error del servidor: cuenta sin permiso para reservar.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta no puede hacer reservas en este momento.'**
  String get bookingErrorInactiveUser;

  /// Error del servidor: sin sesión.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para reservar.'**
  String get bookingErrorSignIn;

  /// Error del servidor: ningún método de pago activo.
  ///
  /// In es, this message translates to:
  /// **'Ahora mismo no podemos recibir reservas. Inténtalo de nuevo más tarde o contacta con central.'**
  String get bookingErrorPaymentsUnavailable;

  /// Error del servidor: datos del viaje mal formados.
  ///
  /// In es, this message translates to:
  /// **'No pudimos procesar tu reserva. Revisa los datos del viaje e inténtalo de nuevo.'**
  String get bookingErrorInvalidRequest;

  /// Error del servidor: fallo interno, sin culpar a la persona.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar la reserva por un problema nuestro. Inténtalo de nuevo en unos minutos.'**
  String get bookingErrorServer;

  /// Error al cancelar: sin conexión.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cancelar. Revisa tu conexión e inténtalo de nuevo.'**
  String get bookingCancelConnectionError;

  /// Error al cancelar: fallo del servidor.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cancelar ahora. Inténtalo de nuevo en unos minutos; si sigue, contacta con central.'**
  String get bookingCancelServerError;

  /// Error al cancelar: el viaje está en curso o terminó.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva ya no se puede cancelar: el viaje está en curso o terminó.'**
  String get bookingCancelNotCancellable;

  /// Error al cancelar: la reserva no es de la cuenta o no existe.
  ///
  /// In es, this message translates to:
  /// **'No encontramos esta reserva en tu cuenta.'**
  String get bookingNotFound;

  /// Error al guardar el color o la foto del vehículo (chófer).
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar el cambio. Inténtalo de nuevo.'**
  String get bookingVehicleSaveError;

  /// Error al cargar la lista de viajes del pasajero.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tus viajes. Reintenta.'**
  String get bookingTripsLoadError;

  /// Antetítulo de la página Luxelane para Empresas.
  ///
  /// In es, this message translates to:
  /// **'Para Empresas'**
  String get businessEyebrow;

  /// Título de la página para empresas.
  ///
  /// In es, this message translates to:
  /// **'Viajes corporativos, redefinidos.'**
  String get businessTitle;

  /// Entradilla de la página para empresas, sobre el formulario de contacto.
  ///
  /// In es, this message translates to:
  /// **'Chóferes privados para tu equipo y tus invitados, con facturación centralizada. Cuéntanos qué necesitas y te contactamos en menos de un día hábil.'**
  String get businessLead;

  /// Aviso si la solicitud de empresa no se pudo enviar.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enviar tu solicitud. Inténtalo de nuevo.'**
  String get businessSendError;

  /// Error de un campo obligatorio vacío en el formulario de empresas.
  ///
  /// In es, this message translates to:
  /// **'Campo obligatorio'**
  String get businessRequired;

  /// Confirmación tras enviar la solicitud: nombre de pila y correo de quien la envió.
  ///
  /// In es, this message translates to:
  /// **'Gracias, {name}. Recibimos tu solicitud y te escribiremos a {email}.'**
  String businessThanks(String name, String email);

  /// Ventaja del servicio para empresas (lista con marcas).
  ///
  /// In es, this message translates to:
  /// **'Facturación mensual centralizada para tu empresa'**
  String get businessPerkBilling;

  /// Ventaja del servicio para empresas (lista con marcas).
  ///
  /// In es, this message translates to:
  /// **'Reservas prioritarias para ejecutivos e invitados'**
  String get businessPerkPriority;

  /// Etiqueta del campo nombre de la empresa.
  ///
  /// In es, this message translates to:
  /// **'Empresa'**
  String get businessCompany;

  /// Etiqueta del campo nombre de la persona de contacto.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get businessName;

  /// Etiqueta del campo correo de trabajo.
  ///
  /// In es, this message translates to:
  /// **'Correo de trabajo'**
  String get businessEmail;

  /// Error si el correo no tiene un formato válido.
  ///
  /// In es, this message translates to:
  /// **'Escribe un correo válido'**
  String get businessEmailInvalid;

  /// Etiqueta del campo teléfono.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get businessPhone;

  /// Etiqueta del desplegable con cuántas personas viajarían.
  ///
  /// In es, this message translates to:
  /// **'¿Cuántas personas viajarían?'**
  String get businessTravellers;

  /// Opción del desplegable de personas: más de 200 (el valor guardado sigue en español).
  ///
  /// In es, this message translates to:
  /// **'Más de 200'**
  String get businessTravellersOver200;

  /// Etiqueta del campo libre del formulario.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos qué necesitas (opcional)'**
  String get businessMessage;

  /// Botón para enviar la solicitud de empresa.
  ///
  /// In es, this message translates to:
  /// **'Enviar solicitud'**
  String get businessSubmit;

  /// Nota bajo los datos del vehículo del chófer que no puede editar él mismo.
  ///
  /// In es, this message translates to:
  /// **'Para cambiar estos datos, contacta con central.'**
  String get commonLockedDocuments;

  /// Título de la pantalla que sustituye a la app cuando no se pudo iniciar.
  ///
  /// In es, this message translates to:
  /// **'No pudimos iniciar la app'**
  String get commonStartupErrorTitle;

  /// Texto bajo «No pudimos iniciar la app».
  ///
  /// In es, this message translates to:
  /// **'Cierra la app y vuelve a abrirla en unos minutos.'**
  String get commonStartupErrorBody;

  /// Opción de asientos de un vehículo: número de pasajeros (siempre 2 o más).
  ///
  /// In es, this message translates to:
  /// **'{count} pasajeros'**
  String commonSeatingPassengers(int count);

  /// Detalle de la opción con todos los asientos ocupados.
  ///
  /// In es, this message translates to:
  /// **'Capacidad máxima'**
  String get commonSeatingMaxDetail;

  /// Detalle de la opción con un pasajero menos que el máximo.
  ///
  /// In es, this message translates to:
  /// **'Más espacio para cada uno'**
  String get commonSeatingRoomierDetail;

  /// Opción de asientos con silla para niños.
  ///
  /// In es, this message translates to:
  /// **'Con asiento infantil'**
  String get commonSeatingChildSeat;

  /// Detalle de la opción con asiento infantil: hay que pedirlo antes.
  ///
  /// In es, this message translates to:
  /// **'Bajo solicitud previa'**
  String get commonSeatingChildSeatDetail;

  /// Detalle de Business Class en la galería del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Sedán ejecutivo, discreto y silencioso'**
  String get commonHighlightBusiness1;

  /// Detalle de Business Class en la galería del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Asientos traseros en cuero para tres'**
  String get commonHighlightBusiness2;

  /// Detalle de Business Class en la galería del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Maletero para tres maletas facturadas'**
  String get commonHighlightBusiness3;

  /// Detalle de Business SUV en la galería del vehículo.
  ///
  /// In es, this message translates to:
  /// **'SUV ejecutiva, posición de manejo elevada'**
  String get commonHighlightSuv1;

  /// Detalle de Business SUV en la galería del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Cabina amplia para cuatro pasajeros'**
  String get commonHighlightSuv2;

  /// Detalle de Business SUV en la galería del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Maletero para cuatro maletas facturadas'**
  String get commonHighlightSuv3;

  /// Detalle de Business Van en la galería del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Van ejecutiva para grupos y familias'**
  String get commonHighlightVan1;

  /// Detalle de Business Van en la galería del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Hasta siete pasajeros en tres filas'**
  String get commonHighlightVan2;

  /// Detalle de Business Van en la galería del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Espacio para dos maletas facturadas'**
  String get commonHighlightVan3;

  /// Detalle de First Class en la galería del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Sedán insignia, nuestro máximo nivel'**
  String get commonHighlightFirst1;

  /// Detalle de First Class en la galería del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Plazas traseras con apoyabrazos central'**
  String get commonHighlightFirst2;

  /// Detalle de First Class y Eléctrico en la galería del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Maletero para dos maletas facturadas'**
  String get commonHighlightTwoCheckedBags;

  /// Detalle de la clase Eléctrico en la galería del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Sedán ejecutivo totalmente eléctrico'**
  String get commonHighlightElectric1;

  /// Detalle de la clase Eléctrico en la galería del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Silencioso y sin emisiones'**
  String get commonHighlightElectric2;

  /// Tipo de equipaje en singular, tras la cifra («1 maleta de mano»).
  ///
  /// In es, this message translates to:
  /// **'maleta de mano'**
  String get commonLuggageCabinOne;

  /// Tipo de equipaje en singular, tras la cifra («1 maleta facturada»).
  ///
  /// In es, this message translates to:
  /// **'maleta facturada'**
  String get commonLuggageCheckedOne;

  /// Tipo de equipaje en singular, tras la cifra («1 maleta extra grande»).
  ///
  /// In es, this message translates to:
  /// **'maleta extra grande'**
  String get commonLuggageOversizeOne;

  /// Tipo de equipaje en plural, tras la cifra («2 maletas de mano»).
  ///
  /// In es, this message translates to:
  /// **'maletas de mano'**
  String get commonLuggageCabinMany;

  /// Tipo de equipaje en plural, tras la cifra («2 maletas facturadas»).
  ///
  /// In es, this message translates to:
  /// **'maletas facturadas'**
  String get commonLuggageCheckedMany;

  /// Tipo de equipaje en plural, tras la cifra («2 maletas extra grandes»).
  ///
  /// In es, this message translates to:
  /// **'maletas extra grandes'**
  String get commonLuggageOversizeMany;

  /// Medidas de una maleta de mano.
  ///
  /// In es, this message translates to:
  /// **'Hasta 55 × 40 × 20 cm'**
  String get commonLuggageCabinSize;

  /// Medidas de una maleta facturada.
  ///
  /// In es, this message translates to:
  /// **'Hasta 75 × 50 × 30 cm'**
  String get commonLuggageCheckedSize;

  /// Medidas de una maleta extra grande.
  ///
  /// In es, this message translates to:
  /// **'Más de 80 cm'**
  String get commonLuggageOversizeSize;

  /// Promesa del servicio (frase corta): el precio queda fijo al reservar.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo al reservar'**
  String get commonPromiseFixedPrice;

  /// Promesa del servicio (detalle): quién calcula el precio fijo. No es una garantía.
  ///
  /// In es, this message translates to:
  /// **'El precio que ves al confirmar lo calcula Luxelane para tu trayecto.'**
  String get commonPromiseFixedPriceLong;

  /// Promesa del servicio (frase corta): los chóferes tienen los documentos verificados.
  ///
  /// In es, this message translates to:
  /// **'Chóferes con documentos verificados'**
  String get commonPromiseChauffeurs;

  /// Promesa del servicio (detalle): Luxelane revisa los documentos de cada chófer.
  ///
  /// In es, this message translates to:
  /// **'Luxelane revisa los documentos de cada chófer antes de que reciba viajes.'**
  String get commonPromiseChauffeursLong;

  /// Nombre de la clase de vehículo eléctrica (las demás clases son nombres de producto y no se traducen).
  ///
  /// In es, this message translates to:
  /// **'Eléctrico'**
  String get commonVehicleElectric;

  /// Descripción corta de Business Class (sin marca ni modelo).
  ///
  /// In es, this message translates to:
  /// **'Sedán ejecutivo'**
  String get commonVehicleBusinessDescription;

  /// Descripción corta de Business SUV.
  ///
  /// In es, this message translates to:
  /// **'SUV ejecutiva, más espacio'**
  String get commonVehicleSuvDescription;

  /// Descripción corta de First Class.
  ///
  /// In es, this message translates to:
  /// **'Sedán insignia'**
  String get commonVehicleFirstDescription;

  /// Descripción corta de Business Van.
  ///
  /// In es, this message translates to:
  /// **'Van ejecutiva para grupos'**
  String get commonVehicleVanDescription;

  /// Descripción corta de la clase Eléctrico.
  ///
  /// In es, this message translates to:
  /// **'Sedán ejecutivo eléctrico'**
  String get commonVehicleElectricDescription;

  /// Tipo de servicio: traslado de un punto a otro.
  ///
  /// In es, this message translates to:
  /// **'Solo ida'**
  String get commonServiceOneWay;

  /// Tipo de servicio: chófer por horas.
  ///
  /// In es, this message translates to:
  /// **'Por horas'**
  String get commonServiceByTheHour;

  /// Descripción del servicio «Solo ida».
  ///
  /// In es, this message translates to:
  /// **'Traslado a precio fijo a tu destino'**
  String get commonServiceOneWayDescription;

  /// Descripción del servicio «Por horas».
  ///
  /// In es, this message translates to:
  /// **'Chófer a tu disposición por un tiempo determinado'**
  String get commonServiceByTheHourDescription;

  /// Estado de una reserva: aún sin chófer o sin pagar.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get commonStatusPending;

  /// Estado de una reserva: confirmada.
  ///
  /// In es, this message translates to:
  /// **'Confirmado'**
  String get commonStatusConfirmed;

  /// Estado de una reserva: el chófer va hacia la recogida.
  ///
  /// In es, this message translates to:
  /// **'En camino'**
  String get commonStatusDriverArriving;

  /// Estado de una reserva: el chófer llegó a la recogida.
  ///
  /// In es, this message translates to:
  /// **'Chófer llegó'**
  String get commonStatusDriverArrived;

  /// Estado de una reserva: el chófer comprobó el código de recogida.
  ///
  /// In es, this message translates to:
  /// **'Verificada'**
  String get commonStatusVerified;

  /// Estado de una reserva: el viaje está en curso.
  ///
  /// In es, this message translates to:
  /// **'En progreso'**
  String get commonStatusInProgress;

  /// Estado de una reserva: viaje terminado.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get commonStatusCompleted;

  /// Estado de una reserva: cancelada.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get commonStatusCancelled;

  /// Estado de una reserva: el pasajero no se presentó.
  ///
  /// In es, this message translates to:
  /// **'No se presentó'**
  String get commonStatusNoShow;

  /// Motivo del pasajero para cancelar una reserva.
  ///
  /// In es, this message translates to:
  /// **'Cambié de planes'**
  String get commonCancelReasonChangedPlans;

  /// Motivo del pasajero para cancelar una reserva.
  ///
  /// In es, this message translates to:
  /// **'Encontré otro transporte'**
  String get commonCancelReasonOtherTransport;

  /// Motivo del pasajero para cancelar una reserva.
  ///
  /// In es, this message translates to:
  /// **'El chófer tarda demasiado'**
  String get commonCancelReasonDriverLate;

  /// Motivo genérico (cancelar del pasajero o liberar del chófer).
  ///
  /// In es, this message translates to:
  /// **'Otro motivo'**
  String get commonReasonOther;

  /// Motivo del chófer para liberar una reserva.
  ///
  /// In es, this message translates to:
  /// **'Problema con el vehículo'**
  String get commonReleaseReasonVehicle;

  /// Motivo del chófer para liberar una reserva.
  ///
  /// In es, this message translates to:
  /// **'Emergencia personal'**
  String get commonReleaseReasonEmergency;

  /// Motivo del chófer para liberar una reserva.
  ///
  /// In es, this message translates to:
  /// **'Condiciones inseguras'**
  String get commonReleaseReasonUnsafe;

  /// Motivo del chófer para liberar una reserva.
  ///
  /// In es, this message translates to:
  /// **'Conflicto de horario'**
  String get commonReleaseReasonSchedule;

  /// Panel: por qué no hubo retención al cancelar.
  ///
  /// In es, this message translates to:
  /// **'Sin política de cancelación'**
  String get commonFeeBasisNoPolicy;

  /// Panel: por qué no hubo retención al cancelar.
  ///
  /// In es, this message translates to:
  /// **'Política inválida (sin recargo)'**
  String get commonFeeBasisPolicyInvalid;

  /// Panel: la reserva se canceló porque falló el pago.
  ///
  /// In es, this message translates to:
  /// **'Falló el pago'**
  String get commonFeeBasisPaymentFailed;

  /// Panel: por qué no hubo retención al cancelar.
  ///
  /// In es, this message translates to:
  /// **'Sin chófer asignado'**
  String get commonFeeBasisNoDriver;

  /// Panel: se canceló dentro del plazo gratuito tras reservar.
  ///
  /// In es, this message translates to:
  /// **'Dentro del plazo tras reservar'**
  String get commonFeeBasisGrace;

  /// Panel: se canceló con antelación suficiente.
  ///
  /// In es, this message translates to:
  /// **'Con antelación suficiente'**
  String get commonFeeBasisEarly;

  /// Panel: se canceló tarde y hubo retención.
  ///
  /// In es, this message translates to:
  /// **'Tarde (aplica recargo)'**
  String get commonFeeBasisLate;

  /// Panel: central decidió que el pasajero no se presentó.
  ///
  /// In es, this message translates to:
  /// **'No se presentó (decisión de central)'**
  String get commonFeeBasisNoShowAdmin;

  /// Nombre por defecto de la zona aproximada de recogida de una solicitud.
  ///
  /// In es, this message translates to:
  /// **'Zona de recogida'**
  String get commonPickupArea;

  /// Nombre por defecto de la zona aproximada de destino de una solicitud.
  ///
  /// In es, this message translates to:
  /// **'Zona de destino'**
  String get commonDropoffArea;

  /// Panel: error al validar una tarifa.
  ///
  /// In es, this message translates to:
  /// **'Los importes no pueden ser negativos'**
  String get commonTariffNegative;

  /// Panel: error al validar una tarifa de solo ida sin precio.
  ///
  /// In es, this message translates to:
  /// **'Un traslado no puede costar Bs0'**
  String get commonTariffZeroTransfer;

  /// Panel: error al validar una tarifa por horas sin precio por hora.
  ///
  /// In es, this message translates to:
  /// **'El servicio por horas necesita un precio por hora'**
  String get commonTariffHourlyPrice;

  /// App del chófer (Android): título de la notificación fija mientras comparte la ubicación.
  ///
  /// In es, this message translates to:
  /// **'Luxelane · estás conectado'**
  String get commonLocationNotificationTitle;

  /// App del chófer (Android): texto de la notificación fija mientras comparte la ubicación.
  ///
  /// In es, this message translates to:
  /// **'Compartimos tu ubicación para asignarte viajes y guiar al pasajero.'**
  String get commonLocationNotificationText;

  /// App del chófer (Android): nombre del canal de la notificación de ubicación en los ajustes del teléfono.
  ///
  /// In es, this message translates to:
  /// **'Ubicación del chófer'**
  String get commonLocationChannelName;

  /// Por qué aún no se puede reservar: las tarifas se están cargando.
  ///
  /// In es, this message translates to:
  /// **'Cargando las tarifas vigentes… inténtalo en unos segundos.'**
  String get commonPricingLoading;

  /// Por qué no se puede reservar: las reservas están en pausa.
  ///
  /// In es, this message translates to:
  /// **'Las reservas están en pausa por mantenimiento. Vuelve a intentarlo en unos minutos.'**
  String get commonPricingMaintenance;

  /// Por qué no se puede reservar: la clase no está disponible para ese tipo de servicio.
  ///
  /// In es, this message translates to:
  /// **'{vehicleClass} no está disponible para \"{serviceType}\" en este momento.'**
  String commonPricingUnavailable(String vehicleClass, String serviceType);

  /// Frase bajo el saludo del inicio: el viaje está en curso.
  ///
  /// In es, this message translates to:
  /// **'Disfruta el trayecto.'**
  String get commonPromptEnjoyJourney;

  /// Frase bajo el saludo del inicio: el chófer llegó a la recogida.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer ya te espera.'**
  String get commonPromptChauffeurWaiting;

  /// Frase bajo el saludo del inicio: el chófer va hacia la recogida.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer va en camino.'**
  String get commonPromptChauffeurOnTheWay;

  /// Frase bajo el saludo del inicio: el próximo viaje es en menos de dos horas.
  ///
  /// In es, this message translates to:
  /// **'Tu próximo trayecto está cerca.'**
  String get commonPromptNextTripSoon;

  /// Frase bajo el saludo del inicio, de 5 a 11 h.
  ///
  /// In es, this message translates to:
  /// **'¿A dónde empieza tu día?'**
  String get commonPromptMorning;

  /// Frase bajo el saludo del inicio, de 11 a 15 h.
  ///
  /// In es, this message translates to:
  /// **'¿A dónde te llevamos?'**
  String get commonPromptMidday;

  /// Frase bajo el saludo del inicio, de 15 a 20 h.
  ///
  /// In es, this message translates to:
  /// **'¿Cerramos el día en calma?'**
  String get commonPromptAfternoon;

  /// Frase bajo el saludo del inicio, de 20 a 1 h.
  ///
  /// In es, this message translates to:
  /// **'¿Volvemos con calma?'**
  String get commonPromptEvening;

  /// Frase bajo el saludo del inicio, de 1 a 5 h. Sin prometer atención a toda hora.
  ///
  /// In es, this message translates to:
  /// **'Estamos aquí a cualquier hora.'**
  String get commonPromptLateNight;

  /// Tipo de vuelo: llega desde dentro de Bolivia.
  ///
  /// In es, this message translates to:
  /// **'Nacional'**
  String get commonFlightDomestic;

  /// Tipo de vuelo: llega desde el extranjero.
  ///
  /// In es, this message translates to:
  /// **'Internacional'**
  String get commonFlightInternational;

  /// Error: la dirección de recogida no tiene coordenadas.
  ///
  /// In es, this message translates to:
  /// **'No pudimos ubicar la recogida en el mapa. Elige otra dirección.'**
  String get commonOriginNoCoords;

  /// Error: la recogida está fuera de las ciudades donde se opera (lista de ciudades separadas por comas).
  ///
  /// In es, this message translates to:
  /// **'Por ahora operamos en {cities}. Elige una recogida en una de esas ciudades.'**
  String commonOriginOutsideArea(String cities);

  /// Error: el destino está en otra ciudad que la recogida.
  ///
  /// In es, this message translates to:
  /// **'El destino debe estar en {city}, la misma ciudad de la recogida.'**
  String commonDestinationOtherCity(String city);

  /// Error: el destino está lejos de una recogida que no está en una ciudad conocida.
  ///
  /// In es, this message translates to:
  /// **'El destino debe estar en la misma ciudad que la recogida.'**
  String get commonDestinationSameCity;

  /// Error: falta el número de vuelo en una recogida en el aeropuerto.
  ///
  /// In es, this message translates to:
  /// **'Indica tu número de vuelo: con él calculamos la hora de recogida.'**
  String get commonFlightNumberMissing;

  /// Error: el número de vuelo no tiene un formato válido (los ejemplos no se traducen).
  ///
  /// In es, this message translates to:
  /// **'Número de vuelo no válido. Ejemplo: OB 760 o Z8 315.'**
  String get commonFlightNumberInvalid;

  /// Título de la app en la pestaña del navegador y el selector de apps (en español, el mismo de index.html y del manifest).
  ///
  /// In es, this message translates to:
  /// **'Luxelane — Servicio de chófer ejecutivo'**
  String get commonAppTitle;

  /// Pestaña de la app del pasajero: reservar un viaje.
  ///
  /// In es, this message translates to:
  /// **'Reservar'**
  String get commonTabBook;

  /// Pestaña de la app del pasajero: lista de viajes.
  ///
  /// In es, this message translates to:
  /// **'Mis viajes'**
  String get commonTabMyTrips;

  /// Pestaña de la app del pasajero: perfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get commonTabProfile;

  /// Enlace de la cabecera web para iniciar sesión.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get commonSignIn;

  /// Etiqueta de lector de pantalla del botón del avatar en la cabecera web.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get commonMyProfile;

  /// Página de una ruta que no existe: título.
  ///
  /// In es, this message translates to:
  /// **'Este camino no existe.'**
  String get commonNotFoundTitle;

  /// Página de una ruta que no existe: texto bajo el título.
  ///
  /// In es, this message translates to:
  /// **'Te llevamos de vuelta al inicio.'**
  String get commonNotFoundBody;

  /// Botón (en mayúsculas) de la página de una ruta que no existe.
  ///
  /// In es, this message translates to:
  /// **'VOLVER AL INICIO'**
  String get commonNotFoundBack;

  /// Título del aviso de versión antigua en la app del chófer.
  ///
  /// In es, this message translates to:
  /// **'Actualiza la app para seguir'**
  String get commonUpdateTitleDriver;

  /// Título del aviso de versión antigua en la app del pasajero.
  ///
  /// In es, this message translates to:
  /// **'Actualiza la app para reservar'**
  String get commonUpdateTitleRider;

  /// Texto del aviso de versión antigua en la web.
  ///
  /// In es, this message translates to:
  /// **'Hay una versión nueva de la web. Recarga la página para seguir reservando.'**
  String get commonUpdateBodyWeb;

  /// Texto del aviso de versión antigua en el móvil.
  ///
  /// In es, this message translates to:
  /// **'Hay una versión nueva de la app. Actualízala para seguir reservando.'**
  String get commonUpdateBodyApp;

  /// Botón del aviso de versión antigua: abre la tienda de apps.
  ///
  /// In es, this message translates to:
  /// **'Ir a la tienda'**
  String get commonUpdateGoToStore;

  /// Botón para cerrar un aviso.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get commonGotIt;

  /// Título del aviso al reservar sin el correo verificado.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu correo para reservar'**
  String get commonEmailNotVerifiedTitle;

  /// Texto del aviso al reservar sin el correo verificado.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, solo se puede reservar con el correo verificado. Abre el enlace que te enviamos o pide uno nuevo.'**
  String get commonEmailNotVerifiedBody;

  /// Botón para posponer una acción.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get commonNotNow;

  /// Botón que lleva a la pantalla de verificar el correo.
  ///
  /// In es, this message translates to:
  /// **'Verificar mi correo'**
  String get commonVerifyMyEmail;

  /// Pantalla de error inesperado: título.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal'**
  String get commonErrorTitle;

  /// Pantalla de error inesperado: texto bajo el título.
  ///
  /// In es, this message translates to:
  /// **'Hemos sido notificados y estamos trabajando en una solución.'**
  String get commonErrorBody;

  /// Botón para reintentar.
  ///
  /// In es, this message translates to:
  /// **'Intentar de nuevo'**
  String get commonTryAgain;

  /// Franja que aparece sin conexión: los datos pueden estar desactualizados.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Lo que ves puede no estar al día.'**
  String get commonOfflineBanner;

  /// Etiqueta de lector de pantalla mientras algo carga.
  ///
  /// In es, this message translates to:
  /// **'Cargando'**
  String get commonLoading;

  /// «Listo»: etiqueta de lector de pantalla de la animación de éxito y botón para cerrar el selector de hora.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get commonDone;

  /// Etiqueta de lector de pantalla de la barra de progreso del viaje.
  ///
  /// In es, this message translates to:
  /// **'Etapa {step} de {total}'**
  String commonStepOf(int step, int total);

  /// Indicación de lector de pantalla del botón deslizable de confirmar.
  ///
  /// In es, this message translates to:
  /// **'Desliza para confirmar'**
  String get commonSlideToConfirm;

  /// Capacidad de un vehículo en su tarjeta, junto al icono de persona («Hasta 3»).
  ///
  /// In es, this message translates to:
  /// **'Hasta {count}'**
  String commonUpTo(int count);

  /// Bajo el precio de un servicio por horas: horas contratadas en total («2h en total»).
  ///
  /// In es, this message translates to:
  /// **'{hours}h en total'**
  String commonHoursTotal(int hours);

  /// Bajo el precio de un traslado (en minúscula).
  ///
  /// In es, this message translates to:
  /// **'precio fijo'**
  String get commonFixedPriceLower;

  /// Encabezado (en mayúsculas) de las preferencias del pasajero que ve el chófer.
  ///
  /// In es, this message translates to:
  /// **'ESTILO DEL PASAJERO'**
  String get commonRiderStyle;

  /// Botón por defecto de la barra de precio: confirmar la reserva.
  ///
  /// In es, this message translates to:
  /// **'Confirmar reserva'**
  String get commonConfirmBooking;

  /// Encabezado (en mayúsculas) del importe en la barra de precio.
  ///
  /// In es, this message translates to:
  /// **'PRECIO FIJO'**
  String get commonFixedPriceUpper;

  /// Título en lugar del mapa cuando no se puede mostrar.
  ///
  /// In es, this message translates to:
  /// **'Mapa no disponible'**
  String get commonMapUnavailable;

  /// Texto bajo «Mapa no disponible».
  ///
  /// In es, this message translates to:
  /// **'El mapa no se puede mostrar ahora. Los datos del viaje siguen aquí.'**
  String get commonMapUnavailableDetail;

  /// Nombre de un punto elegido en el mapa cuando no se pudo obtener su dirección.
  ///
  /// In es, this message translates to:
  /// **'Punto elegido en el mapa'**
  String get commonPointOnMap;

  /// Título por defecto del mapa para elegir un lugar.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar ubicación'**
  String get commonSelectLocation;

  /// Texto inicial del mapa para elegir un lugar, antes de tener una dirección.
  ///
  /// In es, this message translates to:
  /// **'Mueve el mapa para elegir el lugar'**
  String get commonMoveMapToChoose;

  /// Encabezado (en mayúsculas) de la dirección elegida en el mapa.
  ///
  /// In es, this message translates to:
  /// **'UBICACIÓN SELECCIONADA'**
  String get commonSelectedLocation;

  /// Botón (en mayúsculas) para confirmar el lugar elegido en el mapa.
  ///
  /// In es, this message translates to:
  /// **'CONFIRMAR'**
  String get commonConfirmUpper;

  /// Aviso al elegir una dirección sugerida que no tiene coordenadas.
  ///
  /// In es, this message translates to:
  /// **'No pudimos ubicar esa dirección. Prueba con otra o elígela en el mapa.'**
  String get commonAddressNotFound;

  /// Título del mapa al elegir la recogida.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar lugar de recogida'**
  String get commonSelectPickupPlace;

  /// Título del mapa al elegir el destino.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar destino'**
  String get commonSelectDestination;

  /// Aviso al cambiar la recogida: se quitó un destino que estaba en otra ciudad.
  ///
  /// In es, this message translates to:
  /// **'El destino estaba en otra ciudad. Elige uno en la ciudad de recogida.'**
  String get commonDestinationWasOtherCity;

  /// Encabezado (en mayúsculas) del calendario para elegir el día de la recogida.
  ///
  /// In es, this message translates to:
  /// **'FECHA DE RECOGIDA'**
  String get commonPickupDateUpper;

  /// Encabezado (en mayúsculas) del reloj para elegir la hora de la recogida.
  ///
  /// In es, this message translates to:
  /// **'HORA DE RECOGIDA'**
  String get commonPickupTimeUpper;

  /// Botón para cancelar o cerrar sin cambios.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// Botón para pasar al paso siguiente.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get commonNext;

  /// Error al buscar vehículos sin indicar la recogida.
  ///
  /// In es, this message translates to:
  /// **'Indica dónde te recogemos.'**
  String get commonPickupMissing;

  /// Aviso: la hora elegida ya no daba tiempo y se movió (fecha y hora nuevas, ya formateadas).
  ///
  /// In es, this message translates to:
  /// **'Esa hora ya no da tiempo: la movimos a {when}. Revísala y continúa.'**
  String commonPickupMovedLater(String when);

  /// Error al buscar vehículos de un traslado sin destino.
  ///
  /// In es, this message translates to:
  /// **'Indica tu destino para calcular el precio fijo.'**
  String get commonDestinationMissing;

  /// Ayuda del campo de recogida en la página de traslados al aeropuerto.
  ///
  /// In es, this message translates to:
  /// **'Recogida — aeropuerto, hotel o dirección'**
  String get commonPickupHintAirport;

  /// Ayuda del campo de recogida.
  ///
  /// In es, this message translates to:
  /// **'Recogida — dirección, hotel o lugar'**
  String get commonPickupHint;

  /// Ayuda del campo de destino en la página de traslados al aeropuerto.
  ///
  /// In es, this message translates to:
  /// **'Destino — aeropuerto, hotel o dirección'**
  String get commonDestinationHintAirport;

  /// Ayuda del campo de destino en el servicio por horas.
  ///
  /// In es, this message translates to:
  /// **'Destino (opcional)'**
  String get commonDestinationOptional;

  /// Ayuda del campo de destino.
  ///
  /// In es, this message translates to:
  /// **'Destino — dirección, hotel o lugar'**
  String get commonDestinationHint;

  /// Encabezado (en mayúsculas) de la tarjeta de reserva de las páginas de servicios.
  ///
  /// In es, this message translates to:
  /// **'RESERVA TU CHÓFER'**
  String get commonBookYourChauffeur;

  /// Etiqueta del campo de recogida.
  ///
  /// In es, this message translates to:
  /// **'Recogida'**
  String get commonPickup;

  /// Etiqueta del campo de destino.
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get commonDestination;

  /// Opción: recogida lo antes posible (sin hora programada). No promete un plazo.
  ///
  /// In es, this message translates to:
  /// **'Ahora'**
  String get commonNow;

  /// Opción: programar la recogida para una fecha y hora.
  ///
  /// In es, this message translates to:
  /// **'Programar'**
  String get commonSchedule;

  /// Acción (se muestra en mayúsculas) para cambiar la fecha y hora elegidas.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get commonChange;

  /// Botón (en mayúsculas) de la tarjeta de reserva.
  ///
  /// In es, this message translates to:
  /// **'VER VEHÍCULOS Y PRECIOS'**
  String get commonSeeVehiclesAndPrices;

  /// Nota bajo el botón de la tarjeta de reserva.
  ///
  /// In es, this message translates to:
  /// **'Sin compromiso: verás el precio final antes de confirmar.'**
  String get commonNoCommitment;

  /// Enlace bajo un campo de dirección para elegir el lugar en el mapa.
  ///
  /// In es, this message translates to:
  /// **'Elegir en el mapa'**
  String get commonChooseOnMap;

  /// Etiqueta del selector de horas del servicio por horas.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get commonDuration;

  /// Consejo del botón «−» del selector de horas.
  ///
  /// In es, this message translates to:
  /// **'Menos horas'**
  String get commonFewerHours;

  /// Consejo del botón «+» del selector de horas.
  ///
  /// In es, this message translates to:
  /// **'Más horas'**
  String get commonMoreHours;

  /// Servicio de la web (menú y pie de página).
  ///
  /// In es, this message translates to:
  /// **'Traslado al aeropuerto'**
  String get commonServiceAirportTransfer;

  /// Servicio de la web (menú y pie de página).
  ///
  /// In es, this message translates to:
  /// **'Chófer por horas'**
  String get commonServiceHourly;

  /// Servicio de la web (menú y pie de página): recogida sin programar. Sin prometer un plazo.
  ///
  /// In es, this message translates to:
  /// **'Recogida inmediata'**
  String get commonServiceImmediate;

  /// Etiqueta de lector de pantalla del logotipo de la cabecera web (lleva al inicio).
  ///
  /// In es, this message translates to:
  /// **'Luxelane, inicio'**
  String get commonHomeLinkLabel;

  /// Enlace de la web a la sección de la flota.
  ///
  /// In es, this message translates to:
  /// **'Flota'**
  String get commonFleet;

  /// Enlace de la web a la página para empresas.
  ///
  /// In es, this message translates to:
  /// **'Para empresas'**
  String get commonForBusiness;

  /// Menú (en mayúsculas) de servicios de la cabecera web.
  ///
  /// In es, this message translates to:
  /// **'SERVICIOS'**
  String get commonServicesUpper;

  /// Botón corto (en mayúsculas) de la cabecera web en pantallas estrechas.
  ///
  /// In es, this message translates to:
  /// **'RESERVAR'**
  String get commonBookUpper;

  /// Botón (en mayúsculas) de la cabecera web y del menú móvil.
  ///
  /// In es, this message translates to:
  /// **'RESERVAR UN VIAJE'**
  String get commonBookATripUpper;

  /// Consejo del botón que abre el menú en la web móvil.
  ///
  /// In es, this message translates to:
  /// **'Menú'**
  String get commonMenu;

  /// Etiqueta de lector de pantalla para cerrar el menú tocando fuera.
  ///
  /// In es, this message translates to:
  /// **'Cerrar menú'**
  String get commonCloseMenu;

  /// Consejo de un botón para cerrar.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// Título de la lista de servicios (menú móvil y pie de página).
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get commonServices;

  /// Frase de la marca en el pie de página de la web.
  ///
  /// In es, this message translates to:
  /// **'Servicio de chófer privado para quienes valoran su tiempo, su privacidad y cada detalle del camino.'**
  String get commonFooterTagline;

  /// Enlace del pie de página para chóferes que quieren unirse.
  ///
  /// In es, this message translates to:
  /// **'Conduce con nosotros'**
  String get commonDriveWithUs;

  /// Enlace del pie de página a los términos (la página legal sigue en español).
  ///
  /// In es, this message translates to:
  /// **'Términos y condiciones'**
  String get commonTerms;

  /// Enlace del pie de página a la política de privacidad (la página legal sigue en español).
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get commonPrivacy;

  /// Título de la columna de promesas del pie de página.
  ///
  /// In es, this message translates to:
  /// **'Nuestra promesa'**
  String get commonOurPromise;

  /// Línea final del pie de página con el año.
  ///
  /// In es, this message translates to:
  /// **'© {year} Luxelane. Todos los derechos reservados.'**
  String commonCopyright(String year);

  /// Fecha relativa: hoy (antes de la hora, «Hoy · 18:30»).
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get formatToday;

  /// Fecha relativa: mañana («Mañana · 09:15»).
  ///
  /// In es, this message translates to:
  /// **'Mañana'**
  String get formatTomorrow;

  /// Saludo de la mañana en el inicio (de 5 a 12 h).
  ///
  /// In es, this message translates to:
  /// **'Buenos días'**
  String get greetingMorning;

  /// Saludo de la tarde en el inicio (de 12 a 19 h).
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes'**
  String get greetingAfternoon;

  /// Saludo de la noche en el inicio (de 19 a 5 h).
  ///
  /// In es, this message translates to:
  /// **'Buenas noches'**
  String get greetingEvening;

  /// Error al abrir la app del chófer: la cuenta aún no tiene el rol de chófer.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta aún no está habilitada como chófer. Luxelane la activa después de revisar tu solicitud.'**
  String get driverErrorNotEnabled;

  /// Error al cargar la cuenta del chófer al abrir la app.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu cuenta. Revisa tu conexión e inténtalo de nuevo.'**
  String get driverErrorLoadAccount;

  /// Aviso: no se pudieron leer los viajes asignados al chófer.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar tus viajes.'**
  String get driverNoticeTripsLoadFailed;

  /// Aviso: no se pudieron leer las solicitudes abiertas.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las solicitudes de viaje.'**
  String get driverNoticeRequestsLoadFailed;

  /// Aviso al intentar conectarse con un viaje en curso.
  ///
  /// In es, this message translates to:
  /// **'Termina tu viaje actual antes de conectarte.'**
  String get driverNoticeFinishTripFirst;

  /// Aviso: no se guardó el cambio entre en línea y desconectado.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cambiar tu estado. Reintenta.'**
  String get driverNoticeStatusChangeFailed;

  /// Aviso: el chófer no dio permiso de ubicación.
  ///
  /// In es, this message translates to:
  /// **'Activa la ubicación para recibir viajes y que el pasajero vea dónde estás.'**
  String get driverNoticeLocationRequired;

  /// Aviso al marcar «el pasajero no aparece» sin ubicación.
  ///
  /// In es, this message translates to:
  /// **'Activa la ubicación: central necesita saber dónde esperaste.'**
  String get driverNoticeNoShowLocationRequired;

  /// Aviso tras avisar a central de que el pasajero no apareció.
  ///
  /// In es, this message translates to:
  /// **'Avisamos a central. Ya estás libre para otros viajes.'**
  String get driverNoticeNoShowReported;

  /// Aviso: sin conexión al liberar un viaje.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: no se liberó el viaje. Vuelve a intentarlo.'**
  String get driverNoticeReleaseOffline;

  /// Aviso tras liberar (devolver) un viaje aceptado.
  ///
  /// In es, this message translates to:
  /// **'Liberaste el viaje. Central buscará otro chófer.'**
  String get driverNoticeReleased;

  /// Aviso: sin conexión al guardar un paso del viaje (salir, llegar, iniciar, completar).
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: no se guardó el paso. Vuelve a intentarlo; no se duplicará.'**
  String get driverNoticeStepOffline;

  /// Aviso breve tras aceptar una solicitud.
  ///
  /// In es, this message translates to:
  /// **'Viaje aceptado'**
  String get driverNoticeRequestAccepted;

  /// Pantalla de error del inicio del chófer.
  ///
  /// In es, this message translates to:
  /// **'No pudimos abrir tu panel.'**
  String get driverHomeLoadError;

  /// Botón para reintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get driverRetry;

  /// Título grande del inicio cuando el chófer está en línea.
  ///
  /// In es, this message translates to:
  /// **'Estás en línea.'**
  String get driverHomeOnlineTitle;

  /// Título grande del inicio cuando el chófer está desconectado.
  ///
  /// In es, this message translates to:
  /// **'Estás desconectado.'**
  String get driverHomeOfflineTitle;

  /// Aviso del inicio: documentos sin verificar.
  ///
  /// In es, this message translates to:
  /// **'Tus documentos están en revisión. Podrás aceptar viajes cuando Luxelane los verifique.'**
  String get driverHomeDocumentsPending;

  /// Aviso del inicio: sin vehículo activo.
  ///
  /// In es, this message translates to:
  /// **'No tienes un vehículo activo registrado. Pide a Luxelane que lo active para recibir solicitudes.'**
  String get driverHomeNoVehicle;

  /// Encabezado de la sección con las cifras de hoy.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get driverHomeToday;

  /// Etiqueta de la cifra: ganancias netas de hoy.
  ///
  /// In es, this message translates to:
  /// **'Ganancias netas'**
  String get driverHomeNetEarnings;

  /// Etiqueta de la cifra: viajes completados hoy.
  ///
  /// In es, this message translates to:
  /// **'Viajes'**
  String get driverHomeTrips;

  /// Etiqueta de la cifra: valoración media del chófer.
  ///
  /// In es, this message translates to:
  /// **'Valoración'**
  String get driverHomeRating;

  /// Encabezado de la lista de próximas reservas asignadas.
  ///
  /// In es, this message translates to:
  /// **'Tus próximas reservas'**
  String get driverHomeUpcoming;

  /// Título de un servicio por horas: horas y punto de recogida.
  ///
  /// In es, this message translates to:
  /// **'{hours} h desde {place}'**
  String driverHourlyFrom(int hours, String place);

  /// Etiqueta de lector de pantalla del gran botón: desconectarse.
  ///
  /// In es, this message translates to:
  /// **'Desconectarse'**
  String get driverGoOffline;

  /// Gran botón del inicio y su etiqueta: conectarse para recibir viajes.
  ///
  /// In es, this message translates to:
  /// **'Conectarse'**
  String get driverGoOnline;

  /// Texto del gran botón cuando el chófer está en línea.
  ///
  /// In es, this message translates to:
  /// **'En línea'**
  String get driverOnlineBadge;

  /// Bajo el gran botón, en línea, sin clase de vehículo.
  ///
  /// In es, this message translates to:
  /// **'Buscando viajes'**
  String get driverSearching;

  /// Bajo el gran botón, en línea: la clase del vehículo (nombre propio).
  ///
  /// In es, this message translates to:
  /// **'Buscando viajes de {vehicleClass}'**
  String driverSearchingClass(String vehicleClass);

  /// Bajo el gran botón, desconectado.
  ///
  /// In es, this message translates to:
  /// **'Conéctate para recibir solicitudes'**
  String get driverConnectToReceive;

  /// Botón de texto para desconectarse.
  ///
  /// In es, this message translates to:
  /// **'Desconectarme'**
  String get driverDisconnectMe;

  /// Aviso: no hay apps de mapas instaladas.
  ///
  /// In es, this message translates to:
  /// **'No hay aplicaciones de mapas disponibles'**
  String get driverMapsNone;

  /// Título de la hoja para elegir app de mapas.
  ///
  /// In es, this message translates to:
  /// **'Navegar hacia {address}'**
  String driverMapsNavigateTo(String address);

  /// Aviso: no se pudieron abrir los mapas.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron abrir los mapas'**
  String get driverMapsOpenFailed;

  /// Etiqueta de la parada de recogida (se muestra en mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'Recogida'**
  String get driverStopPickup;

  /// Etiqueta de la parada de destino (se muestra en mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get driverStopDestination;

  /// Nombre del invitado que viaja (reserva para otra persona).
  ///
  /// In es, this message translates to:
  /// **'Pasajero: {name}'**
  String driverGuestPassenger(String name);

  /// Título de la nota que dejó el pasajero.
  ///
  /// In es, this message translates to:
  /// **'Nota del pasajero'**
  String get driverRiderNote;

  /// Botón para abrir la navegación hacia la recogida.
  ///
  /// In es, this message translates to:
  /// **'Navegar a la recogida'**
  String get driverNavigateToPickup;

  /// Botón para abrir la navegación hacia el destino.
  ///
  /// In es, this message translates to:
  /// **'Navegar al destino'**
  String get driverNavigateToDestination;

  /// Hora de una solicitud que empieza ya.
  ///
  /// In es, this message translates to:
  /// **'Ahora'**
  String get driverRequestNow;

  /// Hora de una solicitud que empieza en pocos minutos.
  ///
  /// In es, this message translates to:
  /// **'En {minutes} min'**
  String driverRequestInMinutes(int minutes);

  /// Distancia y duración aproximadas del trayecto.
  ///
  /// In es, this message translates to:
  /// **'~{km} km · {minutes} min'**
  String driverRouteDistanceDuration(String km, int minutes);

  /// Distancia aproximada del trayecto.
  ///
  /// In es, this message translates to:
  /// **'~{km} km'**
  String driverRouteDistance(String km);

  /// Cabecera de una solicitud nueva, en mayúsculas, con la clase (nombre propio en mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'NUEVA SOLICITUD · {vehicleClass}'**
  String driverRequestTitle(String vehicleClass);

  /// Etiqueta en mayúsculas: zona aproximada de recogida.
  ///
  /// In es, this message translates to:
  /// **'ZONA DE RECOGIDA'**
  String get driverRequestPickupZone;

  /// Etiqueta en mayúsculas: zona aproximada de destino.
  ///
  /// In es, this message translates to:
  /// **'ZONA DE DESTINO'**
  String get driverRequestDropoffZone;

  /// Etiqueta en mayúsculas: servicio por horas.
  ///
  /// In es, this message translates to:
  /// **'POR HORAS'**
  String get driverRequestHourly;

  /// Servicio por horas: horas a disposición del pasajero.
  ///
  /// In es, this message translates to:
  /// **'{hours} h a disposición'**
  String driverHoursAvailable(int hours);

  /// Número de pasajeros de una solicitud.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 pasajero} other{{count} pasajeros}}'**
  String driverRequestPassengers(int count);

  /// Número de maletas de una solicitud.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 maleta} other{{count} maletas}}'**
  String driverRequestLuggage(int count);

  /// Nota de la solicitud: la dirección exacta y los datos se ven al aceptar.
  ///
  /// In es, this message translates to:
  /// **'Dirección exacta y datos al aceptar'**
  String get driverRequestDetailsOnAccept;

  /// Botón para aceptar una solicitud.
  ///
  /// In es, this message translates to:
  /// **'Aceptar viaje'**
  String get driverAcceptTrip;

  /// Botón para rechazar una solicitud.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get driverDecline;

  /// Pantalla de un viaje que ya no está en la lista.
  ///
  /// In es, this message translates to:
  /// **'Viaje no encontrado'**
  String get driverTripNotFound;

  /// Botón o etiqueta para volver atrás.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get driverBack;

  /// Etiqueta de la tarifa estimada del viaje.
  ///
  /// In es, this message translates to:
  /// **'Tarifa estimada'**
  String get driverEstimatedFare;

  /// Título de la pantalla de solicitudes.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get driverQueueTitle;

  /// Lista vacía, en línea (dos líneas).
  ///
  /// In es, this message translates to:
  /// **'Las nuevas solicitudes\naparecerán aquí.'**
  String get driverQueueEmptyOnline;

  /// Lista vacía, desconectado (dos líneas).
  ///
  /// In es, this message translates to:
  /// **'Conéctate para\nrecibir solicitudes.'**
  String get driverQueueEmptyOffline;

  /// Encabezado: solicitudes abiertas para el chófer.
  ///
  /// In es, this message translates to:
  /// **'Disponibles para ti'**
  String get driverQueueAvailable;

  /// Encabezado: viajes ya asignados al chófer.
  ///
  /// In es, this message translates to:
  /// **'Tus viajes asignados'**
  String get driverQueueAssigned;

  /// Fecha y hora del viaje y el lugar de recogida.
  ///
  /// In es, this message translates to:
  /// **'{date} · desde {place}'**
  String driverQueueFrom(String date, String place);

  /// Número de pasajeros, abreviado.
  ///
  /// In es, this message translates to:
  /// **'{count} pax'**
  String driverQueuePax(int count);

  /// Botón mientras carga el estado del chófer.
  ///
  /// In es, this message translates to:
  /// **'Cargando…'**
  String get driverQueueLoading;

  /// Botón deshabilitado: documentos sin verificar.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de verificación'**
  String get driverQueuePendingVerification;

  /// Botón deshabilitado: hay un viaje en curso.
  ///
  /// In es, this message translates to:
  /// **'Termina tu viaje actual'**
  String get driverQueueFinishCurrent;

  /// Botón deshabilitado: el chófer está desconectado.
  ///
  /// In es, this message translates to:
  /// **'Conéctate para aceptar'**
  String get driverQueueConnectToAccept;

  /// Botón para cerrar sesión.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get driverSignOut;

  /// Botón para pasar al siguiente paso.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get driverContinue;

  /// Error de campo vacío.
  ///
  /// In es, this message translates to:
  /// **'Requerido'**
  String get driverFieldRequired;

  /// Error de valor no válido (año).
  ///
  /// In es, this message translates to:
  /// **'Inválido'**
  String get driverFieldInvalid;

  /// Título de la pantalla de ganancias.
  ///
  /// In es, this message translates to:
  /// **'Ganancias'**
  String get driverEarningsTitle;

  /// Encabezado de la lista de viajes completados.
  ///
  /// In es, this message translates to:
  /// **'Viajes completados'**
  String get driverEarningsCompleted;

  /// Etiqueta en mayúsculas del total de ganancias netas.
  ///
  /// In es, this message translates to:
  /// **'TUS GANANCIAS NETAS'**
  String get driverEarningsNetTitle;

  /// Número de viajes completados.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 viaje completado} other{{count} viajes completados}}'**
  String driverEarningsRides(int count);

  /// Línea del resumen: suma de las tarifas.
  ///
  /// In es, this message translates to:
  /// **'Tarifas de tus viajes'**
  String get driverEarningsFares;

  /// Línea del resumen: comisión de Luxelane.
  ///
  /// In es, this message translates to:
  /// **'Comisión Luxelane'**
  String get driverEarningsCommission;

  /// Nota: comisión por defecto mientras no hay liquidación.
  ///
  /// In es, this message translates to:
  /// **'Los viajes provisionales se calculan con una comisión del {pct} % hasta que se confirme su liquidación.'**
  String driverEarningsProvisionalNote(String pct);

  /// Fecha del viaje y que se reembolsó.
  ///
  /// In es, this message translates to:
  /// **'{date} · reembolsado'**
  String driverEarningsRefunded(String date);

  /// Fecha del viaje, tarifa y porcentaje de comisión.
  ///
  /// In es, this message translates to:
  /// **'{date} · tarifa {fare} · {pct} %'**
  String driverEarningsFareLine(String date, String fare, String pct);

  /// Marca de un viaje sin liquidación confirmada.
  ///
  /// In es, this message translates to:
  /// **'Provisional'**
  String get driverEarningsProvisional;

  /// Lista de ganancias vacía (dos líneas).
  ///
  /// In es, this message translates to:
  /// **'Tu primer viaje\naparecerá aquí.'**
  String get driverEarningsEmpty;

  /// Deslizador: salir hacia la recogida.
  ///
  /// In es, this message translates to:
  /// **'Salir hacia la recogida'**
  String get driverSlideDepart;

  /// Deslizador: el chófer llegó a la recogida.
  ///
  /// In es, this message translates to:
  /// **'He llegado'**
  String get driverSlideArrived;

  /// Deslizador: iniciar el viaje (se cita en driverCodeVerifiedHint).
  ///
  /// In es, this message translates to:
  /// **'Iniciar viaje'**
  String get driverSlideStart;

  /// Deslizador: completar el viaje.
  ///
  /// In es, this message translates to:
  /// **'Completar viaje'**
  String get driverSlideComplete;

  /// Estado del viaje: aceptado, aún sin salir.
  ///
  /// In es, this message translates to:
  /// **'Dirígete a la recogida.'**
  String get driverStepConfirmed;

  /// Estado del viaje: en camino a la recogida.
  ///
  /// In es, this message translates to:
  /// **'En camino a la recogida.'**
  String get driverStepArriving;

  /// Estado: verificación bloqueada tras cinco códigos incorrectos.
  ///
  /// In es, this message translates to:
  /// **'Verificación bloqueada. Contacta con central.'**
  String get driverStepLocked;

  /// Estado: el chófer llegó y pide el código.
  ///
  /// In es, this message translates to:
  /// **'Pide al pasajero su código de recogida.'**
  String get driverStepAskCode;

  /// Estado: pasajero verificado, listo para iniciar.
  ///
  /// In es, this message translates to:
  /// **'Pasajero verificado. Desliza para iniciar.'**
  String get driverStepVerified;

  /// Estado: viaje en curso.
  ///
  /// In es, this message translates to:
  /// **'Viaje en curso · rumbo al destino.'**
  String get driverStepInProgress;

  /// Estado: el chófer avisó que el pasajero no apareció.
  ///
  /// In es, this message translates to:
  /// **'Avisaste que el pasajero no apareció. Central lo revisa.'**
  String get driverStepNoShow;

  /// Estado genérico de un viaje activo.
  ///
  /// In es, this message translates to:
  /// **'Viaje activo.'**
  String get driverStepActive;

  /// Texto con la verificación bloqueada.
  ///
  /// In es, this message translates to:
  /// **'Cinco códigos incorrectos: central debe verificar este viaje.'**
  String get driverLockedFiveCodes;

  /// Botón para escribir el código de recogida.
  ///
  /// In es, this message translates to:
  /// **'Ingresar código del pasajero'**
  String get driverEnterCode;

  /// Botón para liberar un viaje aceptado.
  ///
  /// In es, this message translates to:
  /// **'No puedo hacer este viaje'**
  String get driverCannotDoTrip;

  /// Título del diálogo para liberar un viaje.
  ///
  /// In es, this message translates to:
  /// **'Liberar este viaje'**
  String get driverReleaseTitle;

  /// Texto del diálogo para liberar un viaje.
  ///
  /// In es, this message translates to:
  /// **'El viaje vuelve a buscar chófer y central recibe un aviso. Queda registrado en tu historial.'**
  String get driverReleaseBody;

  /// Botón que confirma liberar el viaje.
  ///
  /// In es, this message translates to:
  /// **'Liberar viaje'**
  String get driverReleaseConfirm;

  /// Motivo para liberar: problema con el vehículo.
  ///
  /// In es, this message translates to:
  /// **'Problema con el vehículo'**
  String get driverReleaseReasonVehicleIssue;

  /// Motivo para liberar: emergencia personal.
  ///
  /// In es, this message translates to:
  /// **'Emergencia personal'**
  String get driverReleaseReasonPersonalEmergency;

  /// Motivo para liberar: condiciones inseguras.
  ///
  /// In es, this message translates to:
  /// **'Condiciones inseguras'**
  String get driverReleaseReasonUnsafeConditions;

  /// Motivo para liberar: conflicto de horario.
  ///
  /// In es, this message translates to:
  /// **'Conflicto de horario'**
  String get driverReleaseReasonScheduleConflict;

  /// Motivo para liberar: otro.
  ///
  /// In es, this message translates to:
  /// **'Otro motivo'**
  String get driverReleaseReasonOther;

  /// Título del diálogo «el pasajero no aparece».
  ///
  /// In es, this message translates to:
  /// **'¿El pasajero no aparece?'**
  String get driverNoShowTitle;

  /// Texto del diálogo «el pasajero no aparece».
  ///
  /// In es, this message translates to:
  /// **'Central recibirá un aviso con tu ubicación y revisará la reserva. Quedarás libre para otros viajes.'**
  String get driverNoShowBody;

  /// Botón para seguir esperando al pasajero.
  ///
  /// In es, this message translates to:
  /// **'Seguir esperando'**
  String get driverNoShowKeepWaiting;

  /// Botón para avisar a central de que el pasajero no apareció.
  ///
  /// In es, this message translates to:
  /// **'Avisar a central'**
  String get driverNoShowNotify;

  /// Botón «el pasajero no aparece».
  ///
  /// In es, this message translates to:
  /// **'El pasajero no aparece'**
  String get driverNoShowButton;

  /// Desde qué hora se puede marcar que el pasajero no aparece.
  ///
  /// In es, this message translates to:
  /// **'Disponible a partir de las {time}.'**
  String driverNoShowAvailableAt(String time);

  /// Tarjeta del vuelo sin aeropuerto conocido.
  ///
  /// In es, this message translates to:
  /// **'Recogida en aeropuerto'**
  String get driverFlightAirportPickup;

  /// Enlace al sitio de estado de vuelos (dominio, no se traduce).
  ///
  /// In es, this message translates to:
  /// **'Ver estado en mivuelo.att.gob.bo'**
  String get driverFlightCheckStatus;

  /// Va dentro de driverFlightDialogBody cuando no se conoce el aeropuerto.
  ///
  /// In es, this message translates to:
  /// **'el aeropuerto de tu ciudad'**
  String get driverFlightYourCityAirport;

  /// Título del diálogo antes de abrir el sitio de vuelos.
  ///
  /// In es, this message translates to:
  /// **'Primero cambia de aeropuerto'**
  String get driverFlightDialogTitle;

  /// Instrucciones antes de abrir el sitio de vuelos; {airport} es el nombre del aeropuerto o driverFlightYourCityAirport.
  ///
  /// In es, this message translates to:
  /// **'Al abrir mivuelo.att.gob.bo, cambia primero el aeropuerto a {airport}, el que corresponde a tu ciudad. Después busca el vuelo {flight} en las llegadas.\n\nCopiaremos el número de vuelo para que solo tengas que pegarlo.'**
  String driverFlightDialogBody(String airport, String flight);

  /// Botón para cancelar un diálogo.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get driverCancel;

  /// Botón que abre el sitio de vuelos.
  ///
  /// In es, this message translates to:
  /// **'Entendido, abrir'**
  String get driverFlightDialogOpen;

  /// Aviso: no se pudo abrir el sitio de vuelos.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir mivuelo.att.gob.bo'**
  String get driverFlightOpenFailed;

  /// Botón para llamar a central.
  ///
  /// In es, this message translates to:
  /// **'Llamar a central'**
  String get driverCallDispatch;

  /// La reserva llegó con la verificación bloqueada.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, la verificación quedó bloqueada. Contacta con central.'**
  String get driverCodeLockedSecurity;

  /// Título de la pantalla del código de recogida.
  ///
  /// In es, this message translates to:
  /// **'Pide el código al pasajero'**
  String get driverCodeAsk;

  /// Texto bajo el título del código de recogida.
  ///
  /// In es, this message translates to:
  /// **'Lo ve en su app. Sin él no se puede iniciar el viaje.'**
  String get driverCodeHint;

  /// Etiqueta de lector de pantalla: dígitos escritos del código.
  ///
  /// In es, this message translates to:
  /// **'Código, {entered} de {length} dígitos'**
  String driverCodeSemantics(int entered, int length);

  /// Etiqueta de lector de pantalla de la tecla para borrar.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get driverCodeDelete;

  /// Título tras verificar el código.
  ///
  /// In es, this message translates to:
  /// **'Pasajero verificado'**
  String get driverCodeVerified;

  /// Tras verificar: cita el deslizador driverSlideStart.
  ///
  /// In es, this message translates to:
  /// **'Desliza «Iniciar viaje» cuando estéis listos.'**
  String get driverCodeVerifiedHint;

  /// Título con la verificación bloqueada.
  ///
  /// In es, this message translates to:
  /// **'Contacta con central'**
  String get driverCodeContactDispatch;

  /// Pestaña de la app del chófer: inicio para conducir.
  ///
  /// In es, this message translates to:
  /// **'Conducir'**
  String get driverNavDrive;

  /// Pestaña de la app del chófer: solicitudes.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get driverNavRequests;

  /// Pestaña de la app del chófer: ganancias.
  ///
  /// In es, this message translates to:
  /// **'Ganancias'**
  String get driverNavEarnings;

  /// Pestaña de la app del chófer: perfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get driverNavProfile;

  /// Registro de chófer (app del chófer): título de la pantalla previa a abrir la solicitud.
  ///
  /// In es, this message translates to:
  /// **'Conducir con Luxelane'**
  String get regIntroTitle;

  /// Registro de chófer (app del chófer): qué cambia al abrir la solicitud.
  ///
  /// In es, this message translates to:
  /// **'Para registrarte como chófer, esta cuenta pasa a ser una cuenta de chófer.'**
  String get regIntroBody;

  /// Registro de chófer (app del chófer): la cuenta no vuelve a ser de pasajero.
  ///
  /// In es, this message translates to:
  /// **'La cuenta deja de ser de pasajero y no se vuelve a usar para reservar viajes.'**
  String get regIntroPointOneWay;

  /// Registro de chófer (app del chófer): quien ya tiene reservas usa otro correo.
  ///
  /// In es, this message translates to:
  /// **'Si ya hiciste reservas como pasajero con este correo, crea otra cuenta con un correo distinto para registrarte como chófer.'**
  String get regIntroPointBookings;

  /// Registro de chófer (app del chófer): qué viene después.
  ///
  /// In es, this message translates to:
  /// **'Después completarás tus datos, los de tu vehículo y tus documentos. Luxelane los revisa antes de habilitarte.'**
  String get regIntroPointReview;

  /// Registro de chófer (app del chófer): botón para convertir la cuenta.
  ///
  /// In es, this message translates to:
  /// **'Convertir en cuenta de chófer'**
  String get regIntroStart;

  /// Registro de chófer (app del chófer): título de la confirmación.
  ///
  /// In es, this message translates to:
  /// **'¿Convertir esta cuenta?'**
  String get regIntroConfirmTitle;

  /// Registro de chófer (app del chófer): texto de la confirmación.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta ya no se podrá usar como pasajero. No se puede deshacer.'**
  String get regIntroConfirmBody;

  /// Registro de chófer (app del chófer): confirmar la conversión.
  ///
  /// In es, this message translates to:
  /// **'Sí, convertir'**
  String get regIntroConfirmYes;

  /// Registro de chófer (app del chófer): cancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get regCancel;

  /// Registro de chófer (app del chófer): cerrar sesión desde el registro.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get regSignOut;

  /// Registro de chófer (app del chófer): título de la pantalla de la solicitud.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud de chófer'**
  String get regTitle;

  /// Registro de chófer (app del chófer): encabezado del paso actual.
  ///
  /// In es, this message translates to:
  /// **'Paso {current} de {total}: {title}'**
  String regStepOf(int current, int total, String title);

  /// Registro de chófer (app del chófer): etiqueta de accesibilidad de la barra de progreso.
  ///
  /// In es, this message translates to:
  /// **'Progreso de la solicitud: paso {current} de {total}'**
  String regProgressLabel(int current, int total);

  /// Registro de chófer (app del chófer): título del paso de datos personales.
  ///
  /// In es, this message translates to:
  /// **'Tus datos'**
  String get regStepPersonal;

  /// Registro de chófer (app del chófer): título del paso del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Tu vehículo'**
  String get regStepVehicle;

  /// Registro de chófer (app del chófer): título del paso de documentos.
  ///
  /// In es, this message translates to:
  /// **'Documentos'**
  String get regStepDocuments;

  /// Registro de chófer (app del chófer): título del paso del segundo factor.
  ///
  /// In es, this message translates to:
  /// **'Verificación en dos pasos'**
  String get regStepSecurity;

  /// Registro de chófer (app del chófer): título del paso final.
  ///
  /// In es, this message translates to:
  /// **'Resumen y envío'**
  String get regStepSummary;

  /// Registro de chófer (app del chófer): volver al paso anterior.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get regBack;

  /// Registro de chófer (app del chófer): ir al paso siguiente.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get regContinue;

  /// Registro de chófer (app del chófer): guardar el paso y seguir.
  ///
  /// In es, this message translates to:
  /// **'Guardar y continuar'**
  String get regSaveContinue;

  /// Registro de chófer (app del chófer): reintentar la carga.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get regRetry;

  /// Registro de chófer (app del chófer): etiqueta mientras se guarda.
  ///
  /// In es, this message translates to:
  /// **'Guardando…'**
  String get regSaving;

  /// Registro de chófer (app del chófer): campo nombre completo.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get regFullName;

  /// Registro de chófer (app del chófer): campo número de documento de identidad.
  ///
  /// In es, this message translates to:
  /// **'Número de documento de identidad'**
  String get regNationalId;

  /// Registro de chófer (app del chófer): campo número de licencia.
  ///
  /// In es, this message translates to:
  /// **'Número de licencia de conducir'**
  String get regLicenseNumber;

  /// Registro de chófer (app del chófer): campo vencimiento de la licencia.
  ///
  /// In es, this message translates to:
  /// **'Vencimiento de la licencia'**
  String get regLicenseExpiry;

  /// Registro de chófer (app del chófer): botón para elegir una fecha.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha'**
  String get regPickDate;

  /// Registro de chófer (app del chófer): validación: campo vacío.
  ///
  /// In es, this message translates to:
  /// **'Completa este campo'**
  String get regFieldRequired;

  /// Registro de chófer (app del chófer): validación del nombre.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu nombre completo (2 a 120 caracteres)'**
  String get regFullNameInvalid;

  /// Registro de chófer (app del chófer): validación de un número de documento.
  ///
  /// In es, this message translates to:
  /// **'Usa solo letras, números y guiones (4 a 20)'**
  String get regIdInvalid;

  /// Registro de chófer (app del chófer): validación: la fecha debe ser futura.
  ///
  /// In es, this message translates to:
  /// **'Elige una fecha posterior a hoy'**
  String get regDateInFuture;

  /// Registro de chófer (app del chófer): quién ve los números de documento.
  ///
  /// In es, this message translates to:
  /// **'Tus números de documento solo los ve el equipo de Luxelane que revisa la solicitud.'**
  String get regPrivacyNote;

  /// Registro de chófer (app del chófer): campo marca.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get regMake;

  /// Registro de chófer (app del chófer): campo modelo.
  ///
  /// In es, this message translates to:
  /// **'Modelo'**
  String get regModel;

  /// Registro de chófer (app del chófer): campo año.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get regYear;

  /// Registro de chófer (app del chófer): validación del año.
  ///
  /// In es, this message translates to:
  /// **'Año entre {min} y {max}'**
  String regYearInvalid(int min, int max);

  /// Registro de chófer (app del chófer): validación de marca o modelo.
  ///
  /// In es, this message translates to:
  /// **'Entre 1 y 40 caracteres'**
  String get regTextInvalid;

  /// Registro de chófer (app del chófer): campo color.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get regColor;

  /// Registro de chófer (app del chófer): campo color libre.
  ///
  /// In es, this message translates to:
  /// **'Escribe el color'**
  String get regColorOtherText;

  /// Registro de chófer (app del chófer): validación del color libre.
  ///
  /// In es, this message translates to:
  /// **'Entre 1 y 20 caracteres'**
  String get regColorOtherInvalid;

  /// Registro de chófer (app del chófer): campo placa.
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get regPlate;

  /// Registro de chófer (app del chófer): validación de la placa.
  ///
  /// In es, this message translates to:
  /// **'Solo letras y números (4 a 10)'**
  String get regPlateInvalid;

  /// Registro de chófer (app del chófer): campo tipo de vehículo.
  ///
  /// In es, this message translates to:
  /// **'Tipo de vehículo'**
  String get regBodyType;

  /// Registro de chófer (app del chófer): campo pasajeros.
  ///
  /// In es, this message translates to:
  /// **'Pasajeros'**
  String get regPassengers;

  /// Registro de chófer (app del chófer): campo clase de servicio.
  ///
  /// In es, this message translates to:
  /// **'Clase de servicio'**
  String get regVehicleClass;

  /// Registro de chófer (app del chófer): qué pasa al cambiar de vehículo tras aprobar.
  ///
  /// In es, this message translates to:
  /// **'Si cambias de vehículo después de la aprobación, el nuevo queda en revisión hasta que Luxelane lo apruebe.'**
  String get regVehicleChangeNote;

  /// Registro de chófer (app del chófer): consejo general para las fotos.
  ///
  /// In es, this message translates to:
  /// **'Sube cada documento con una foto nítida, con buena luz y sin reflejos.'**
  String get regDocsIntro;

  /// Registro de chófer (app del chófer): aviso cuando no hay requisitos configurados.
  ///
  /// In es, this message translates to:
  /// **'Luxelane aún no definió qué documentos se piden. Puedes completar tus datos; el envío se habilita cuando estén definidos.'**
  String get regDocsNotConfigured;

  /// Registro de chófer (app del chófer): etiqueta de documento obligatorio.
  ///
  /// In es, this message translates to:
  /// **'Obligatorio'**
  String get regDocRequired;

  /// Registro de chófer (app del chófer): etiqueta de documento opcional.
  ///
  /// In es, this message translates to:
  /// **'Opcional'**
  String get regDocOptional;

  /// Registro de chófer (app del chófer): fecha de vencimiento de un documento.
  ///
  /// In es, this message translates to:
  /// **'Vence: {date}'**
  String regDocExpires(String date);

  /// Registro de chófer (app del chófer): motivo de rechazo de un documento.
  ///
  /// In es, this message translates to:
  /// **'Motivo: {reason}'**
  String regDocRejectedReason(String reason);

  /// Registro de chófer (app del chófer): subir un documento.
  ///
  /// In es, this message translates to:
  /// **'Subir'**
  String get regDocUpload;

  /// Registro de chófer (app del chófer): volver a subir un documento.
  ///
  /// In es, this message translates to:
  /// **'Volver a subir'**
  String get regDocReupload;

  /// Registro de chófer (app del chófer): etiqueta mientras se sube.
  ///
  /// In es, this message translates to:
  /// **'Subiendo…'**
  String get regDocUploading;

  /// Registro de chófer (app del chófer): en la web no se suben documentos ni fotos.
  ///
  /// In es, this message translates to:
  /// **'Los documentos y las fotos se suben desde la app de Luxelane en tu teléfono. Aquí puedes completar tus datos y los del vehículo.'**
  String get regWebUploadBlocked;

  /// Registro de chófer (app del chófer): fallo al subir la foto.
  ///
  /// In es, this message translates to:
  /// **'No se pudo subir la foto. Revisa tu conexión y vuelve a intentarlo.'**
  String get regUploadFailed;

  /// Registro de chófer (app del chófer): la foto tiene poca resolución.
  ///
  /// In es, this message translates to:
  /// **'La foto tiene poca resolución. Tómala más cerca y con buena luz.'**
  String get regPhotoTooSmall;

  /// Registro de chófer (app del chófer): no se pudo leer la foto.
  ///
  /// In es, this message translates to:
  /// **'No pudimos leer la foto. Vuelve a tomarla.'**
  String get regPhotoUnreadable;

  /// Registro de chófer (app del chófer): ayuda: documento de identidad o licencia.
  ///
  /// In es, this message translates to:
  /// **'Apoya el documento en una superficie lisa, con buena luz y sin reflejos. Que se vean las cuatro esquinas y que el texto se lea.'**
  String get regHelpIdDocument;

  /// Registro de chófer (app del chófer): ayuda: certificados y documentos en papel.
  ///
  /// In es, this message translates to:
  /// **'Fotografía la hoja completa, de frente y sin sombras.'**
  String get regHelpPaper;

  /// Registro de chófer (app del chófer): ayuda: foto de perfil.
  ///
  /// In es, this message translates to:
  /// **'Tu cara de frente, sin gafas de sol ni gorra, con fondo claro.'**
  String get regHelpProfile;

  /// Registro de chófer (app del chófer): ayuda: foto en vivo.
  ///
  /// In es, this message translates to:
  /// **'Se toma en el momento con la cámara frontal. Mira a la cámara con buena luz.'**
  String get regHelpLive;

  /// Registro de chófer (app del chófer): ayuda: fotos exteriores del vehículo.
  ///
  /// In es, this message translates to:
  /// **'El vehículo completo desde este lado, con buena luz.'**
  String get regHelpVehicle;

  /// Registro de chófer (app del chófer): ayuda: fotos del interior.
  ///
  /// In es, this message translates to:
  /// **'El interior completo desde este punto, con buena luz.'**
  String get regHelpInterior;

  /// Registro de chófer (app del chófer): ayuda: foto de la placa.
  ///
  /// In es, this message translates to:
  /// **'La placa de frente, completa y legible.'**
  String get regHelpPlate;

  /// Registro de chófer (app del chófer): aviso del marco de encuadre (la cámara del sistema se abre a pantalla completa).
  ///
  /// In es, this message translates to:
  /// **'La cámara se abre a pantalla completa: encuadra como en este marco.'**
  String get regFrameHint;

  /// Registro de chófer (app del chófer): etiqueta de accesibilidad del marco de encuadre.
  ///
  /// In es, this message translates to:
  /// **'Guía de encuadre'**
  String get regFrameLabel;

  /// Registro de chófer (app del chófer): abrir la cámara.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get regTakePhoto;

  /// Registro de chófer (app del chófer): elegir de la galería.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get regFromGallery;

  /// Registro de chófer (app del chófer): la foto en vivo solo admite cámara.
  ///
  /// In es, this message translates to:
  /// **'Esta foto solo se toma con la cámara, no desde la galería.'**
  String get regLiveCameraOnly;

  /// Registro de chófer (app del chófer): título de la revisión de la foto.
  ///
  /// In es, this message translates to:
  /// **'Revisa la foto'**
  String get regReviewTitle;

  /// Registro de chófer (app del chófer): qué comprobar antes de usar la foto.
  ///
  /// In es, this message translates to:
  /// **'Comprueba que se lea bien y que no esté cortada.'**
  String get regReviewHint;

  /// Registro de chófer (app del chófer): etiqueta de accesibilidad de la vista previa.
  ///
  /// In es, this message translates to:
  /// **'Vista previa de la foto'**
  String get regPhotoPreviewLabel;

  /// Registro de chófer (app del chófer): repetir la foto.
  ///
  /// In es, this message translates to:
  /// **'Repetir'**
  String get regRetake;

  /// Registro de chófer (app del chófer): usar la foto.
  ///
  /// In es, this message translates to:
  /// **'Usar esta foto'**
  String get regUsePhoto;

  /// Registro de chófer (app del chófer): fecha de vencimiento del documento.
  ///
  /// In es, this message translates to:
  /// **'Fecha de vencimiento del documento'**
  String get regExpiryNeeded;

  /// Registro de chófer (app del chófer): falta la fecha de vencimiento.
  ///
  /// In es, this message translates to:
  /// **'Indica la fecha de vencimiento'**
  String get regExpiryRequired;

  /// Registro de chófer (app del chófer): no se tomó ninguna foto.
  ///
  /// In es, this message translates to:
  /// **'No se tomó ninguna foto.'**
  String get regPhotoCancelled;

  /// Registro de chófer (app del chófer): no se pudo abrir la cámara o la galería.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la cámara. Revisa los permisos de la app.'**
  String get regCameraUnavailable;

  /// Registro de chófer (app del chófer): por qué se pide el segundo factor.
  ///
  /// In es, this message translates to:
  /// **'Para enviar la solicitud y, después, conectarte, tu cuenta necesita la verificación en dos pasos con una app autenticadora.'**
  String get regSecurityBody;

  /// Registro de chófer (app del chófer): abrir el alta del segundo factor.
  ///
  /// In es, this message translates to:
  /// **'Activar la verificación en dos pasos'**
  String get regSecurityEnroll;

  /// Registro de chófer (app del chófer): el segundo factor está listo.
  ///
  /// In es, this message translates to:
  /// **'La verificación en dos pasos está activa en esta sesión.'**
  String get regSecurityReady;

  /// Registro de chófer (app del chófer): activado pero la sesión no lo usó.
  ///
  /// In es, this message translates to:
  /// **'Ya la tienes activada. Cierra sesión y vuelve a entrar con el código de tu app autenticadora para continuar.'**
  String get regSecuritySignInAgain;

  /// Registro de chófer (app del chófer): volver a comprobar el segundo factor.
  ///
  /// In es, this message translates to:
  /// **'Comprobar de nuevo'**
  String get regSecurityCheck;

  /// Registro de chófer (app del chófer): falta el segundo factor para enviar.
  ///
  /// In es, this message translates to:
  /// **'Antes de enviar, activa la verificación en dos pasos.'**
  String get regSecurityNeededToSubmit;

  /// Registro de chófer (app del chófer): introducción del resumen.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu solicitud antes de enviarla.'**
  String get regSummaryIntro;

  /// Registro de chófer (app del chófer): sección datos personales del resumen.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get regSummaryPersonal;

  /// Registro de chófer (app del chófer): sección vehículo del resumen.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get regSummaryVehicle;

  /// Registro de chófer (app del chófer): progreso de documentos obligatorios.
  ///
  /// In es, this message translates to:
  /// **'Documentos obligatorios listos: {done} de {total}'**
  String regSummaryDocs(int done, int total);

  /// Registro de chófer (app del chófer): documentos que faltan.
  ///
  /// In es, this message translates to:
  /// **'Faltan: {list}'**
  String regSummaryMissing(String list);

  /// Registro de chófer (app del chófer): faltan pasos.
  ///
  /// In es, this message translates to:
  /// **'Completa tus datos y los del vehículo para poder enviar.'**
  String get regSummaryIncomplete;

  /// Registro de chófer (app del chófer): editar una sección.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get regEdit;

  /// Registro de chófer (app del chófer): enviar la solicitud.
  ///
  /// In es, this message translates to:
  /// **'Enviar solicitud'**
  String get regSubmit;

  /// Registro de chófer (app del chófer): aviso tras enviar.
  ///
  /// In es, this message translates to:
  /// **'Solicitud enviada.'**
  String get regSubmitted;

  /// Registro de chófer (app del chófer): solicitud enviada o en revisión.
  ///
  /// In es, this message translates to:
  /// **'Solicitud en revisión'**
  String get regStatusReviewTitle;

  /// Registro de chófer (app del chófer): qué pasa mientras se revisa (sin plazos).
  ///
  /// In es, this message translates to:
  /// **'Luxelane está revisando tu solicitud. Recibirás un aviso en la app cuando haya una respuesta.'**
  String get regStatusReviewBody;

  /// Registro de chófer (app del chófer): Luxelane pidió cambios.
  ///
  /// In es, this message translates to:
  /// **'Luxelane pidió cambios en tu solicitud. Revisa los documentos marcados y vuelve a enviarla.'**
  String get regStatusNeedsChanges;

  /// Registro de chófer (app del chófer): solicitud rechazada.
  ///
  /// In es, this message translates to:
  /// **'Solicitud no aprobada'**
  String get regStatusRejectedTitle;

  /// Registro de chófer (app del chófer): la solicitud está cerrada.
  ///
  /// In es, this message translates to:
  /// **'Esta solicitud no fue aprobada y está cerrada.'**
  String get regStatusRejectedBody;

  /// Registro de chófer (app del chófer): actualizar el estado.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get regRefresh;

  /// Registro de chófer (app del chófer): no se conecta sin segundo factor (mfaEnforced).
  ///
  /// In es, this message translates to:
  /// **'Para conectarte, activa la verificación en dos pasos.'**
  String get regOnlineNeedsMfa;

  /// Registro de chófer (app del chófer): tiene segundo factor pero la sesión no lo usó.
  ///
  /// In es, this message translates to:
  /// **'Para conectarte, cierra sesión y vuelve a entrar con el código de tu app autenticadora.'**
  String get regOnlineNeedsMfaSignIn;

  /// Registro de chófer (app del chófer): botón del aviso para activar el segundo factor.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get regOnlineMfaAction;

  /// Registro de chófer: nombre del documento de tipo profile_photo (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Foto de perfil'**
  String get regDocTypeProfilePhoto;

  /// Registro de chófer: nombre del documento de tipo live_photo (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Foto en vivo'**
  String get regDocTypeLivePhoto;

  /// Registro de chófer: nombre del documento de tipo national_id_front (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Documento de identidad (anverso)'**
  String get regDocTypeNationalIdFront;

  /// Registro de chófer: nombre del documento de tipo national_id_back (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Documento de identidad (reverso)'**
  String get regDocTypeNationalIdBack;

  /// Registro de chófer: nombre del documento de tipo license_front (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Licencia de conducir (anverso)'**
  String get regDocTypeLicenseFront;

  /// Registro de chófer: nombre del documento de tipo license_back (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Licencia de conducir (reverso)'**
  String get regDocTypeLicenseBack;

  /// Registro de chófer: nombre del documento de tipo criminal_record (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Certificado de antecedentes'**
  String get regDocTypeCriminalRecord;

  /// Registro de chófer: nombre del documento de tipo vehicle_ownership (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Documento de propiedad del vehículo'**
  String get regDocTypeVehicleOwnership;

  /// Registro de chófer: nombre del documento de tipo vehicle_soat (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Seguro obligatorio de accidentes (SOAT)'**
  String get regDocTypeVehicleSoat;

  /// Registro de chófer: nombre del documento de tipo vehicle_inspection (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Inspección técnica del vehículo'**
  String get regDocTypeVehicleInspection;

  /// Registro de chófer: nombre del documento de tipo vehicle_insurance (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Seguro del vehículo'**
  String get regDocTypeVehicleInsurance;

  /// Registro de chófer: nombre del documento de tipo vehicle_permit (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Permiso de operación del vehículo'**
  String get regDocTypeVehiclePermit;

  /// Registro de chófer: nombre del documento de tipo owner_authorization (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Autorización del propietario'**
  String get regDocTypeOwnerAuthorization;

  /// Registro de chófer: nombre del documento de tipo vehicle_photo_front (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Vehículo: frente'**
  String get regDocTypeVehiclePhotoFront;

  /// Registro de chófer: nombre del documento de tipo vehicle_photo_back (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Vehículo: parte trasera'**
  String get regDocTypeVehiclePhotoBack;

  /// Registro de chófer: nombre del documento de tipo vehicle_photo_left (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Vehículo: lado izquierdo'**
  String get regDocTypeVehiclePhotoLeft;

  /// Registro de chófer: nombre del documento de tipo vehicle_photo_right (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Vehículo: lado derecho'**
  String get regDocTypeVehiclePhotoRight;

  /// Registro de chófer: nombre del documento de tipo vehicle_photo_interior_front (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Vehículo: interior delantero'**
  String get regDocTypeVehiclePhotoInteriorFront;

  /// Registro de chófer: nombre del documento de tipo vehicle_photo_interior_back (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Vehículo: interior trasero'**
  String get regDocTypeVehiclePhotoInteriorBack;

  /// Registro de chófer: nombre del documento de tipo vehicle_photo_plate (app del chófer y panel).
  ///
  /// In es, this message translates to:
  /// **'Vehículo: placa'**
  String get regDocTypeVehiclePhotoPlate;

  /// Registro de chófer: estado de la solicitud draft.
  ///
  /// In es, this message translates to:
  /// **'Borrador'**
  String get regAppStatusDraft;

  /// Registro de chófer: estado de la solicitud submitted.
  ///
  /// In es, this message translates to:
  /// **'Enviada'**
  String get regAppStatusSubmitted;

  /// Registro de chófer: estado de la solicitud in_review.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get regAppStatusInReview;

  /// Registro de chófer: estado de la solicitud needs_changes.
  ///
  /// In es, this message translates to:
  /// **'Necesita cambios'**
  String get regAppStatusNeedsChanges;

  /// Registro de chófer: estado de la solicitud approved.
  ///
  /// In es, this message translates to:
  /// **'Aprobada'**
  String get regAppStatusApproved;

  /// Registro de chófer: estado de la solicitud rejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazada'**
  String get regAppStatusRejected;

  /// Registro de chófer: estado de un documento pending_upload.
  ///
  /// In es, this message translates to:
  /// **'Por subir'**
  String get regDocStatusPendingUpload;

  /// Registro de chófer: estado de un documento uploaded.
  ///
  /// In es, this message translates to:
  /// **'Subido, en revisión'**
  String get regDocStatusUploaded;

  /// Registro de chófer: estado de un documento approved.
  ///
  /// In es, this message translates to:
  /// **'Aprobado'**
  String get regDocStatusApproved;

  /// Registro de chófer: estado de un documento rejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazado'**
  String get regDocStatusRejected;

  /// Registro de chófer: estado de un documento expired.
  ///
  /// In es, this message translates to:
  /// **'Vencido'**
  String get regDocStatusExpired;

  /// Registro de chófer: motivo de rechazo de un documento (illegible).
  ///
  /// In es, this message translates to:
  /// **'No se lee bien'**
  String get regRejectIllegible;

  /// Registro de chófer: motivo de rechazo de un documento (expired).
  ///
  /// In es, this message translates to:
  /// **'Está vencido'**
  String get regRejectExpired;

  /// Registro de chófer: motivo de rechazo de un documento (wrong_document).
  ///
  /// In es, this message translates to:
  /// **'No es el documento pedido'**
  String get regRejectWrongDocument;

  /// Registro de chófer: motivo de rechazo de un documento (incomplete).
  ///
  /// In es, this message translates to:
  /// **'Está incompleto o cortado'**
  String get regRejectIncomplete;

  /// Registro de chófer: motivo de rechazo de un documento (data_mismatch).
  ///
  /// In es, this message translates to:
  /// **'Los datos no coinciden con los de la solicitud'**
  String get regRejectDataMismatch;

  /// Registro de chófer: motivo de rechazo de un documento (low_quality).
  ///
  /// In es, this message translates to:
  /// **'Imagen de baja calidad'**
  String get regRejectLowQuality;

  /// Registro de chófer: motivo de rechazo de un documento (other).
  ///
  /// In es, this message translates to:
  /// **'Otro motivo'**
  String get regRejectOther;

  /// Registro de chófer: color del vehículo black (mismo texto que el catálogo del servidor).
  ///
  /// In es, this message translates to:
  /// **'Negro'**
  String get regColorBlack;

  /// Registro de chófer: color del vehículo white (mismo texto que el catálogo del servidor).
  ///
  /// In es, this message translates to:
  /// **'Blanco'**
  String get regColorWhite;

  /// Registro de chófer: color del vehículo silver (mismo texto que el catálogo del servidor).
  ///
  /// In es, this message translates to:
  /// **'Plateado'**
  String get regColorSilver;

  /// Registro de chófer: color del vehículo gray (mismo texto que el catálogo del servidor).
  ///
  /// In es, this message translates to:
  /// **'Gris'**
  String get regColorGray;

  /// Registro de chófer: color del vehículo blue (mismo texto que el catálogo del servidor).
  ///
  /// In es, this message translates to:
  /// **'Azul'**
  String get regColorBlue;

  /// Registro de chófer: color del vehículo red (mismo texto que el catálogo del servidor).
  ///
  /// In es, this message translates to:
  /// **'Rojo'**
  String get regColorRed;

  /// Registro de chófer: color del vehículo green (mismo texto que el catálogo del servidor).
  ///
  /// In es, this message translates to:
  /// **'Verde'**
  String get regColorGreen;

  /// Registro de chófer: color del vehículo beige (mismo texto que el catálogo del servidor).
  ///
  /// In es, this message translates to:
  /// **'Beige'**
  String get regColorBeige;

  /// Registro de chófer: color del vehículo brown (mismo texto que el catálogo del servidor).
  ///
  /// In es, this message translates to:
  /// **'Marrón'**
  String get regColorBrown;

  /// Registro de chófer: color del vehículo other (mismo texto que el catálogo del servidor).
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get regColorOther;

  /// Registro de chófer: tipo de carrocería sedan.
  ///
  /// In es, this message translates to:
  /// **'Sedán'**
  String get regBodySedan;

  /// Registro de chófer: tipo de carrocería suv.
  ///
  /// In es, this message translates to:
  /// **'SUV'**
  String get regBodySuv;

  /// Registro de chófer: tipo de carrocería van.
  ///
  /// In es, this message translates to:
  /// **'Van'**
  String get regBodyVan;

  /// Ventana del chófer: cierre del viaje terminado.
  ///
  /// In es, this message translates to:
  /// **'Viaje terminado'**
  String get driverTripClosedCompletedTitle;

  /// Ventana del chófer: dónde verá el viaje terminado.
  ///
  /// In es, this message translates to:
  /// **'Lo verás en tu historial.'**
  String get driverTripClosedCompletedBody;

  /// Ventana del chófer: cierre tras marcar que el pasajero no se presentó.
  ///
  /// In es, this message translates to:
  /// **'Marcaste que el pasajero no se presentó'**
  String get driverTripClosedNoShowTitle;

  /// Ventana del chófer: qué pasa tras «no se presentó».
  ///
  /// In es, this message translates to:
  /// **'Central revisará el viaje.'**
  String get driverTripClosedNoShowBody;

  /// Ventana del chófer: el viaje se canceló mientras el chófer lo tenía abierto.
  ///
  /// In es, this message translates to:
  /// **'El viaje se canceló'**
  String get driverTripClosedCancelledTitle;

  /// Ventana del chófer: tras la cancelación.
  ///
  /// In es, this message translates to:
  /// **'Ya no tienes que ir a la recogida.'**
  String get driverTripClosedCancelledBody;

  /// Ventana del chófer: el viaje dejó de estar a cargo del chófer y no se sabe aún cómo terminó.
  ///
  /// In es, this message translates to:
  /// **'Este viaje ya no está a tu cargo'**
  String get driverTripClosedOtherTitle;

  /// Ventana del chófer: qué hacer si no sabe por qué.
  ///
  /// In es, this message translates to:
  /// **'Si tienes dudas, consulta con central.'**
  String get driverTripClosedOtherBody;

  /// Ventana del chófer: botón para volver a las solicitudes.
  ///
  /// In es, this message translates to:
  /// **'Volver a solicitudes'**
  String get driverTripClosedBack;

  /// Historial del chófer: no se pudieron leer los viajes terminados.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar tus viajes terminados.'**
  String get driverHistoryLoadFailed;

  /// Historial del chófer: lectura en curso (lector de pantalla).
  ///
  /// In es, this message translates to:
  /// **'Cargando tus viajes terminados'**
  String get driverHistoryLoading;

  /// Ganancias: viaje por horas, con la zona de recogida (sin dirección exacta).
  ///
  /// In es, this message translates to:
  /// **'Por horas · {area}'**
  String driverEarningsTripArea(String area);

  /// Ganancias: viaje sin zona registrada.
  ///
  /// In es, this message translates to:
  /// **'Zona sin registrar'**
  String get driverEarningsAreaUnknown;

  /// Error: el servidor o Firebase limitó los intentos.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.'**
  String get errorTooManyAttempts;

  /// Error: la sesión ya no es válida y hay que volver a entrar.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión expiró. Vuelve a iniciar sesión.'**
  String get errorSessionExpired;

  /// Error: la acción exige la verificación en dos pasos activada (se activa en Perfil).
  ///
  /// In es, this message translates to:
  /// **'Activa la verificación en dos pasos (Perfil) y vuelve a iniciar sesión para continuar.'**
  String get errorMfaRequired;

  /// Error: la acción exige haber iniciado sesión hace poco.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, vuelve a iniciar sesión para continuar.'**
  String get errorReauthRequired;

  /// Error: no hay conexión con el servidor.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión con el servidor. Revisa tu red e inténtalo de nuevo.'**
  String get errorNoConnection;

  /// Error al volver a identificarse: la contraseña no es la de la cuenta.
  ///
  /// In es, this message translates to:
  /// **'La contraseña no coincide.'**
  String get errorReauthWrongPassword;

  /// Error al volver a identificarse con otra cuenta distinta de la actual.
  ///
  /// In es, this message translates to:
  /// **'Usa la misma cuenta con la que entraste.'**
  String get errorReauthUserMismatch;

  /// Error genérico al volver a identificarse.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar tu identidad. Inténtalo de nuevo.'**
  String get errorReauthFailed;

  /// Error genérico: el servidor rechazó los datos enviados.
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos e inténtalo de nuevo.'**
  String get errorInvalidArgument;

  /// Error genérico: la cuenta no tiene permiso para la acción.
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para hacer esto.'**
  String get errorPermissionDenied;

  /// Error genérico: la acción no se puede hacer en el estado actual.
  ///
  /// In es, this message translates to:
  /// **'Esto no se puede hacer en este momento.'**
  String get errorFailedPrecondition;

  /// Error genérico: el documento pedido no existe.
  ///
  /// In es, this message translates to:
  /// **'No encontramos el registro.'**
  String get errorNotFound;

  /// Error genérico de último recurso.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar. Inténtalo de nuevo.'**
  String get errorGeneric;

  /// Error al eliminar la cuenta: tiene viajes activos o reservados.
  ///
  /// In es, this message translates to:
  /// **'Tienes viajes activos o reservados. Cancélalos o espera a que terminen antes de eliminar tu cuenta.'**
  String get errorDeleteActiveBookings;

  /// Error al eliminar la cuenta: es de administración.
  ///
  /// In es, this message translates to:
  /// **'Las cuentas de administración se eliminan desde la consola.'**
  String get errorDeleteAdminAccount;

  /// Error genérico al eliminar la cuenta.
  ///
  /// In es, this message translates to:
  /// **'No pudimos eliminar tu cuenta. Inténtalo de nuevo.'**
  String get errorDeleteAccountFailed;

  /// Error al aceptar los términos: cambiaron mientras se leían.
  ///
  /// In es, this message translates to:
  /// **'Los términos se acaban de actualizar. Vuelve a abrirlos y acéptalos de nuevo.'**
  String get errorTermsOutdated;

  /// Error genérico al registrar la aceptación de los términos.
  ///
  /// In es, this message translates to:
  /// **'No pudimos registrar tu aceptación. Inténtalo de nuevo.'**
  String get errorAcceptTermsFailed;

  /// Error del formulario de empresas: demasiadas solicitudes desde el mismo lugar.
  ///
  /// In es, this message translates to:
  /// **'Ya recibimos varias solicitudes desde aquí. Inténtalo más tarde o escríbenos.'**
  String get errorBusinessLeadTooMany;

  /// Error del formulario de empresas: datos no válidos.
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos del formulario.'**
  String get errorBusinessLeadInvalid;

  /// Error genérico al enviar el formulario de empresas.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enviar tu solicitud. Inténtalo de nuevo.'**
  String get errorBusinessLeadFailed;

  /// Error al iniciar sesión: el mismo texto si no hay cuenta o la contraseña no es correcta.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos.'**
  String get errorBadCredentials;

  /// Respuesta al pedir restablecer la contraseña: la misma haya o no cuenta con ese correo.
  ///
  /// In es, this message translates to:
  /// **'Si hay una cuenta con {email}, te enviamos un enlace para restablecer tu contraseña. Revisa también el correo no deseado.'**
  String errorPasswordResetSent(String email);

  /// Error genérico al iniciar sesión.
  ///
  /// In es, this message translates to:
  /// **'No pudimos iniciar sesión. Inténtalo de nuevo.'**
  String get errorLoginFailed;

  /// Error al registrarse con un correo que quizá ya tiene cuenta (sin confirmarlo).
  ///
  /// In es, this message translates to:
  /// **'No pudimos crear la cuenta con ese correo. Si ya te registraste, inicia sesión o recupera tu contraseña.'**
  String get errorRegisterEmailInUse;

  /// Error: el correo escrito no tiene un formato válido.
  ///
  /// In es, this message translates to:
  /// **'Ese correo no es válido. Revísalo.'**
  String get errorInvalidEmail;

  /// Error al registrarse: contraseña demasiado corta.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es muy débil: usa al menos 6 caracteres.'**
  String get errorWeakPassword;

  /// Error genérico al crear la cuenta.
  ///
  /// In es, this message translates to:
  /// **'No pudimos crear la cuenta. Inténtalo de nuevo.'**
  String get errorRegisterFailed;

  /// Error genérico al enviar el enlace para restablecer la contraseña.
  ///
  /// In es, this message translates to:
  /// **'No pudimos enviar el enlace. Inténtalo de nuevo.'**
  String get errorPasswordResetFailed;

  /// Mensaje por defecto de un fallo del servidor sin texto propio (el original ya estaba en inglés y se conserva igual en español).
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la operación. Inténtalo de nuevo.'**
  String get errorServerDefault;

  /// Error al reservar: el correo de la cuenta no está verificado.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu correo para poder reservar.'**
  String get errorEmailNotVerified;

  /// Error al reservar: falta aceptar los términos vigentes.
  ///
  /// In es, this message translates to:
  /// **'Acepta los términos vigentes para poder reservar.'**
  String get errorTermsRequired;

  /// Mensaje por defecto de un fallo de autenticación sin texto propio (el original ya estaba en inglés y se conserva igual en español).
  ///
  /// In es, this message translates to:
  /// **'No se pudo iniciar sesión. Inténtalo de nuevo.'**
  String get errorAuthDefault;

  /// Mensaje por defecto cuando la persona cierra la ventana de inicio de sesión (no se muestra como error; el original ya estaba en inglés).
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión cancelado.'**
  String get errorAuthCancelledDefault;

  /// Mensaje por defecto de un fallo de red sin texto propio (el original ya estaba en inglés y se conserva igual en español).
  ///
  /// In es, this message translates to:
  /// **'No internet connection'**
  String get errorNetworkDefault;

  /// Mensaje por defecto cuando no existe un documento (el original ya estaba en inglés y se conserva igual en español).
  ///
  /// In es, this message translates to:
  /// **'No encontramos lo que buscabas.'**
  String get errorNotFoundDefault;

  /// Mensaje por defecto de un fallo de pago sin texto propio (el original ya estaba en inglés y se conserva igual en español).
  ///
  /// In es, this message translates to:
  /// **'No se pudo procesar el pago. Inténtalo de nuevo.'**
  String get errorPaymentDefault;

  /// Mensaje por defecto de un fallo de permisos sin texto propio (el original ya estaba en inglés y se conserva igual en español).
  ///
  /// In es, this message translates to:
  /// **'No tienes permiso para hacer esto.'**
  String get errorPermissionDefault;

  /// Error al reservar: el servidor calculó otro precio y hay que confirmarlo.
  ///
  /// In es, this message translates to:
  /// **'El precio de este viaje cambió.'**
  String get errorPriceChanged;

  /// Error al cancelar: la retención por cancelar cambió mientras se decidía.
  ///
  /// In es, this message translates to:
  /// **'El recargo por cancelar cambió.'**
  String get errorCancellationFeeChanged;

  /// Error en la app del chófer: la versión es demasiado antigua para avanzar un viaje.
  ///
  /// In es, this message translates to:
  /// **'Actualiza la app para seguir con tus viajes.'**
  String get errorAppUpdateDriver;

  /// Error en la app del pasajero: la versión es demasiado antigua para reservar.
  ///
  /// In es, this message translates to:
  /// **'Actualiza la app para reservar.'**
  String get errorAppUpdateRider;

  /// Mensaje por defecto de un fallo de validación sin texto propio (el original ya estaba en inglés y se conserva igual en español).
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos e inténtalo de nuevo.'**
  String get errorValidationDefault;

  /// Segundo paso del inicio de sesión: pide el código de la app autenticadora (TOTP).
  ///
  /// In es, this message translates to:
  /// **'Introduce el código de tu app autenticadora.'**
  String get errorMfaEnterCode;

  /// Error de verificación en dos pasos: el código no es válido.
  ///
  /// In es, this message translates to:
  /// **'Código incorrecto. Usa el código actual de tu app autenticadora (y revisa que la hora del teléfono sea automática).'**
  String get errorMfaWrongCode;

  /// Error al dar de alta la verificación en dos pasos: hace falta un inicio de sesión reciente.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, cierra sesión, vuelve a entrar y repite el alta.'**
  String get errorMfaRecentLogin;

  /// Error al dar de alta la verificación en dos pasos sin el correo verificado.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu correo antes de activar la verificación en dos pasos.'**
  String get errorMfaUnverifiedEmail;

  /// Error de verificación en dos pasos: sin conexión.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu red e inténtalo de nuevo.'**
  String get errorMfaNoConnection;

  /// Error de verificación en dos pasos: venció el alta (código QR).
  ///
  /// In es, this message translates to:
  /// **'El código QR venció. Empieza el alta de nuevo.'**
  String get errorMfaQrExpired;

  /// Error: la verificación en dos pasos no está habilitada en el proyecto.
  ///
  /// In es, this message translates to:
  /// **'La verificación en dos pasos aún no está activada. Avisa a central.'**
  String get errorMfaNotEnabled;

  /// Error: la cuenta no tiene app autenticadora para el segundo paso.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta no tiene una app autenticadora registrada. Contacta con central.'**
  String get errorMfaNoTotp;

  /// Error genérico de la verificación en dos pasos.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la verificación. Inténtalo de nuevo.'**
  String get errorMfaFailed;

  /// Error al entrar: la cuenta del pasajero está bloqueada desde el panel.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta está bloqueada. Escríbenos a soporte si crees que es un error.'**
  String get errorAccountBlocked;

  /// Error al entrar: la cuenta del chófer está suspendida.
  ///
  /// In es, this message translates to:
  /// **'Cuenta suspendida. Contacta con central.'**
  String get errorDriverSuspended;

  /// Error: el servidor exige verificar la app (App Check) y no se pudo.
  ///
  /// In es, this message translates to:
  /// **'No se pudo verificar la app. Actualízala o inténtalo más tarde.'**
  String get errorAppCheckFailed;

  /// No se encontró el perfil de la cuenta (usuario o chófer). Antes salía «User not found» en inglés.
  ///
  /// In es, this message translates to:
  /// **'No encontramos tu perfil. Vuelve a iniciar sesión.'**
  String get errorProfileNotFound;

  /// Error del registro de chóferes: el servidor respondió «has_bookings».
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta ya tiene reservas como pasajero. Para registrarte como chófer, crea una cuenta con otro correo.'**
  String get regErrorHasBookings;

  /// Error del registro de chóferes: el servidor respondió «driver_account».
  ///
  /// In es, this message translates to:
  /// **'Una cuenta de chófer no puede usar pagos de pasajero.'**
  String get regErrorDriverAccount;

  /// Error del registro de chóferes: el servidor respondió «not_a_rider».
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta no puede iniciar una solicitud de chófer.'**
  String get regErrorNotARider;

  /// Error del registro de chóferes: el servidor respondió «admin_account».
  ///
  /// In es, this message translates to:
  /// **'Una cuenta de administración no puede registrarse como chófer.'**
  String get regErrorAdminAccount;

  /// Error del registro de chóferes: el servidor respondió «inactive_user».
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta está bloqueada.'**
  String get regErrorInactiveUser;

  /// Error del registro de chóferes: el servidor respondió «not_a_driver».
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta aún no tiene una solicitud de chófer.'**
  String get regErrorNotADriver;

  /// Error del registro de chóferes: el servidor respondió «locked_after_approval».
  ///
  /// In es, this message translates to:
  /// **'Tus datos ya fueron aprobados; solo Luxelane puede cambiarlos.'**
  String get regErrorLockedAfterApproval;

  /// Error del registro de chóferes: el servidor respondió «application_closed».
  ///
  /// In es, this message translates to:
  /// **'Esta solicitud está cerrada y ya no admite cambios.'**
  String get regErrorApplicationClosed;

  /// Error del registro de chóferes: el servidor respondió «plate_in_use».
  ///
  /// In es, this message translates to:
  /// **'Esa placa ya está registrada en otro vehículo activo.'**
  String get regErrorPlateInUse;

  /// Error del registro de chóferes: el servidor respondió «invalid_file».
  ///
  /// In es, this message translates to:
  /// **'El archivo no es una imagen válida o supera el tamaño permitido. Toma la foto otra vez.'**
  String get regErrorInvalidFile;

  /// Error del registro de chóferes: el servidor respondió «file_missing».
  ///
  /// In es, this message translates to:
  /// **'No encontramos el archivo subido. Vuelve a intentarlo.'**
  String get regErrorFileMissing;

  /// Error del registro de chóferes: el servidor respondió «unexpected_version».
  ///
  /// In es, this message translates to:
  /// **'El documento cambió mientras lo subías. Actualiza la pantalla y vuelve a intentarlo.'**
  String get regErrorUnexpectedVersion;

  /// Error del registro de chóferes: el servidor respondió «document_expired».
  ///
  /// In es, this message translates to:
  /// **'La fecha de vencimiento ya pasó. Sube un documento vigente.'**
  String get regErrorDocumentExpired;

  /// Error del registro de chóferes: el servidor respondió «requirements_not_configured».
  ///
  /// In es, this message translates to:
  /// **'Aún no podemos recibir solicitudes: faltan por definir los documentos que se piden. Puedes guardar tus datos y enviar más adelante.'**
  String get regErrorRequirementsNotConfigured;

  /// Error del registro de chóferes: el servidor respondió «steps_incomplete».
  ///
  /// In es, this message translates to:
  /// **'Completa tus datos personales y los del vehículo antes de enviar.'**
  String get regErrorStepsIncomplete;

  /// Error del registro de chóferes: el servidor respondió «documents_missing».
  ///
  /// In es, this message translates to:
  /// **'Faltan documentos obligatorios o hay alguno vencido o rechazado.'**
  String get regErrorDocumentsMissing;

  /// Error del registro de chóferes: el servidor respondió «invalid_request».
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos marcados e inténtalo de nuevo.'**
  String get regErrorInvalidRequest;

  /// Error del registro de chóferes: el servidor respondió «driver_docs_blocked».
  ///
  /// In es, this message translates to:
  /// **'Tienes documentos obligatorios vencidos. Súbelos de nuevo para volver a conectarte.'**
  String get regErrorDriverDocsBlocked;

  /// Error del registro de chóferes: el servidor respondió «profile_not_found».
  ///
  /// In es, this message translates to:
  /// **'No encontramos tu perfil. Cierra sesión y vuelve a entrar.'**
  String get regErrorProfileNotFound;

  /// Error del registro de chóferes: el servidor respondió «documents_not_approved».
  ///
  /// In es, this message translates to:
  /// **'No se puede aprobar: hay documentos obligatorios sin aprobar o vencidos.'**
  String get regErrorDocumentsNotApproved;

  /// Error del registro de chóferes: el servidor respondió «not_decidable».
  ///
  /// In es, this message translates to:
  /// **'La solicitud no está en un estado que admita esta decisión.'**
  String get regErrorNotDecidable;

  /// Error del registro de chóferes: el servidor respondió «not_reviewable».
  ///
  /// In es, this message translates to:
  /// **'Este documento no se puede revisar en su estado actual.'**
  String get regErrorNotReviewable;

  /// Error del registro de chóferes: el servidor respondió «stale_version».
  ///
  /// In es, this message translates to:
  /// **'El chófer subió una versión más nueva. Actualiza y revisa la última.'**
  String get regErrorStaleVersion;

  /// Error del registro de chóferes: el servidor respondió «document_not_found».
  ///
  /// In es, this message translates to:
  /// **'Ese documento no existe o aún no se subió.'**
  String get regErrorDocumentNotFound;

  /// Error del registro de chóferes: el servidor respondió «driver_not_found».
  ///
  /// In es, this message translates to:
  /// **'No encontramos a ese chófer.'**
  String get regErrorDriverNotFound;

  /// Error del registro de chóferes: el servidor respondió «application_not_found».
  ///
  /// In es, this message translates to:
  /// **'No encontramos esa solicitud.'**
  String get regErrorApplicationNotFound;

  /// Error del registro de chóferes: el servidor respondió «purge_disabled».
  ///
  /// In es, this message translates to:
  /// **'El borrado de documentos está desactivado.'**
  String get regErrorPurgeDisabled;

  /// Error del registro de chóferes: el servidor respondió «(otro)».
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar este paso. Inténtalo de nuevo.'**
  String get regErrorGeneric;

  /// Error de la reserva con vuelo: el servidor respondió «flight_config_missing».
  ///
  /// In es, this message translates to:
  /// **'Aún no se pueden reservar recogidas con vuelo. Inténtalo más tarde.'**
  String get bookingErrorFlightConfigMissing;

  /// Error de la reserva con vuelo: el servidor respondió «airport_unknown».
  ///
  /// In es, this message translates to:
  /// **'Este aeropuerto aún no está disponible para recogidas.'**
  String get bookingErrorAirportUnknown;

  /// Error de la reserva con vuelo: el servidor respondió «flight_not_airport_pickup».
  ///
  /// In es, this message translates to:
  /// **'El vuelo solo se indica cuando la recogida es en el aeropuerto de llegada.'**
  String get bookingErrorFlightNotAirportPickup;

  /// Vuelos (pasajero): título del paso del vuelo en la reserva de aeropuerto.
  ///
  /// In es, this message translates to:
  /// **'Tu vuelo'**
  String get bookingFlightSectionTitle;

  /// Vuelos (pasajero): campo aerolínea (opcional).
  ///
  /// In es, this message translates to:
  /// **'Aerolínea (opcional)'**
  String get bookingFlightAirline;

  /// Vuelos (pasajero): campo fecha del vuelo.
  ///
  /// In es, this message translates to:
  /// **'Fecha del vuelo'**
  String get bookingFlightDate;

  /// Vuelos (pasajero): campo hora de llegada del billete.
  ///
  /// In es, this message translates to:
  /// **'Hora de llegada según tu billete'**
  String get bookingFlightTime;

  /// Vuelos (pasajero): elegir la fecha.
  ///
  /// In es, this message translates to:
  /// **'Elegir fecha'**
  String get bookingFlightPickDate;

  /// Vuelos (pasajero): elegir la hora.
  ///
  /// In es, this message translates to:
  /// **'Elegir hora'**
  String get bookingFlightPickTime;

  /// Vuelos (pasajero): falta la fecha.
  ///
  /// In es, this message translates to:
  /// **'Indica la fecha del vuelo'**
  String get bookingFlightDateMissing;

  /// Vuelos (pasajero): falta la hora.
  ///
  /// In es, this message translates to:
  /// **'Indica la hora de llegada de tu billete'**
  String get bookingFlightTimeMissing;

  /// Vuelos (pasajero): pregunta del equipaje facturado.
  ///
  /// In es, this message translates to:
  /// **'¿Llevas equipaje facturado?'**
  String get bookingFlightCheckedBagQuestion;

  /// Vuelos (pasajero): respuesta: con equipaje facturado.
  ///
  /// In es, this message translates to:
  /// **'Sí, con equipaje facturado'**
  String get bookingFlightCheckedBagYes;

  /// Vuelos (pasajero): respuesta: sin equipaje facturado.
  ///
  /// In es, this message translates to:
  /// **'No, solo de mano'**
  String get bookingFlightCheckedBagNo;

  /// Vuelos (pasajero): ayuda sobria sobre el equipaje facturado.
  ///
  /// In es, this message translates to:
  /// **'Si declaras sin equipaje y lo llevas, tu chófer puede irse antes de que salgas.'**
  String get bookingFlightCheckedBagHelp;

  /// Vuelos (pasajero): vuelo con retraso en el viaje del pasajero.
  ///
  /// In es, this message translates to:
  /// **'Tu vuelo figura con retraso. Nueva hora de recogida: {time}.'**
  String rideFlightDelayed(String time);

  /// Vuelos (pasajero): vuelo cancelado o desviado en el viaje del pasajero.
  ///
  /// In es, this message translates to:
  /// **'Tu vuelo figura como cancelado o desviado. Central revisará tu reserva.'**
  String get rideFlightDisrupted;

  /// Vuelos (pasajero): título de la tarjeta del vuelo del chófer.
  ///
  /// In es, this message translates to:
  /// **'Vuelo'**
  String get driverFlightCardTitle;

  /// Vuelos (pasajero): estado del vuelo en la tarjeta del chófer.
  ///
  /// In es, this message translates to:
  /// **'Estado: {status}'**
  String driverFlightStatus(String status);

  /// Vuelos: solicitud abierta con recogida en aeropuerto; solo aeropuerto y tipo de vuelo, nunca el número.
  ///
  /// In es, this message translates to:
  /// **'Aeropuerto {airport} · {type}'**
  String driverRequestAirportFlight(String airport, String type);

  /// Vuelos: estado del vuelo (scheduled).
  ///
  /// In es, this message translates to:
  /// **'Programado'**
  String get flightStatusScheduled;

  /// Vuelos: estado del vuelo (delayed).
  ///
  /// In es, this message translates to:
  /// **'Retrasado'**
  String get flightStatusDelayed;

  /// Vuelos: estado del vuelo (landed).
  ///
  /// In es, this message translates to:
  /// **'Aterrizó'**
  String get flightStatusLanded;

  /// Vuelos: estado del vuelo (cancelled).
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get flightStatusCancelled;

  /// Vuelos: estado del vuelo (diverted).
  ///
  /// In es, this message translates to:
  /// **'Desviado'**
  String get flightStatusDiverted;

  /// Vuelos: estado del vuelo (unknown).
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get flightStatusUnknown;

  /// Vuelos: sin punto de recogida definido para el aeropuerto.
  ///
  /// In es, this message translates to:
  /// **'Punto por confirmar con central'**
  String get flightPickupPointPending;

  /// Vuelos: sin datos en vivo; solo la hora programada.
  ///
  /// In es, this message translates to:
  /// **'Sin datos de vuelo en vivo: hora programada {time}'**
  String flightNoLiveData(String time);

  /// Vuelos: el chófer debe estar en el punto de recogida a esa hora.
  ///
  /// In es, this message translates to:
  /// **'Debes estar en el punto a las {time}'**
  String flightBeAtPointAt(String time);

  /// Vuelos: el pasajero ve a qué hora estará el chófer en el punto.
  ///
  /// In es, this message translates to:
  /// **'Hora de recogida en el punto: {time}'**
  String flightDriverWillBeAt(String time);

  /// Vuelos: hora estimada de llegada.
  ///
  /// In es, this message translates to:
  /// **'Llegada estimada: {time}'**
  String flightEstimatedArrival(String time);

  /// Vuelos: hora programada de llegada.
  ///
  /// In es, this message translates to:
  /// **'Llegada programada: {time}'**
  String flightScheduledArrival(String time);

  /// Vuelos: hora real de llegada.
  ///
  /// In es, this message translates to:
  /// **'Aterrizó: {time}'**
  String flightActualArrival(String time);

  /// Título del mapa para elegir el punto de recogida.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar lugar de recogida'**
  String get homePickOriginTitle;

  /// Título del mapa para elegir el destino.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar destino'**
  String get homePickDestinationTitle;

  /// Aviso: al cambiar la recogida, el destino quedó en otra ciudad y se borró.
  ///
  /// In es, this message translates to:
  /// **'El destino estaba en otra ciudad. Elige uno en la ciudad de recogida.'**
  String get homeDestinationOtherCity;

  /// Aviso al buscar sin punto de recogida.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un lugar de recogida'**
  String get homeEnterPickup;

  /// Aviso: la hora elegida quedó en el pasado y se movió; {when} es fecha y hora ya formateadas.
  ///
  /// In es, this message translates to:
  /// **'Esa hora ya no da tiempo: la movimos a {when}. Revísala y continúa.'**
  String homePickupMoved(String when);

  /// Aviso al buscar un viaje de ida sin destino.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un destino'**
  String get homeEnterDestination;

  /// Explicación en el mapa cuando no hay acceso a la ubicación del dispositivo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos usar tu ubicación. Permite el acceso a la ubicación en tu navegador o en los ajustes del teléfono, o elige el punto en el mapa.'**
  String get homeLocationUnavailable;

  /// Etiqueta del lector de pantalla del botón de perfil.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get homeMyProfile;

  /// Botón principal del inicio: pasar a elegir vehículo.
  ///
  /// In es, this message translates to:
  /// **'Ver vehículos y precios'**
  String get homeSeeVehicles;

  /// Próximo viaje por horas: duración y punto de recogida.
  ///
  /// In es, this message translates to:
  /// **'{hours} h desde {place}'**
  String homeHourlyFrom(int hours, String place);

  /// Etiqueta del lector de pantalla de la tarjeta del próximo viaje.
  ///
  /// In es, this message translates to:
  /// **'Ver tu próximo trayecto'**
  String get homeNextTripSemantics;

  /// Antetítulo de la tarjeta del próximo viaje (mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'TU PRÓXIMO TRAYECTO'**
  String get homeNextTripEyebrow;

  /// Etiqueta del campo de recogida.
  ///
  /// In es, this message translates to:
  /// **'Lugar de recogida'**
  String get homePickupLabel;

  /// Texto de ayuda del campo de recogida.
  ///
  /// In es, this message translates to:
  /// **'Recogida'**
  String get homePickupHint;

  /// Tooltip del botón de usar la ubicación actual.
  ///
  /// In es, this message translates to:
  /// **'Usar mi ubicación'**
  String get homeUseMyLocation;

  /// Etiqueta del campo de destino.
  ///
  /// In es, this message translates to:
  /// **'Destino'**
  String get homeDestinationLabel;

  /// Texto de ayuda del campo de destino.
  ///
  /// In es, this message translates to:
  /// **'¿A dónde vas?'**
  String get homeDestinationHint;

  /// Tooltip del botón de elegir el destino en el mapa.
  ///
  /// In es, this message translates to:
  /// **'Elegir en el mapa'**
  String get homeChooseOnMap;

  /// Atajo para repetir el último viaje.
  ///
  /// In es, this message translates to:
  /// **'Repetir último'**
  String get homeRepeatLast;

  /// Distancia y duración estimadas de la ruta.
  ///
  /// In es, this message translates to:
  /// **'{km} km · {minutes} min'**
  String homeRouteSummary(String km, int minutes);

  /// Clase de vehículo elegida en la flota (nombre de clase sin traducir).
  ///
  /// In es, this message translates to:
  /// **'Tu {vehicleClass}'**
  String homePreferredClass(String vehicleClass);

  /// Encabezado del calendario para la fecha de recogida (mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'FECHA DE RECOGIDA'**
  String get homePickupDateHelp;

  /// Encabezado del reloj para la hora de recogida (mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'HORA DE RECOGIDA'**
  String get homePickupTimeHelp;

  /// Botón cancelar del calendario y del reloj.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get homePickerCancel;

  /// Botón del calendario para pasar a la hora.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get homePickerNext;

  /// Botón del reloj para terminar.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get homePickerDone;

  /// Etiqueta del lector de pantalla para cambiar fecha y hora.
  ///
  /// In es, this message translates to:
  /// **'Cambiar fecha y hora de recogida'**
  String get homeChangePickupTime;

  /// Recogida próxima: lo antes posible y la hora ya formateada.
  ///
  /// In es, this message translates to:
  /// **'Lo antes posible · {time}'**
  String homeAsap(String time);

  /// Enlace para programar fecha y hora.
  ///
  /// In es, this message translates to:
  /// **'Programar'**
  String get homeSchedule;

  /// Etiqueta del selector de horas (servicio por horas).
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get homeDuration;

  /// Titular de la web, primera parte (termina en espacio; sigue en cursiva «te espera.»).
  ///
  /// In es, this message translates to:
  /// **'Tu chófer '**
  String get homeWebHeadlineStart;

  /// Titular de la web, segunda parte en cursiva.
  ///
  /// In es, this message translates to:
  /// **'te espera.'**
  String get homeWebHeadlineEnd;

  /// Etiqueta del campo de recogida en la barra de reserva (mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'RECOGIDA'**
  String get homeWebPickup;

  /// Etiqueta y ayuda del campo de recogida en la web.
  ///
  /// In es, this message translates to:
  /// **'¿Dónde estás?'**
  String get homeWebWhereAreYou;

  /// Etiqueta del campo de destino en la barra de reserva (mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'DESTINO'**
  String get homeWebDestination;

  /// Etiqueta del selector de horas en la barra de reserva (mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'DURACIÓN'**
  String get homeWebDuration;

  /// Etiqueta de fecha y hora en la barra de reserva (mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'FECHA Y HORA'**
  String get homeWebDateTime;

  /// Botón sobre el mapa para cambiar el punto (mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'CAMBIAR UBICACIÓN'**
  String get homeWebChangeLocation;

  /// Selector de servicio: viaje de ida.
  ///
  /// In es, this message translates to:
  /// **'Solo ida'**
  String get homeWebOneWay;

  /// Selector de servicio: por horas.
  ///
  /// In es, this message translates to:
  /// **'Por horas'**
  String get homeWebHourly;

  /// Botón de la barra de reserva (mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'VER PRECIOS'**
  String get homeWebSeePrices;

  /// Botón para confirmar fecha y hora en el calendario (mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'CONFIRMAR'**
  String get homeWebConfirm;

  /// Duración del servicio por horas.
  ///
  /// In es, this message translates to:
  /// **'{hours, plural, =1{1 hora} other{{hours} horas}}'**
  String homeWebHours(int hours);

  /// Cinta animada de la web (se muestra en mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'Precios Fijos'**
  String get homeWebMarqueeFixedPrices;

  /// Cinta animada de la web (se muestra en mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'Chóferes Profesionales'**
  String get homeWebMarqueeChauffeurs;

  /// Cinta animada de la web (se muestra en mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'Flota Premium'**
  String get homeWebMarqueeFleet;

  /// Cinta animada de la web (se muestra en mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'Traslados Aeroportuarios'**
  String get homeWebMarqueeAirport;

  /// Cinta animada de la web (se muestra en mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'Viajes Corporativos'**
  String get homeWebMarqueeCorporate;

  /// Antetítulo de la sección de flota.
  ///
  /// In es, this message translates to:
  /// **'Nuestra Flota'**
  String get homeWebFleetEyebrow;

  /// Título de la sección de flota (con salto de línea).
  ///
  /// In es, this message translates to:
  /// **'Vehículos premium,\nsin excepciones.'**
  String get homeWebFleetTitle;

  /// Indicación para desplazar el carrusel de la flota (mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'DESLIZA PARA EXPLORAR →'**
  String get homeWebFleetSwipe;

  /// Opinión 1 de la sección de testimonios.
  ///
  /// In es, this message translates to:
  /// **'Absolutamente impecable de principio a fin. El chófer llegó antes de tiempo y el auto estaba inmaculado. No usaré a nadie más.'**
  String get homeWebReview1Quote;

  /// Ciudad y país de la opinión 1.
  ///
  /// In es, this message translates to:
  /// **'Londres, Reino Unido'**
  String get homeWebReview1Location;

  /// Opinión 2 de la sección de testimonios.
  ///
  /// In es, this message translates to:
  /// **'Los precios fijos y los chóferes confiables hacen de Luxelane el único servicio en el que confío para todos mis viajes de negocios.'**
  String get homeWebReview2Quote;

  /// Ciudad y país de la opinión 2.
  ///
  /// In es, this message translates to:
  /// **'Nueva York, EE. UU.'**
  String get homeWebReview2Location;

  /// Opinión 3 de la sección de testimonios.
  ///
  /// In es, this message translates to:
  /// **'Del aeropuerto al hotel, cada detalle fue manejado a la perfección. Así es como debería sentirse el viaje de lujo.'**
  String get homeWebReview3Quote;

  /// Ciudad y país de la opinión 3.
  ///
  /// In es, this message translates to:
  /// **'París, Francia'**
  String get homeWebReview3Location;

  /// Ventaja de la sección para empresas.
  ///
  /// In es, this message translates to:
  /// **'Facturación y cobros centralizados'**
  String get homeWebBusinessPerkBilling;

  /// Ventaja para empresas (sección y libro).
  ///
  /// In es, this message translates to:
  /// **'Reservas prioritarias para ejecutivos'**
  String get homeWebBusinessPerkPriority;

  /// Antetítulo de la sección para empresas (y página del libro).
  ///
  /// In es, this message translates to:
  /// **'Para Empresas'**
  String get homeWebBusinessEyebrow;

  /// Título de la sección para empresas (con salto de línea).
  ///
  /// In es, this message translates to:
  /// **'Viajes corporativos,\nredefinidos.'**
  String get homeWebBusinessTitle;

  /// Texto de la sección para empresas.
  ///
  /// In es, this message translates to:
  /// **'Luxelane para Empresas brinda a tu equipo acceso a servicio de chófer premium con los controles e informes que tu equipo financiero exige.'**
  String get homeWebBusinessBody;

  /// Botón que lleva a la página para empresas.
  ///
  /// In es, this message translates to:
  /// **'Más información'**
  String get homeWebLearnMore;

  /// Antetítulo de la llamada final (mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'CUANDO QUIERAS. DONDE QUIERAS.'**
  String get homeWebCtaEyebrow;

  /// Llamada final, primera línea.
  ///
  /// In es, this message translates to:
  /// **'Tu próximo viaje,'**
  String get homeWebCtaTitleStart;

  /// Llamada final, segunda línea en cursiva.
  ///
  /// In es, this message translates to:
  /// **'en tus términos.'**
  String get homeWebCtaTitleEnd;

  /// Línea bajo la llamada final (con espacios alrededor del punto medio).
  ///
  /// In es, this message translates to:
  /// **'Precio fijo  ·  Chóferes profesionales'**
  String get homeWebCtaPromise;

  /// Botón de la llamada final.
  ///
  /// In es, this message translates to:
  /// **'Reservar un viaje'**
  String get homeWebCtaBook;

  /// Botón de la llamada final para ver la flota.
  ///
  /// In es, this message translates to:
  /// **'Ver flota'**
  String get homeWebCtaFleet;

  /// Lema bajo la marca en la portada del libro.
  ///
  /// In es, this message translates to:
  /// **'Servicio de Chófer Premium'**
  String get homeWebBookTagline;

  /// Libro, página 1: nombre.
  ///
  /// In es, this message translates to:
  /// **'El Estándar'**
  String get homeWebBookStandardLabel;

  /// Libro, página 1: subtítulo.
  ///
  /// In es, this message translates to:
  /// **'La Promesa Que Cumplimos'**
  String get homeWebBookStandardSub;

  /// Libro, página 1: etiqueta.
  ///
  /// In es, this message translates to:
  /// **'El Estándar Luxelane'**
  String get homeWebBookStandardTag;

  /// Libro, página 1: titular (con salto de línea).
  ///
  /// In es, this message translates to:
  /// **'El estándar que\notros siguen.'**
  String get homeWebBookStandardHeadline;

  /// Libro, página 1: punto.
  ///
  /// In es, this message translates to:
  /// **'Chóferes con documentos verificados'**
  String get homeWebBookStandardBullet1;

  /// Libro, página 1: punto.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo al reservar'**
  String get homeWebBookStandardBullet2;

  /// Libro, página 2: nombre y etiqueta.
  ///
  /// In es, this message translates to:
  /// **'La Experiencia'**
  String get homeWebBookExperienceLabel;

  /// Libro, página 2: subtítulo.
  ///
  /// In es, this message translates to:
  /// **'Cada Detalle Considerado'**
  String get homeWebBookExperienceSub;

  /// Libro, página 2: titular (con salto de línea).
  ///
  /// In es, this message translates to:
  /// **'Cada detalle,\ncuidado.'**
  String get homeWebBookExperienceHeadline;

  /// Libro, página 2: texto. En inglés y portugués sin «siempre» (glosario: sin promesas).
  ///
  /// In es, this message translates to:
  /// **'Desde listas de reproducción seleccionadas hasta privacidad con cancelación de ruido — tus preferencias recordadas, siempre.'**
  String get homeWebBookExperienceBody;

  /// Libro, página 2: punto.
  ///
  /// In es, this message translates to:
  /// **'Interiores de cuero premium'**
  String get homeWebBookExperienceBullet1;

  /// Libro, página 2: punto.
  ///
  /// In es, this message translates to:
  /// **'Wi-Fi y carga inalámbrica'**
  String get homeWebBookExperienceBullet2;

  /// Libro, página 2: punto.
  ///
  /// In es, this message translates to:
  /// **'Servicio de champán disponible'**
  String get homeWebBookExperienceBullet3;

  /// Libro, página 2: punto.
  ///
  /// In es, this message translates to:
  /// **'Control de clima ambiental'**
  String get homeWebBookExperienceBullet4;

  /// Libro, página 3: subtítulo.
  ///
  /// In es, this message translates to:
  /// **'Viajes Corporativos Redefinidos'**
  String get homeWebBookBusinessSub;

  /// Libro, página 3: punto.
  ///
  /// In es, this message translates to:
  /// **'Facturación centralizada'**
  String get homeWebBookBusinessBullet1;

  /// Antetítulo de la sección del libro (mayúsculas; en español también está en inglés).
  ///
  /// In es, this message translates to:
  /// **'NUESTRA EXPERIENCIA EXCLUSIVA'**
  String get homeWebBookEyebrow;

  /// Indicación vertical para desplazarse (mayúsculas; en español también está en inglés).
  ///
  /// In es, this message translates to:
  /// **'DESLIZA'**
  String get homeWebBookScroll;

  /// Primera frase del SMS de SOS que la persona envía a central, con el ID corto de la reserva. Se envía siempre en español (lo lee central); en/pt no se usan.
  ///
  /// In es, this message translates to:
  /// **'SOS. Reserva #{id}.'**
  String incidentSmsHeader(String id);

  /// SMS de SOS: enlace de mapa a la última ubicación. Se envía siempre en español (lo lee central); en/pt no se usan.
  ///
  /// In es, this message translates to:
  /// **'Ubicación: {link}'**
  String incidentSmsLocation(String link);

  /// SMS de SOS cuando no hay ubicación. Se envía siempre en español (lo lee central); en/pt no se usan.
  ///
  /// In es, this message translates to:
  /// **'Ubicación no disponible.'**
  String get incidentSmsNoLocation;

  /// Ayuda del SOS si no hay números de emergencia configurados (nunca se inventa uno).
  ///
  /// In es, this message translates to:
  /// **'Contacta con las autoridades locales.'**
  String get incidentNoNumbersHelp;

  /// Ayuda del SOS: enviando el aviso (título).
  ///
  /// In es, this message translates to:
  /// **'Avisando a central…'**
  String get incidentSendingTitle;

  /// Ayuda del SOS: enviando el aviso (detalle).
  ///
  /// In es, this message translates to:
  /// **'No cierres la app.'**
  String get incidentSendingBody;

  /// Ayuda del SOS: el aviso no llegó (título).
  ///
  /// In es, this message translates to:
  /// **'No pudimos avisar a central'**
  String get incidentFailedTitle;

  /// Ayuda del SOS: sin conexión; se ofrece llamar o enviar SMS.
  ///
  /// In es, this message translates to:
  /// **'No hay conexión. Llama o envía el mensaje ya preparado.'**
  String get incidentOfflineBody;

  /// Ayuda del SOS: quien pidió ayuda canceló el aviso (título).
  ///
  /// In es, this message translates to:
  /// **'Aviso cancelado'**
  String get incidentCancelledTitle;

  /// Ayuda del SOS: aviso cancelado por quien lo pidió.
  ///
  /// In es, this message translates to:
  /// **'Central fue avisada. Ya no compartimos tu ubicación.'**
  String get incidentCancelledBody;

  /// Ayuda del SOS: aviso abierto (título).
  ///
  /// In es, this message translates to:
  /// **'Avisamos a central'**
  String get incidentOpenTitle;

  /// Ayuda del SOS: aviso abierto (detalle).
  ///
  /// In es, this message translates to:
  /// **'Central fue avisada. Compartimos tu ubicación mientras dure el aviso.'**
  String get incidentOpenBody;

  /// Ayuda del SOS: central reconoció el aviso (título).
  ///
  /// In es, this message translates to:
  /// **'Central recibió tu aviso'**
  String get incidentAckTitle;

  /// Ayuda del SOS: central reconoció el aviso (detalle).
  ///
  /// In es, this message translates to:
  /// **'Una persona de central lo está atendiendo.'**
  String get incidentAckBody;

  /// Ayuda del SOS: central cerró el aviso (título).
  ///
  /// In es, this message translates to:
  /// **'Aviso cerrado'**
  String get incidentClosedTitle;

  /// Ayuda del SOS: central cerró el aviso (detalle).
  ///
  /// In es, this message translates to:
  /// **'Central cerró el aviso. Ya no compartimos tu ubicación.'**
  String get incidentClosedBody;

  /// Ayuda del SOS: se pidió cancelar y central verificará por llamada.
  ///
  /// In es, this message translates to:
  /// **'Central te llamará para verificar que estás bien. Ya no compartimos tu ubicación.'**
  String get incidentCancelRequestedBody;

  /// Título de la ayuda del SOS sin aviso y nombre del botón de ayuda (se anuncia «Ayuda SOS»).
  ///
  /// In es, this message translates to:
  /// **'Ayuda'**
  String get incidentHelp;

  /// Ayuda del SOS sin aviso: cómo avisar. SOS no se traduce.
  ///
  /// In es, this message translates to:
  /// **'Mantén pulsado SOS para avisar a central.'**
  String get incidentIdleBody;

  /// Título del diálogo para cancelar un SOS.
  ///
  /// In es, this message translates to:
  /// **'¿Fue una falsa alarma?'**
  String get incidentFalseAlarmQuestion;

  /// Diálogo para cancelar un SOS: qué pasa al cancelarlo.
  ///
  /// In es, this message translates to:
  /// **'Cancelaremos el aviso. Central lo verá igualmente y queda registrado.'**
  String get incidentFalseAlarmBody;

  /// Botón para cerrar el diálogo sin cancelar el SOS.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get incidentBack;

  /// Botón para confirmar que el SOS fue una falsa alarma.
  ///
  /// In es, this message translates to:
  /// **'Cancelar aviso'**
  String get incidentCancelAlert;

  /// Ayuda del SOS: veces que se envió el aviso (solo con 2 o más).
  ///
  /// In es, this message translates to:
  /// **'Aviso enviado {count} veces.'**
  String incidentSentTimes(int count);

  /// Botón para llamar a central desde la ayuda del SOS.
  ///
  /// In es, this message translates to:
  /// **'Llamar a central'**
  String get incidentCallDispatch;

  /// Botón para enviar el SMS preparado a central.
  ///
  /// In es, this message translates to:
  /// **'Enviar SMS a central'**
  String get incidentSmsDispatch;

  /// Botón para reintentar el aviso de SOS.
  ///
  /// In es, this message translates to:
  /// **'Reintentar el aviso'**
  String get incidentRetry;

  /// Nombre del botón SOS para volver a avisar (se anuncia «Avisar de nuevo SOS»).
  ///
  /// In es, this message translates to:
  /// **'Avisar de nuevo'**
  String get incidentAlertAgain;

  /// Bajo el botón SOS cuando ya hay un aviso.
  ///
  /// In es, this message translates to:
  /// **'Mantén pulsado para avisar de nuevo'**
  String get incidentHoldToAlertAgain;

  /// Botón para cancelar un SOS por falsa alarma.
  ///
  /// In es, this message translates to:
  /// **'Fue una falsa alarma'**
  String get incidentFalseAlarm;

  /// Diálogo de confirmación del SOS con lector de pantalla o teclado: título.
  ///
  /// In es, this message translates to:
  /// **'¿Avisar a central?'**
  String get incidentConfirmTitle;

  /// Diálogo de confirmación del SOS: qué recibe central.
  ///
  /// In es, this message translates to:
  /// **'Central recibirá tu aviso y tu ubicación mientras dure.'**
  String get incidentConfirmBody;

  /// Botón para no enviar el SOS.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get incidentConfirmCancel;

  /// Botón para confirmar el envío del SOS.
  ///
  /// In es, this message translates to:
  /// **'Avisar a central'**
  String get incidentConfirmSend;

  /// Etiqueta de lector de pantalla del botón SOS: su nombre seguido de SOS (SOS no se traduce).
  ///
  /// In es, this message translates to:
  /// **'{label} SOS'**
  String incidentSosSemantics(String label);

  /// Indicación de lector de pantalla del botón SOS.
  ///
  /// In es, this message translates to:
  /// **'Mantén pulsado dos segundos para avisar a central. Con lector de pantalla, toca dos veces y confirma.'**
  String get incidentSosHint;

  /// Botón de la pantalla del viaje con un SOS en curso.
  ///
  /// In es, this message translates to:
  /// **'Ayuda en curso'**
  String get incidentLive;

  /// Error del SOS sin conexión.
  ///
  /// In es, this message translates to:
  /// **'No pudimos avisar a central: sin conexión.'**
  String get incidentErrorOffline;

  /// Error del SOS fuera del viaje.
  ///
  /// In es, this message translates to:
  /// **'El botón de ayuda funciona durante el viaje.'**
  String get incidentErrorOutsideWindow;

  /// Error del SOS: demasiados avisos.
  ///
  /// In es, this message translates to:
  /// **'Ya enviaste varios avisos. Llama a central si lo necesitas.'**
  String get incidentErrorRateLimited;

  /// Error del SOS: la reserva ya no es de esta persona.
  ///
  /// In es, this message translates to:
  /// **'Este viaje ya no está a tu nombre.'**
  String get incidentErrorNotAllowed;

  /// Error genérico del SOS.
  ///
  /// In es, this message translates to:
  /// **'No pudimos avisar a central.'**
  String get incidentErrorGeneric;

  /// Título de la sección del perfil donde se elige el idioma de la app.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get languageTitle;

  /// Opción del selector de idioma: seguir el idioma del teléfono.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get languageSystem;

  /// Detalle bajo «Sistema»: qué idioma resulta del teléfono.
  ///
  /// In es, this message translates to:
  /// **'Usa el idioma del teléfono: {language}'**
  String languageSystemDetail(String language);

  /// Aviso si el idioma no se guardó en el servidor; la app ya cambió de idioma.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el idioma en tu cuenta. Se usará en este dispositivo.'**
  String get languageSaveError;

  /// Aviso sobre las páginas legales (términos, privacidad) cuando la app está en inglés o portugués: el texto legal sigue en español hasta que el abogado entregue las traducciones. En español no se muestra.
  ///
  /// In es, this message translates to:
  /// **'Este documento solo está disponible en español por ahora.'**
  String get legalSpanishOnlyNotice;

  /// Título de la bandeja de avisos y texto de ayuda de la campana.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsTitle;

  /// Botón de la bandeja para marcar todos los avisos como leídos.
  ///
  /// In es, this message translates to:
  /// **'Marcar todo como leído'**
  String get notificationsMarkAllRead;

  /// Bandeja de avisos vacía.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay notificaciones'**
  String get notificationsEmpty;

  /// Hora de un aviso de hace menos de un minuto.
  ///
  /// In es, this message translates to:
  /// **'Ahora'**
  String get notificationsNow;

  /// Hora de un aviso de hace menos de una hora: minutos transcurridos (abreviado «m»).
  ///
  /// In es, this message translates to:
  /// **'Hace {minutes}m'**
  String notificationsMinutesAgo(int minutes);

  /// Hora de un aviso de hace menos de un día: horas transcurridas (abreviado «h»).
  ///
  /// In es, this message translates to:
  /// **'Hace {hours}h'**
  String notificationsHoursAgo(int hours);

  /// Error de pago por un fallo del servidor; no culpa a la persona.
  ///
  /// In es, this message translates to:
  /// **'No pudimos completar el pago por un problema nuestro. Inténtalo de nuevo en unos minutos.'**
  String get paymentOurFault;

  /// Error: el método de pago elegido está desactivado.
  ///
  /// In es, this message translates to:
  /// **'Este método de pago no está disponible ahora. Elige otro o contacta con central.'**
  String get paymentMethodDisabled;

  /// Error: la reserva ya está pagada.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva ya está pagada.'**
  String get paymentAlreadyPaid;

  /// Error: la reserva ya no espera un pago.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva ya no admite pagos. Revisa su estado en Mis viajes.'**
  String get paymentNotAwaiting;

  /// Error: no se encontró la reserva (o no es de la persona).
  ///
  /// In es, this message translates to:
  /// **'No encontramos esta reserva.'**
  String get paymentBookingNotFound;

  /// Error: el número de operación tiene caracteres no permitidos. Los caracteres finales son literales.
  ///
  /// In es, this message translates to:
  /// **'Revisa el número de operación: usa solo letras, números, espacios y . _ / -'**
  String get paymentInvalidOperationNumber;

  /// Error del pago con tarjeta: la cuenta no tiene pagos habilitados (en minúscula, va dentro de otro mensaje).
  ///
  /// In es, this message translates to:
  /// **'tu cuenta aún no tiene pagos habilitados'**
  String get paymentAccountNotEnabled;

  /// Error del pago con tarjeta: no hubo respuesta del servidor de pagos (en minúscula).
  ///
  /// In es, this message translates to:
  /// **'no se pudo contactar con el servidor de pagos'**
  String get paymentServerUnreachable;

  /// Error al quitar una tarjeta que paga una reserva pendiente.
  ///
  /// In es, this message translates to:
  /// **'Esta tarjeta paga una reserva pendiente. Cancélala o espera a que termine antes de quitar la tarjeta.'**
  String get paymentCardInUse;

  /// Error al quitar una tarjeta guardada.
  ///
  /// In es, this message translates to:
  /// **'No pudimos quitar la tarjeta. Inténtalo de nuevo.'**
  String get paymentRemoveCardError;

  /// Error al cambiar la tarjeta predeterminada.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cambiar la tarjeta predeterminada. Inténtalo de nuevo.'**
  String get paymentSetDefaultError;

  /// Error al crear el perfil de pagos de la persona.
  ///
  /// In es, this message translates to:
  /// **'No pudimos preparar tu perfil de pagos. Inténtalo de nuevo.'**
  String get paymentProfileError;

  /// Error al cargar el estado del pago de una reserva.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar el pago de tu reserva. Revisa tu conexión.'**
  String get paymentLoadError;

  /// Error: el pago con tarjeta no se puede usar en este momento.
  ///
  /// In es, this message translates to:
  /// **'El pago con tarjeta no está disponible ahora. Elige otro método.'**
  String get paymentCardUnavailable;

  /// Error: el formulario de tarjeta no completó el pago.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar el pago con tarjeta. Revisa los datos e inténtalo de nuevo.'**
  String get paymentCardFailed;

  /// Aviso al agregar una tarjeta sin todos los datos.
  ///
  /// In es, this message translates to:
  /// **'Ingresa los datos completos de la tarjeta'**
  String get paymentCardIncomplete;

  /// Aviso tras guardar una tarjeta nueva.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta agregada exitosamente'**
  String get paymentCardAdded;

  /// Título de la pantalla para agregar una tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Agregar método de pago'**
  String get paymentAddMethodTitle;

  /// Etiqueta del botón de volver en las pantallas de tarjetas.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get paymentBack;

  /// Encabezado del formulario de la tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Datos de la tarjeta'**
  String get paymentCardDetails;

  /// Nota de seguridad bajo el formulario de tarjeta. Stripe y PCI DSS no se traducen.
  ///
  /// In es, this message translates to:
  /// **'Protegido por Stripe · Cumplimiento PCI DSS'**
  String get paymentAddCardSecure;

  /// Botón o acción para agregar una tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Agregar tarjeta'**
  String get paymentAddCard;

  /// Título de la pantalla de pago de una reserva.
  ///
  /// In es, this message translates to:
  /// **'Pago de tu reserva'**
  String get paymentBookingTitle;

  /// Botón para ir al detalle del viaje desde el pago.
  ///
  /// In es, this message translates to:
  /// **'Ver mi viaje'**
  String get paymentViewTrip;

  /// Estado vacío: la reserva no tiene pago pendiente.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva no tiene un pago pendiente.'**
  String get paymentNoPending;

  /// Título cuando central confirmó el pago.
  ///
  /// In es, this message translates to:
  /// **'Pago confirmado'**
  String get paymentConfirmedTitle;

  /// Mensaje tras confirmar el pago; sin plazos.
  ///
  /// In es, this message translates to:
  /// **'Ya buscamos a tu chófer. Te avisaremos cuando esté asignado.'**
  String get paymentConfirmedMessage;

  /// Título cuando venció el plazo para pagar.
  ///
  /// In es, this message translates to:
  /// **'El plazo para pagar terminó'**
  String get paymentExpiredTitle;

  /// Explicación de la reserva cancelada por falta de pago, con la referencia del pago.
  ///
  /// In es, this message translates to:
  /// **'La reserva se canceló porque no recibimos el pago a tiempo. Si ya habías pagado, contacta con central e indica la referencia {reference}.'**
  String paymentExpiredMessage(String reference);

  /// Botón para empezar una reserva nueva.
  ///
  /// In es, this message translates to:
  /// **'Hacer una nueva reserva'**
  String get paymentNewBooking;

  /// Título cuando la reserva ya no acepta pagos (devuelta, cancelada…).
  ///
  /// In es, this message translates to:
  /// **'Esta reserva ya no admite pagos'**
  String get paymentClosedTitle;

  /// Mensaje bajo «Esta reserva ya no admite pagos».
  ///
  /// In es, this message translates to:
  /// **'Consulta el detalle y el comprobante en tu viaje.'**
  String get paymentClosedMessage;

  /// Aviso cuando central no pudo confirmar el pago avisado.
  ///
  /// In es, this message translates to:
  /// **'No pudimos confirmar tu pago. Revisa los datos y vuelve a avisarnos, o contacta con central.'**
  String get paymentRejected;

  /// Aviso cuando ningún método de pago se puede usar en este dispositivo.
  ///
  /// In es, this message translates to:
  /// **'Ahora mismo no podemos recibir el pago desde aquí. Contacta con central para completar tu reserva.'**
  String get paymentNoMethods;

  /// Botón para volver a elegir el método de pago.
  ///
  /// In es, this message translates to:
  /// **'Cambiar método de pago'**
  String get paymentChangeMethod;

  /// Nota al pie de la pantalla de pago.
  ///
  /// In es, this message translates to:
  /// **'Buscamos chófer cuando el pago está confirmado.'**
  String get paymentSearchAfterConfirm;

  /// Rótulo en mayúsculas sobre el importe a pagar.
  ///
  /// In es, this message translates to:
  /// **'IMPORTE A PAGAR'**
  String get paymentAmountDueEyebrow;

  /// Etiqueta de la referencia del pago (código a escribir en el concepto).
  ///
  /// In es, this message translates to:
  /// **'Referencia'**
  String get paymentReference;

  /// El plazo para pagar ya pasó; {time} es la hora.
  ///
  /// In es, this message translates to:
  /// **'El plazo para pagar terminó a las {time}.'**
  String paymentDeadlinePassed(String time);

  /// Tiempo que queda para pagar; {span} es «24 min» o «1 h 5 min», {time} la hora límite.
  ///
  /// In es, this message translates to:
  /// **'Quedan {span} para pagar (hasta las {time}).'**
  String paymentTimeLeft(String span, String time);

  /// Duración solo con minutos, dentro de «Quedan … para pagar».
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String paymentSpanMinutes(int minutes);

  /// Duración en horas exactas dentro de «Quedan … para pagar».
  ///
  /// In es, this message translates to:
  /// **'{hours} h'**
  String paymentSpanHours(int hours);

  /// Duración en horas y minutos dentro de «Quedan … para pagar».
  ///
  /// In es, this message translates to:
  /// **'{hours} h {minutes} min'**
  String paymentSpanHoursMinutes(int hours, int minutes);

  /// Etiqueta del botón de copiar; {label} es «referencia» o «cuenta», en minúscula.
  ///
  /// In es, this message translates to:
  /// **'Copiar {label}'**
  String paymentCopy(String label);

  /// Aviso tras copiar; {label} es «Referencia» o «Cuenta» (femenino).
  ///
  /// In es, this message translates to:
  /// **'{label} copiada.'**
  String paymentCopied(String label);

  /// Método de pago: QR o transferencia bancaria.
  ///
  /// In es, this message translates to:
  /// **'QR o transferencia bancaria'**
  String get paymentMethodManualQr;

  /// Método de pago: tarjeta (también cuando no se conoce la marca).
  ///
  /// In es, this message translates to:
  /// **'Tarjeta'**
  String get paymentMethodCard;

  /// Rótulo en mayúsculas sobre la lista de métodos.
  ///
  /// In es, this message translates to:
  /// **'¿CÓMO QUIERES PAGAR?'**
  String get paymentHowToPay;

  /// Rótulo en mayúsculas sobre los datos de cobro.
  ///
  /// In es, this message translates to:
  /// **'PAGA POR QR O TRANSFERENCIA'**
  String get paymentManualEyebrow;

  /// Etiqueta del lector de pantalla para la imagen del QR.
  ///
  /// In es, this message translates to:
  /// **'Código QR para pagar'**
  String get paymentQrLabel;

  /// Aviso si la imagen del QR no carga.
  ///
  /// In es, this message translates to:
  /// **'No pudimos mostrar el QR. Usa los datos de la cuenta.'**
  String get paymentQrError;

  /// Etiqueta: titular de la cuenta de cobro (el valor lo escribe el admin y no se traduce).
  ///
  /// In es, this message translates to:
  /// **'Titular'**
  String get paymentHolder;

  /// Etiqueta: banco de la cuenta de cobro.
  ///
  /// In es, this message translates to:
  /// **'Banco'**
  String get paymentBank;

  /// Etiqueta: tipo de cuenta de cobro.
  ///
  /// In es, this message translates to:
  /// **'Tipo de cuenta'**
  String get paymentAccountType;

  /// Etiqueta: número de cuenta de cobro (femenino en español y portugués: «Cuenta copiada»).
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get paymentAccount;

  /// Instrucción del pago manual: importe exacto y referencia para el concepto.
  ///
  /// In es, this message translates to:
  /// **'Paga exactamente {amount} y escribe la referencia {reference} en el concepto o glosa.'**
  String paymentPayExactly(String amount, String reference);

  /// Etiqueta del campo del número de operación del banco.
  ///
  /// In es, this message translates to:
  /// **'Número de operación (opcional)'**
  String get paymentOperationLabel;

  /// Ayuda del campo del número de operación.
  ///
  /// In es, this message translates to:
  /// **'El que aparece en tu comprobante'**
  String get paymentOperationHint;

  /// Botón para avisar que ya se hizo el pago manual.
  ///
  /// In es, this message translates to:
  /// **'Ya pagué'**
  String get paymentIPaid;

  /// Estado: el pago avisado espera que central lo confirme.
  ///
  /// In es, this message translates to:
  /// **'Esperando confirmación'**
  String get paymentWaitingTitle;

  /// Explicación mientras central revisa el pago.
  ///
  /// In es, this message translates to:
  /// **'Central está revisando tu pago. Te avisaremos aquí y en tus notificaciones cuando lo confirme.'**
  String get paymentWaitingMessage;

  /// Número de operación que escribió la persona.
  ///
  /// In es, this message translates to:
  /// **'Número de operación: {number}'**
  String paymentOperationNumber(String number);

  /// Estado tras completar el formulario de tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Confirmando tu pago…'**
  String get paymentConfirming;

  /// Botón para abrir el pago con tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Pagar con tarjeta'**
  String get paymentPayWithCard;

  /// Botón para reintentar el pago con tarjeta tras un error.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get paymentRetry;

  /// Aviso en la web: las tarjetas se agregan desde la app del teléfono.
  ///
  /// In es, this message translates to:
  /// **'Agrega tus tarjetas desde la app de Luxelane en tu teléfono.'**
  String get paymentAddCardsOnPhone;

  /// Título del diálogo para quitar una tarjeta.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar esta tarjeta?'**
  String get paymentRemoveCardTitle;

  /// Texto del diálogo para quitar una tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Dejará de estar disponible para tus próximas reservas.'**
  String get paymentRemoveCardMessage;

  /// Botón para cerrar el diálogo sin quitar la tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get paymentCancel;

  /// Botón del diálogo que quita la tarjeta.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get paymentRemove;

  /// Título de la pantalla de métodos de pago del perfil.
  ///
  /// In es, this message translates to:
  /// **'Métodos de pago'**
  String get paymentMethodsTitle;

  /// Estado vacío cuando no hay tarjetas que guardar: cada reserva se paga en su pantalla de pago.
  ///
  /// In es, this message translates to:
  /// **'Cada reserva se paga en su paso de pago.'**
  String get paymentPerBooking;

  /// Encabezado de la lista de tarjetas.
  ///
  /// In es, this message translates to:
  /// **'Tarjetas guardadas'**
  String get paymentSavedCards;

  /// Pie de la lista de tarjetas.
  ///
  /// In es, this message translates to:
  /// **'Toca una tarjeta para usarla por defecto al reservar.'**
  String get paymentSetDefaultHint;

  /// Nota de seguridad bajo la lista de tarjetas. Stripe no se traduce.
  ///
  /// In es, this message translates to:
  /// **'Pagos cifrados y protegidos por Stripe'**
  String get paymentEncrypted;

  /// Estado vacío de la lista de tarjetas.
  ///
  /// In es, this message translates to:
  /// **'Paga sin pensarlo.'**
  String get paymentEmptyCards;

  /// Detalle de la tarjeta predeterminada; {expiry} es «MM/AA».
  ///
  /// In es, this message translates to:
  /// **'Predeterminada · vence {expiry}'**
  String paymentCardDefaultExpires(String expiry);

  /// Detalle de una tarjeta; {expiry} es «MM/AA».
  ///
  /// In es, this message translates to:
  /// **'Vence {expiry}'**
  String paymentCardExpires(String expiry);

  /// Etiqueta del botón para quitar una tarjeta de la lista.
  ///
  /// In es, this message translates to:
  /// **'Quitar tarjeta'**
  String get paymentRemoveCard;

  /// Método en el comprobante: QR o transferencia.
  ///
  /// In es, this message translates to:
  /// **'QR o transferencia'**
  String get paymentReceiptMethodManual;

  /// Título de la tarjeta del viaje cuando falta pagar.
  ///
  /// In es, this message translates to:
  /// **'Pago pendiente'**
  String get paymentPendingTitle;

  /// La persona avisó que pagó; {amount} es el importe con «Bs».
  ///
  /// In es, this message translates to:
  /// **'Avisaste que pagaste {amount}. Central lo está revisando.'**
  String paymentReportedMessage(String amount);

  /// Falta pagar; {amount} es el importe con «Bs».
  ///
  /// In es, this message translates to:
  /// **'Paga {amount} para que busquemos a tu chófer.'**
  String paymentPendingMessage(String amount);

  /// Botón para abrir el pago ya avisado.
  ///
  /// In es, this message translates to:
  /// **'Ver el pago'**
  String get paymentViewPayment;

  /// Botón para abrir la pantalla de pago.
  ///
  /// In es, this message translates to:
  /// **'Pagar ahora'**
  String get paymentPayNow;

  /// Título del comprobante de pago.
  ///
  /// In es, this message translates to:
  /// **'Comprobante de pago'**
  String get paymentReceiptTitle;

  /// Etiqueta del botón que pliega el comprobante.
  ///
  /// In es, this message translates to:
  /// **'Ocultar comprobante'**
  String get paymentReceiptHide;

  /// Etiqueta del botón que despliega el comprobante.
  ///
  /// In es, this message translates to:
  /// **'Ver comprobante'**
  String get paymentReceiptShow;

  /// Aclaración del comprobante: no es una factura.
  ///
  /// In es, this message translates to:
  /// **'Este comprobante no es una factura.'**
  String get paymentReceiptNotInvoice;

  /// Fila del comprobante: importe pagado.
  ///
  /// In es, this message translates to:
  /// **'Pagado'**
  String get paymentReceiptPaid;

  /// Fila del comprobante: fecha del pago.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get paymentReceiptDate;

  /// Fila del comprobante: método de pago.
  ///
  /// In es, this message translates to:
  /// **'Método'**
  String get paymentReceiptMethod;

  /// Fila del comprobante: retención por cancelar.
  ///
  /// In es, this message translates to:
  /// **'Retención por cancelación'**
  String get paymentReceiptRetained;

  /// Fila del comprobante: devolución aún no registrada.
  ///
  /// In es, this message translates to:
  /// **'Devolución pendiente'**
  String get paymentReceiptRefundPending;

  /// Nota bajo la devolución pendiente; sin plazos.
  ///
  /// In es, this message translates to:
  /// **'Central la registrará y te avisaremos cuando quede hecha.'**
  String get paymentReceiptRefundPendingNote;

  /// Fila del comprobante: importe devuelto.
  ///
  /// In es, this message translates to:
  /// **'Devuelto'**
  String get paymentReceiptRefunded;

  /// Nota bajo el importe devuelto.
  ///
  /// In es, this message translates to:
  /// **'Te devolvemos el dinero al método con el que pagaste.'**
  String get paymentReceiptRefundedNote;

  /// Fila del comprobante: saldo que falta pagar.
  ///
  /// In es, this message translates to:
  /// **'Saldo pendiente'**
  String get paymentReceiptBalanceDue;

  /// Nota bajo el saldo pendiente; sin promesas de contacto.
  ///
  /// In es, this message translates to:
  /// **'El importe final del viaje fue mayor que lo pagado.'**
  String get paymentReceiptBalanceNote;

  /// Opción «sin preferencia» de temperatura, conversación y música.
  ///
  /// In es, this message translates to:
  /// **'Sin preferencia'**
  String get prefsNoPreference;

  /// Título: idiomas que el pasajero prefiere en su chófer.
  ///
  /// In es, this message translates to:
  /// **'Idiomas del chófer'**
  String get prefsLanguagesTitle;

  /// Idioma del chófer: español.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get prefsLanguageEs;

  /// Idioma del chófer: inglés.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get prefsLanguageEn;

  /// Idioma del chófer: portugués.
  ///
  /// In es, this message translates to:
  /// **'Portugués'**
  String get prefsLanguagePt;

  /// Título: temperatura de la cabina.
  ///
  /// In es, this message translates to:
  /// **'Temperatura'**
  String get prefsTemperatureTitle;

  /// Temperatura de la cabina: fresca.
  ///
  /// In es, this message translates to:
  /// **'Fresca'**
  String get prefsTemperatureCool;

  /// Temperatura de la cabina: templada.
  ///
  /// In es, this message translates to:
  /// **'Templada'**
  String get prefsTemperatureMild;

  /// Título: si prefiere conversar o ir en silencio.
  ///
  /// In es, this message translates to:
  /// **'Conversación'**
  String get prefsConversationTitle;

  /// Conversación: le gusta conversar.
  ///
  /// In es, this message translates to:
  /// **'Me gusta conversar'**
  String get prefsConversationChatty;

  /// Conversación: prefiere silencio.
  ///
  /// In es, this message translates to:
  /// **'Prefiero silencio'**
  String get prefsConversationQuiet;

  /// Título: estilo de música.
  ///
  /// In es, this message translates to:
  /// **'Música'**
  String get prefsMusicTitle;

  /// Estilo de música genérico (sin artistas ni marcas).
  ///
  /// In es, this message translates to:
  /// **'Clásica'**
  String get prefsMusicClassical;

  /// Estilo de música genérico (sin artistas ni marcas).
  ///
  /// In es, this message translates to:
  /// **'Jazz'**
  String get prefsMusicJazz;

  /// Estilo de música genérico (sin artistas ni marcas).
  ///
  /// In es, this message translates to:
  /// **'Instrumental'**
  String get prefsMusicInstrumental;

  /// Estilo de música genérico (sin artistas ni marcas).
  ///
  /// In es, this message translates to:
  /// **'Pop'**
  String get prefsMusicPop;

  /// Estilo de música genérico (sin artistas ni marcas).
  ///
  /// In es, this message translates to:
  /// **'Rock'**
  String get prefsMusicRock;

  /// Estilo de música genérico (sin artistas ni marcas).
  ///
  /// In es, this message translates to:
  /// **'Latina'**
  String get prefsMusicLatin;

  /// Estilo de música genérico (sin artistas ni marcas).
  ///
  /// In es, this message translates to:
  /// **'Electrónica'**
  String get prefsMusicElectronic;

  /// Estilo de música genérico (sin artistas ni marcas).
  ///
  /// In es, this message translates to:
  /// **'Folclore'**
  String get prefsMusicFolk;

  /// Estilo de música genérico (sin artistas ni marcas).
  ///
  /// In es, this message translates to:
  /// **'Sin música'**
  String get prefsMusicNone;

  /// Título: enlace a una lista de música del pasajero (opcional).
  ///
  /// In es, this message translates to:
  /// **'Lista de música'**
  String get prefsPlaylistTitle;

  /// Título: necesidades prácticas para el viaje.
  ///
  /// In es, this message translates to:
  /// **'Necesidades'**
  String get prefsNeedsTitle;

  /// Necesidad práctica (lista cerrada). Texto neutro.
  ///
  /// In es, this message translates to:
  /// **'Equipaje extra'**
  String get prefsNeedExtraLuggage;

  /// Necesidad práctica (lista cerrada). Texto neutro.
  ///
  /// In es, this message translates to:
  /// **'Ayuda con el equipaje'**
  String get prefsNeedLuggageAssistance;

  /// Necesidad práctica (lista cerrada). Texto neutro.
  ///
  /// In es, this message translates to:
  /// **'Silla infantil'**
  String get prefsNeedChildSeat;

  /// Necesidad práctica (lista cerrada). Texto neutro.
  ///
  /// In es, this message translates to:
  /// **'Alzador infantil'**
  String get prefsNeedBoosterSeat;

  /// Necesidad práctica (lista cerrada). Texto neutro.
  ///
  /// In es, this message translates to:
  /// **'Asistencia para subir'**
  String get prefsNeedBoardingAssistance;

  /// Necesidad práctica (lista cerrada). Texto neutro.
  ///
  /// In es, this message translates to:
  /// **'Silla de ruedas plegable'**
  String get prefsNeedFoldingWheelchair;

  /// Necesidad práctica (lista cerrada). Texto neutro.
  ///
  /// In es, this message translates to:
  /// **'Mascota en transportín'**
  String get prefsNeedPetInCarrier;

  /// Aviso bajo las necesidades que pueden ser personales (asistencia para subir, silla de ruedas).
  ///
  /// In es, this message translates to:
  /// **'Solo tu chófer asignado lo verá.'**
  String get prefsNeedPrivateHint;

  /// Título: nota libre para el chófer (hasta 200 caracteres).
  ///
  /// In es, this message translates to:
  /// **'Nota para el chófer'**
  String get prefsNoteTitle;

  /// Advertencia bajo la nota: no escribir datos sensibles.
  ///
  /// In es, this message translates to:
  /// **'No escribas datos sensibles: claves, tarjetas ni datos de salud.'**
  String get prefsNoteWarning;

  /// Texto sobrio bajo las preferencias: no promete que se cumplan.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer verá estas preferencias.'**
  String get prefsDriverWillSee;

  /// Título de la tarjeta del chófer con las preferencias del pasajero.
  ///
  /// In es, this message translates to:
  /// **'Preferencias del pasajero'**
  String get prefsCardTitle;

  /// Botón del chófer para abrir la lista de música del pasajero.
  ///
  /// In es, this message translates to:
  /// **'Abrir lista'**
  String get prefsOpenPlaylist;

  /// Título del aviso antes de abrir la lista.
  ///
  /// In es, this message translates to:
  /// **'Abrir fuera de la app'**
  String get prefsOpenPlaylistTitle;

  /// Aviso antes de abrir la lista: sale de la app.
  ///
  /// In es, this message translates to:
  /// **'La lista se abrirá fuera de Luxelane, en el navegador o en otra aplicación.'**
  String get prefsOpenPlaylistBody;

  /// Botón para confirmar que se abre la lista.
  ///
  /// In es, this message translates to:
  /// **'Abrir'**
  String get prefsOpenPlaylistConfirm;

  /// Botón para cancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get prefsCancel;

  /// Error si no se pudo abrir la lista.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la lista.'**
  String get prefsOpenPlaylistError;

  /// Resumen corto en la solicitud abierta: idiomas que prefiere el pasajero.
  ///
  /// In es, this message translates to:
  /// **'Idiomas: {languages}'**
  String prefsLanguagesSummary(String languages);

  /// Error al guardar: la lista no es https o su servicio no está permitido.
  ///
  /// In es, this message translates to:
  /// **'Ese enlace de lista no se puede usar. Revisa que empiece por https y sea de un servicio admitido.'**
  String get prefsErrorPlaylist;

  /// Error al guardar: la nota es demasiado larga o lleva un enlace.
  ///
  /// In es, this message translates to:
  /// **'Revisa la nota: hasta 200 caracteres y sin enlaces.'**
  String get prefsErrorNote;

  /// Confirmación sobria al guardar las preferencias del perfil.
  ///
  /// In es, this message translates to:
  /// **'Preferencias guardadas.'**
  String get prefsSaved;

  /// Título de la pantalla de preferencias del perfil.
  ///
  /// In es, this message translates to:
  /// **'Preferencias'**
  String get prefsScreenTitle;

  /// Estado vacío de la pantalla de preferencias: aún no hay ninguna.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes preferencias. Añade las que quieras que tu chófer conozca.'**
  String get prefsEmpty;

  /// Subtítulo de la fila del perfil cuando no hay preferencias.
  ///
  /// In es, this message translates to:
  /// **'Sin preferencias todavía'**
  String get prefsEmptyShort;

  /// Botón para guardar las preferencias del perfil.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get prefsSave;

  /// Ayuda bajo el campo de la lista de música.
  ///
  /// In es, this message translates to:
  /// **'Pega un enlace https. Se abre siempre fuera de la app.'**
  String get prefsPlaylistHelp;

  /// Error del campo de la lista: el enlace no empieza por https.
  ///
  /// In es, this message translates to:
  /// **'El enlace debe empezar por https://'**
  String get prefsPlaylistInvalid;

  /// Ejemplo dentro del campo de la nota para el chófer.
  ///
  /// In es, this message translates to:
  /// **'Por ejemplo, dónde esperarte'**
  String get prefsNoteHint;

  /// Reserva: título del paso opcional con las preferencias de este viaje.
  ///
  /// In es, this message translates to:
  /// **'Preferencias de este viaje'**
  String get prefsTripTitle;

  /// Reserva: las preferencias mostradas son las del perfil.
  ///
  /// In es, this message translates to:
  /// **'Las de tu perfil.'**
  String get prefsTripFromProfile;

  /// Reserva: las preferencias se cambiaron solo para este viaje.
  ///
  /// In es, this message translates to:
  /// **'Cambiadas solo para este viaje.'**
  String get prefsTripChanged;

  /// Reserva: botón para cambiar las preferencias de este viaje.
  ///
  /// In es, this message translates to:
  /// **'Cambiar para este viaje'**
  String get prefsTripEdit;

  /// Reserva: cerrar las preferencias de este viaje sin cambiar nada.
  ///
  /// In es, this message translates to:
  /// **'Omitir'**
  String get prefsTripSkip;

  /// Reserva: volver a las preferencias del perfil.
  ///
  /// In es, this message translates to:
  /// **'Usar las de mi perfil'**
  String get prefsTripReset;

  /// Reserva: botón para usar las preferencias elegidas en este viaje.
  ///
  /// In es, this message translates to:
  /// **'Usar en este viaje'**
  String get prefsTripApply;

  /// Reserva: no hay preferencias para este viaje.
  ///
  /// In es, this message translates to:
  /// **'Sin preferencias para este viaje.'**
  String get prefsTripEmpty;

  /// Aviso de error si no se guardaron los cambios del perfil.
  ///
  /// In es, this message translates to:
  /// **'No pudimos guardar los cambios. Inténtalo de nuevo.'**
  String get profileSaveError;

  /// Aviso tras guardar el perfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado'**
  String get profileUpdated;

  /// Título de la pantalla de perfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// Botón de la barra superior para editar el perfil.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get profileEdit;

  /// Encabezado de la sección de licencia y vehículo del chófer.
  ///
  /// In es, this message translates to:
  /// **'Licencia y vehículo'**
  String get profileDriverDocuments;

  /// Encabezado de la sección de la cuenta.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get profileAccount;

  /// Fila de la cuenta: correo electrónico.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get profileEmail;

  /// Fila de la cuenta y campo del formulario: teléfono.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get profilePhone;

  /// Subtítulo de la fila del teléfono si aún no hay uno.
  ///
  /// In es, this message translates to:
  /// **'Añádelo para tu chófer'**
  String get profilePhoneMissing;

  /// Fila que abre los métodos de pago.
  ///
  /// In es, this message translates to:
  /// **'Métodos de pago'**
  String get profilePaymentMethods;

  /// Fila de la verificación en dos pasos (chóferes y admin).
  ///
  /// In es, this message translates to:
  /// **'Verificación en dos pasos'**
  String get profileTwoStep;

  /// Subtítulo de la verificación en dos pasos.
  ///
  /// In es, this message translates to:
  /// **'App autenticadora'**
  String get profileAuthenticatorApp;

  /// Encabezado de la sección legal.
  ///
  /// In es, this message translates to:
  /// **'Legal'**
  String get profileLegal;

  /// Fila que abre los términos y condiciones.
  ///
  /// In es, this message translates to:
  /// **'Términos y condiciones'**
  String get profileTerms;

  /// Fila que abre la política de privacidad.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get profilePrivacy;

  /// Botón para cerrar sesión.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get profileSignOut;

  /// Botón para eliminar la cuenta.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get profileDeleteAccount;

  /// Aviso tras eliminar la cuenta.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta fue eliminada.'**
  String get profileAccountDeleted;

  /// Título del diálogo para confirmar la eliminación de la cuenta.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar tu cuenta?'**
  String get profileDeleteTitle;

  /// Texto del diálogo de eliminar cuenta (dos párrafos).
  ///
  /// In es, this message translates to:
  /// **'Borraremos tu perfil, tus tarjetas guardadas y tus avisos, y no podrás volver a entrar con esta cuenta. Conservamos el registro de viajes y pagos que exige la ley.\n\nEsta acción no se puede deshacer.'**
  String get profileDeleteBody;

  /// Botón para cancelar un diálogo del perfil.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get profileCancel;

  /// Botón que confirma la eliminación de la cuenta.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get profileDelete;

  /// Título del formulario de edición y etiqueta de accesibilidad de la cabecera.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get profileEditTitle;

  /// Campo del formulario: nombre.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get profileName;

  /// Error de validación: campo obligatorio.
  ///
  /// In es, this message translates to:
  /// **'Requerido'**
  String get profileRequired;

  /// Error de validación del teléfono.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer lo necesita para contactarte'**
  String get profilePhoneInvalid;

  /// Botón para guardar el formulario del perfil.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get profileSaveChanges;

  /// Rol en la cabecera del perfil: administrador.
  ///
  /// In es, this message translates to:
  /// **'Administración'**
  String get profileRoleAdmin;

  /// Rol en la cabecera del perfil: chófer.
  ///
  /// In es, this message translates to:
  /// **'Chófer Luxelane'**
  String get profileRoleDriver;

  /// Rol en la cabecera del perfil del pasajero: año de alta.
  ///
  /// In es, this message translates to:
  /// **'Miembro desde {year}'**
  String profileMemberSince(int year);

  /// Número de viajes en la cabecera del perfil.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{{count} viaje} other{{count} viajes}}'**
  String profileRides(int count);

  /// Título del diálogo para cambiar el color del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Color del vehículo'**
  String get profileVehicleColorTitle;

  /// Campo y fila: color del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Color'**
  String get profileColor;

  /// Botón para guardar el color del vehículo.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get profileSave;

  /// Etiqueta de accesibilidad del candado: dato bloqueado.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado'**
  String get profileLocked;

  /// Fila de la licencia de conducir del chófer.
  ///
  /// In es, this message translates to:
  /// **'Licencia'**
  String get profileLicence;

  /// Subtítulo de la licencia: número y vencimiento (mes/año).
  ///
  /// In es, this message translates to:
  /// **'{number} · vence {expiry}'**
  String profileLicenceDetail(String number, String expiry);

  /// Subtítulo del vehículo: clase y placa.
  ///
  /// In es, this message translates to:
  /// **'{vehicleClass} · placa {plate}'**
  String profileVehicleDetail(String vehicleClass, String plate);

  /// Fila del perfil del pasajero que abre sus preferencias para el chófer.
  ///
  /// In es, this message translates to:
  /// **'Preferencias para tu chófer'**
  String get profilePreferencesEntry;

  /// Pantalla del viaje: la reserva no existe o no es de esta cuenta.
  ///
  /// In es, this message translates to:
  /// **'No encontramos esta reserva en tu cuenta.'**
  String get rideLoadNotFound;

  /// Pantalla del viaje: la reserva no cargó por falta de conexión.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu reserva. Revisa tu conexión.'**
  String get rideLoadOffline;

  /// Pantalla del viaje: la reserva no cargó por otro motivo.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu reserva. Inténtalo de nuevo.'**
  String get rideLoadFailed;

  /// Titular mientras la reserva busca chófer.
  ///
  /// In es, this message translates to:
  /// **'Estamos asignando a tu chófer. Te avisaremos en cuanto esté confirmado.'**
  String get ridePendingSearching;

  /// Titular cuando el chófer anterior liberó el viaje y hay número de central para llamar.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer anterior no pudo hacer el viaje. Estamos buscando otro y central ya está avisada. Si lo necesitas, llama a central.'**
  String get ridePendingReleasedCall;

  /// Titular cuando el chófer anterior liberó el viaje, sin número de central.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer anterior no pudo hacer el viaje. Estamos buscando otro y central ya está avisada.'**
  String get ridePendingReleased;

  /// Titular cuando pasó la hora de recogida sin chófer y hay número de central.
  ///
  /// In es, this message translates to:
  /// **'Ya pasó la hora de recogida y aún no hay chófer asignado. Llama a central o cancela la reserva.'**
  String get ridePendingPickupPassedCall;

  /// Titular cuando pasó la hora de recogida sin chófer, sin número de central.
  ///
  /// In es, this message translates to:
  /// **'Ya pasó la hora de recogida y aún no hay chófer asignado. Puedes esperar o cancelar la reserva.'**
  String get ridePendingPickupPassed;

  /// Mensaje que el titular comparte con su invitado con el código de recogida.
  ///
  /// In es, this message translates to:
  /// **'Tu código de recogida es {code}. Dáselo a tu chófer al subir; sin él no puede iniciar el viaje.'**
  String rideCodeShareText(String code);

  /// Etiqueta de lector de pantalla mientras carga el código de recogida.
  ///
  /// In es, this message translates to:
  /// **'Cargando tu código de recogida'**
  String get rideCodeLoading;

  /// Encabezado en mayúsculas de la tarjeta del código de recogida.
  ///
  /// In es, this message translates to:
  /// **'CÓDIGO DE RECOGIDA'**
  String get rideCodeTitle;

  /// Etiqueta de lector de pantalla del código, con los dígitos separados por espacios.
  ///
  /// In es, this message translates to:
  /// **'Código de recogida {digits}'**
  String rideCodeSemantics(String digits);

  /// Bajo el código de recogida: qué hacer con él.
  ///
  /// In es, this message translates to:
  /// **'Dáselo a tu chófer al subir. Sin él no puede iniciar el viaje.'**
  String get rideCodeHint;

  /// Bajo el código, si la reserva es para un invitado.
  ///
  /// In es, this message translates to:
  /// **'Compártelo con {guest}: se lo dará al chófer al subir.'**
  String rideCodeGuestHint(String guest);

  /// Botón para compartir el código de recogida con el invitado.
  ///
  /// In es, this message translates to:
  /// **'Compartir código'**
  String get rideCodeShare;

  /// Botón para volver a pedir el código de recogida.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get rideRetry;

  /// Aviso tras cancelar la reserva.
  ///
  /// In es, this message translates to:
  /// **'Reserva cancelada'**
  String get rideCancelledSnack;

  /// Aviso si la retención por cancelar cambió dos veces seguidas.
  ///
  /// In es, this message translates to:
  /// **'La retención cambió de nuevo. Inténtalo otra vez.'**
  String get rideCancelFeeChangedAgain;

  /// Título del diálogo y botón para cancelar la reserva.
  ///
  /// In es, this message translates to:
  /// **'Cancelar reserva'**
  String get rideCancelBooking;

  /// Diálogo de cancelación: cuánto se retiene si cancela ahora.
  ///
  /// In es, this message translates to:
  /// **'Según la política de cancelación, si cancelas ahora se retienen {amount} de lo que pagaste.'**
  String rideCancelFee(String amount);

  /// Diálogo de cancelación cuando la retención cambió mientras decidía.
  ///
  /// In es, this message translates to:
  /// **'La retención cambió. Según la política de cancelación, si cancelas ahora se retienen {amount} de lo que pagaste.'**
  String rideCancelFeeChanged(String amount);

  /// Diálogo de cancelación: importe pendiente de devolución. Sin plazos ni promesas.
  ///
  /// In es, this message translates to:
  /// **'{amount} quedan pendientes de devolución. Te avisaremos cuando central la registre.'**
  String rideCancelRefund(String amount);

  /// Encabezado de la lista de motivos de cancelación.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get rideCancelReasonLabel;

  /// Motivo de cancelación del pasajero.
  ///
  /// In es, this message translates to:
  /// **'Cambié de planes'**
  String get rideCancelReasonChangedPlans;

  /// Motivo de cancelación del pasajero.
  ///
  /// In es, this message translates to:
  /// **'Encontré otro transporte'**
  String get rideCancelReasonOtherTransport;

  /// Motivo de cancelación del pasajero.
  ///
  /// In es, this message translates to:
  /// **'El chófer tarda demasiado'**
  String get rideCancelReasonDriverLate;

  /// Motivo de cancelación del pasajero.
  ///
  /// In es, this message translates to:
  /// **'Otro motivo'**
  String get rideCancelReasonOther;

  /// Botón para cerrar el diálogo sin cancelar.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get rideBack;

  /// Botón para confirmar la cancelación cuando hay retención.
  ///
  /// In es, this message translates to:
  /// **'Cancelar con retención'**
  String get rideCancelWithFee;

  /// Titular de una reserva cancelada.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva fue cancelada.'**
  String get rideCancelledMessage;

  /// Titular de una reserva cancelada con retención.
  ///
  /// In es, this message translates to:
  /// **'Esta reserva fue cancelada. Retención por cancelación: {amount}.'**
  String rideCancelledWithFee(String amount);

  /// Titular mientras carga la reserva.
  ///
  /// In es, this message translates to:
  /// **'Cargando tu reserva…'**
  String get rideStatusLoading;

  /// Titular de una reserva sin pago confirmado.
  ///
  /// In es, this message translates to:
  /// **'Tu reserva espera el pago. Buscamos chófer cuando esté confirmado.'**
  String get rideStatusAwaitingPayment;

  /// Titular con chófer asignado, antes de que salga.
  ///
  /// In es, this message translates to:
  /// **'Tu reserva está confirmada. Te avisaremos cuando tu chófer salga hacia ti.'**
  String get rideStatusConfirmed;

  /// Titular mientras el chófer va a la recogida.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer va de camino al punto de recogida.'**
  String get rideStatusDriverArriving;

  /// Titular cuando el chófer llegó y espera.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer ha llegado y te espera. Tómate tu tiempo.'**
  String get rideStatusDriverArrived;

  /// Titular tras verificar el código de recogida.
  ///
  /// In es, this message translates to:
  /// **'Código verificado. Tu viaje empieza en un momento.'**
  String get rideStatusVerified;

  /// Titular durante el trayecto.
  ///
  /// In es, this message translates to:
  /// **'Disfruta del trayecto. Llegarás a tu destino en breve.'**
  String get rideStatusInProgress;

  /// Titular al terminar el viaje.
  ///
  /// In es, this message translates to:
  /// **'Has llegado. Gracias por viajar con Luxelane.'**
  String get rideStatusCompleted;

  /// Titular cuando el chófer marcó que el pasajero no se presentó.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer no te encontró en el punto de recogida. Central fue avisada.'**
  String get rideStatusNoShow;

  /// Nombre del chófer en el diálogo de valoración si no se conoce (en minúscula en español).
  ///
  /// In es, this message translates to:
  /// **'tu chófer'**
  String get rideYourDriverLower;

  /// Nombre del chófer en su tarjeta si no se conoce.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer'**
  String get rideYourDriver;

  /// Aviso tras enviar la valoración del viaje.
  ///
  /// In es, this message translates to:
  /// **'¡Gracias por tu valoración!'**
  String get rideRatingThanks;

  /// Botón para valorar un viaje completado.
  ///
  /// In es, this message translates to:
  /// **'Calificar viaje'**
  String get rideRateTrip;

  /// Botón para llamar al chófer durante el viaje.
  ///
  /// In es, this message translates to:
  /// **'Llamar a tu chófer'**
  String get rideCallDriver;

  /// Botón de cancelar mientras se procesa la cancelación.
  ///
  /// In es, this message translates to:
  /// **'Cancelando…'**
  String get rideCancelling;

  /// Etiqueta de lector de pantalla del botón que vuelve al inicio.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get rideBackHome;

  /// Tarjeta mientras se asigna chófer: título.
  ///
  /// In es, this message translates to:
  /// **'Asignando a tu chófer'**
  String get rideAssigningTitle;

  /// Tarjeta mientras se asigna chófer: detalle.
  ///
  /// In es, this message translates to:
  /// **'Verás su nombre, vehículo y valoración aquí.'**
  String get rideAssigningDetail;

  /// Momento de éxito al verificarse el código de recogida: título.
  ///
  /// In es, this message translates to:
  /// **'Código verificado'**
  String get rideCodeVerified;

  /// Momento de éxito al verificarse el código de recogida: detalle.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer ya puede iniciar el viaje.'**
  String get rideCodeVerifiedDetail;

  /// Momento de éxito al terminar el viaje.
  ///
  /// In es, this message translates to:
  /// **'Viaje completado'**
  String get rideCompleted;

  /// Título del diálogo de valoración.
  ///
  /// In es, this message translates to:
  /// **'Califica tu viaje'**
  String get rideRatingTitle;

  /// Botón para cerrar el diálogo de valoración sin valorar.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get rideRatingLater;

  /// Botón para enviar la valoración.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get rideRatingSend;

  /// Valoración de 5 estrellas.
  ///
  /// In es, this message translates to:
  /// **'Excelente'**
  String get rideRating5;

  /// Valoración de 4 estrellas.
  ///
  /// In es, this message translates to:
  /// **'Bueno'**
  String get rideRating4;

  /// Valoración de 3 estrellas.
  ///
  /// In es, this message translates to:
  /// **'Regular'**
  String get rideRating3;

  /// Valoración de 2 estrellas.
  ///
  /// In es, this message translates to:
  /// **'Malo'**
  String get rideRating2;

  /// Valoración de 1 estrella.
  ///
  /// In es, this message translates to:
  /// **'Muy malo'**
  String get rideRating1;

  /// Error de un paso del viaje sin conexión (pasajero y chófer).
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu red e inténtalo de nuevo.'**
  String get rideErrorNetwork;

  /// El código de recogida aún no está disponible: el chófer no llegó.
  ///
  /// In es, this message translates to:
  /// **'El código aparece cuando tu chófer llega a la recogida.'**
  String get rideErrorNotAtPickup;

  /// El chófer escribió un código de recogida incorrecto (sin dato de intentos).
  ///
  /// In es, this message translates to:
  /// **'Código incorrecto.'**
  String get rideErrorWrongCode;

  /// Código de recogida incorrecto: queda un intento.
  ///
  /// In es, this message translates to:
  /// **'Código incorrecto. Te queda 1 intento.'**
  String get rideErrorWrongCodeOne;

  /// Código de recogida incorrecto: quedan varios intentos.
  ///
  /// In es, this message translates to:
  /// **'Código incorrecto. Te quedan {left} intentos.'**
  String rideErrorWrongCodeMany(int left);

  /// Verificación del código bloqueada por demasiados intentos.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, la verificación quedó bloqueada. Contacta con central.'**
  String get rideErrorLocked;

  /// El código de recogida venció.
  ///
  /// In es, this message translates to:
  /// **'El código venció. Contacta con central para continuar.'**
  String get rideErrorExpired;

  /// El código de recogida no está disponible.
  ///
  /// In es, this message translates to:
  /// **'El código no está disponible ahora. Contacta con central.'**
  String get rideErrorUnavailable;

  /// Al chófer: el viaje ya no está asignado a él.
  ///
  /// In es, this message translates to:
  /// **'Este viaje ya no está a tu cargo.'**
  String get rideErrorNotYours;

  /// Al chófer: aún no puede marcar que el pasajero no se presentó.
  ///
  /// In es, this message translates to:
  /// **'Aún no terminó el tiempo de espera. Espera un poco más.'**
  String get rideErrorTooEarly;

  /// Al chófer: la opción de no se presentó está desactivada.
  ///
  /// In es, this message translates to:
  /// **'Esta opción no está disponible. Contacta con central.'**
  String get rideErrorNoShowDisabled;

  /// Al chófer: hace falta la ubicación para marcar que no se presentó.
  ///
  /// In es, this message translates to:
  /// **'Activa la ubicación: central necesita saber dónde esperaste.'**
  String get rideErrorLocationRequired;

  /// Al chófer: ya no puede liberar el viaje.
  ///
  /// In es, this message translates to:
  /// **'Ya no puedes liberar este viaje. Contacta con central.'**
  String get rideErrorNotReleasable;

  /// El viaje cambió de estado mientras se hacía un paso.
  ///
  /// In es, this message translates to:
  /// **'El viaje cambió de estado. Actualizamos la pantalla.'**
  String get rideErrorInvalidTransition;

  /// Error genérico de un paso del viaje.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar. Inténtalo de nuevo.'**
  String get rideErrorGeneric;

  /// Páginas de servicio: antetítulo de la franja de garantías.
  ///
  /// In es, this message translates to:
  /// **'Nuestra promesa'**
  String get servicesPromiseEyebrow;

  /// Páginas de servicio: título de la franja de garantías.
  ///
  /// In es, this message translates to:
  /// **'Tranquilidad, por escrito.'**
  String get servicesPromiseTitle;

  /// Páginas de servicio: antetítulo de los pasos.
  ///
  /// In es, this message translates to:
  /// **'Cómo funciona'**
  String get servicesStepsEyebrow;

  /// Páginas de servicio: título de los pasos (con salto de línea).
  ///
  /// In es, this message translates to:
  /// **'Tres pasos.\nNada más.'**
  String get servicesStepsTitle;

  /// Páginas de servicio: antetítulo de las clases de vehículo.
  ///
  /// In es, this message translates to:
  /// **'La flota'**
  String get servicesFleetEyebrow;

  /// Páginas de servicio: título de las clases de vehículo.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo llegar.'**
  String get servicesFleetTitle;

  /// Páginas de servicio: texto bajo el título de la flota.
  ///
  /// In es, this message translates to:
  /// **'Vehículos de gama alta, impecables y preparados antes de cada servicio.'**
  String get servicesFleetBody;

  /// Etiqueta de la clase más elegida (mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'LA MÁS ELEGIDA'**
  String get servicesMostChosen;

  /// Capacidad de la clase de vehículo.
  ///
  /// In es, this message translates to:
  /// **'Hasta {count} pasajeros'**
  String servicesCapacity(int count);

  /// Antes del precio mínimo de la clase (mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'DESDE'**
  String get servicesPriceFrom;

  /// En lugar del precio cuando aún no hay tarifa.
  ///
  /// In es, this message translates to:
  /// **'Cotiza al reservar'**
  String get servicesQuoteOnBooking;

  /// Páginas de servicio: antetítulo de preguntas frecuentes.
  ///
  /// In es, this message translates to:
  /// **'Preguntas frecuentes'**
  String get servicesFaqEyebrow;

  /// Páginas de servicio: título de preguntas frecuentes (con salto de línea).
  ///
  /// In es, this message translates to:
  /// **'Todo lo que\nquieres saber.'**
  String get servicesFaqTitle;

  /// Botón final de las páginas de servicio (mayúsculas).
  ///
  /// In es, this message translates to:
  /// **'RESERVAR AHORA'**
  String get servicesBookNow;

  /// Traslado al aeropuerto: antetítulo.
  ///
  /// In es, this message translates to:
  /// **'Traslado al aeropuerto'**
  String get servicesAirportEyebrow;

  /// Traslado al aeropuerto: título (con saltos de línea).
  ///
  /// In es, this message translates to:
  /// **'Aterriza.\nNosotros nos\nocupamos del resto.'**
  String get servicesAirportTitle;

  /// Traslado al aeropuerto: entradilla.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer te espera en llegadas con tu nombre y se encarga del equipaje. Tú solo sales por la puerta.'**
  String get servicesAirportLead;

  /// Traslado al aeropuerto: paso 1, título.
  ///
  /// In es, this message translates to:
  /// **'Reserva en 2 minutos'**
  String get servicesAirportStep1Title;

  /// Traslado al aeropuerto: paso 1, texto.
  ///
  /// In es, this message translates to:
  /// **'Indica aeropuerto, destino y hora. Añade tu número de vuelo y verás el precio final al instante.'**
  String get servicesAirportStep1Body;

  /// Traslado al aeropuerto: paso 2, título.
  ///
  /// In es, this message translates to:
  /// **'Recibe a tu chófer'**
  String get servicesAirportStep2Title;

  /// Traslado al aeropuerto: paso 2, texto.
  ///
  /// In es, this message translates to:
  /// **'Antes de la recogida tendrás su nombre, vehículo y contacto en la app.'**
  String get servicesAirportStep2Body;

  /// Traslado al aeropuerto: paso 3, título.
  ///
  /// In es, this message translates to:
  /// **'Sal y relájate'**
  String get servicesAirportStep3Title;

  /// Traslado al aeropuerto: paso 3, texto.
  ///
  /// In es, this message translates to:
  /// **'Te espera en llegadas, se ocupa del equipaje y te lleva directo a tu destino.'**
  String get servicesAirportStep3Body;

  /// Traslado al aeropuerto: antetítulo del relato.
  ///
  /// In es, this message translates to:
  /// **'La llegada'**
  String get servicesAirportStoryEyebrow;

  /// Traslado al aeropuerto: título del relato (con salto de línea).
  ///
  /// In es, this message translates to:
  /// **'El primer momento\nde tu viaje, resuelto.'**
  String get servicesAirportStoryTitle;

  /// Traslado al aeropuerto: texto del relato.
  ///
  /// In es, this message translates to:
  /// **'Después de un vuelo largo, lo último que quieres son colas, negociaciones o incertidumbre. Un chófer de Luxelane convierte la llegada en una transición tranquila hacia tu hotel, tu reunión o tu casa.'**
  String get servicesAirportStoryBody;

  /// Traslado al aeropuerto: punto del relato.
  ///
  /// In es, this message translates to:
  /// **'Ayuda con el equipaje, de la cinta al maletero'**
  String get servicesAirportStoryPoint1;

  /// Traslado al aeropuerto: punto del relato.
  ///
  /// In es, this message translates to:
  /// **'Conexiones entre aeropuertos y hoteles sin complicaciones'**
  String get servicesAirportStoryPoint2;

  /// Traslado al aeropuerto: pregunta frecuente 1.
  ///
  /// In es, this message translates to:
  /// **'¿Dónde me espera el chófer?'**
  String get servicesAirportFaq1Question;

  /// Traslado al aeropuerto: respuesta 1.
  ///
  /// In es, this message translates to:
  /// **'En la zona de llegadas. Recibirás sus datos de contacto en la app antes de la recogida.'**
  String get servicesAirportFaq1Answer;

  /// Traslado al aeropuerto: pregunta frecuente 2.
  ///
  /// In es, this message translates to:
  /// **'¿Puedo cancelar mi reserva?'**
  String get servicesAirportFaq2Question;

  /// Traslado al aeropuerto: respuesta 2.
  ///
  /// In es, this message translates to:
  /// **'Sí, desde la app antes de que empiece el viaje. Si según la política de cancelación corresponde un recargo, lo verás antes de confirmar.'**
  String get servicesAirportFaq2Answer;

  /// Traslado al aeropuerto: pregunta frecuente 3.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto equipaje puedo llevar?'**
  String get servicesAirportFaq3Question;

  /// Traslado al aeropuerto: respuesta 3 (Business Van no se traduce).
  ///
  /// In es, this message translates to:
  /// **'Depende de la clase de vehículo. Si viajas con mucho equipaje o en grupo, la Business Van ofrece espacio para hasta 7 pasajeros.'**
  String get servicesAirportFaq3Answer;

  /// Traslado al aeropuerto: título del cierre (con salto de línea).
  ///
  /// In es, this message translates to:
  /// **'Tu próximo vuelo\nya tiene chófer.'**
  String get servicesAirportClosingTitle;

  /// Traslado al aeropuerto: texto del cierre.
  ///
  /// In es, this message translates to:
  /// **'Reserva ahora. Precio fijo al reservar y chóferes con documentos verificados.'**
  String get servicesAirportClosingBody;

  /// Chófer por horas: antetítulo.
  ///
  /// In es, this message translates to:
  /// **'Chófer por horas'**
  String get servicesHourlyEyebrow;

  /// Chófer por horas: título (con saltos de línea).
  ///
  /// In es, this message translates to:
  /// **'Tu agenda.\nTu ritmo.\nTu chófer.'**
  String get servicesHourlyTitle;

  /// Chófer por horas: entradilla.
  ///
  /// In es, this message translates to:
  /// **'Un chófer y un vehículo exclusivamente para ti, de 2 a 24 horas. Cambia de planes cuantas veces quieras: él se adapta.'**
  String get servicesHourlyLead;

  /// Chófer por horas: garantía propia, título.
  ///
  /// In es, this message translates to:
  /// **'Paradas ilimitadas'**
  String get servicesHourlyStopsTitle;

  /// Chófer por horas: garantía propia, detalle.
  ///
  /// In es, this message translates to:
  /// **'Reuniones, compras o visitas: tu chófer te espera en cada parada.'**
  String get servicesHourlyStopsDetail;

  /// Chófer por horas: paso 1, título.
  ///
  /// In es, this message translates to:
  /// **'Elige la duración'**
  String get servicesHourlyStep1Title;

  /// Chófer por horas: paso 1, texto.
  ///
  /// In es, this message translates to:
  /// **'Indica el punto de recogida, el día y cuántas horas necesitas. Mínimo 2, máximo 24.'**
  String get servicesHourlyStep1Body;

  /// Chófer por horas: paso 2, título.
  ///
  /// In es, this message translates to:
  /// **'Diseña tu jornada'**
  String get servicesHourlyStep2Title;

  /// Chófer por horas: paso 2, texto.
  ///
  /// In es, this message translates to:
  /// **'Comparte tu itinerario en las notas o decídelo sobre la marcha. No hace falta destino final.'**
  String get servicesHourlyStep2Body;

  /// Chófer por horas: paso 3, título.
  ///
  /// In es, this message translates to:
  /// **'Disfruta sin mirar el reloj'**
  String get servicesHourlyStep3Title;

  /// Chófer por horas: paso 3, texto.
  ///
  /// In es, this message translates to:
  /// **'Tu chófer y tu vehículo están a tu disposición durante todo el tiempo reservado.'**
  String get servicesHourlyStep3Body;

  /// Chófer por horas: antetítulo del relato.
  ///
  /// In es, this message translates to:
  /// **'Para cada ocasión'**
  String get servicesHourlyStoryEyebrow;

  /// Chófer por horas: título del relato (con salto de línea).
  ///
  /// In es, this message translates to:
  /// **'Un día entero,\nsin pensar en cómo moverte.'**
  String get servicesHourlyStoryTitle;

  /// Chófer por horas: texto del relato.
  ///
  /// In es, this message translates to:
  /// **'Desde una agenda de reuniones hasta una tarde descubriendo la ciudad, el servicio por horas te da la libertad de un vehículo privado sin ninguna de sus preocupaciones.'**
  String get servicesHourlyStoryBody;

  /// Chófer por horas: punto del relato.
  ///
  /// In es, this message translates to:
  /// **'Viajes de negocios: de reunión en reunión, sin esperas'**
  String get servicesHourlyStoryPoint1;

  /// Chófer por horas: punto del relato.
  ///
  /// In es, this message translates to:
  /// **'Eventos y cenas: llegada impecable, salida sin prisas'**
  String get servicesHourlyStoryPoint2;

  /// Chófer por horas: punto del relato.
  ///
  /// In es, this message translates to:
  /// **'Turismo privado: la ciudad a tu ritmo, con un chófer local'**
  String get servicesHourlyStoryPoint3;

  /// Chófer por horas: punto del relato.
  ///
  /// In es, this message translates to:
  /// **'Compras y ocio: tu chófer guarda tus bolsas y te espera'**
  String get servicesHourlyStoryPoint4;

  /// Chófer por horas: pregunta frecuente 1.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo reservo un chófer por horas?'**
  String get servicesHourlyFaq1Question;

  /// Chófer por horas: respuesta 1.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el lugar de recogida, la duración, el día y la hora. Después elige la clase de vehículo y confirma. Verás el precio final antes de pagar.'**
  String get servicesHourlyFaq1Answer;

  /// Chófer por horas: pregunta frecuente 2.
  ///
  /// In es, this message translates to:
  /// **'¿Puedo cambiar el itinerario durante el servicio?'**
  String get servicesHourlyFaq2Question;

  /// Chófer por horas: respuesta 2.
  ///
  /// In es, this message translates to:
  /// **'Sí. El chófer y el vehículo están a tu disposición durante todas las horas reservadas, con tantas paradas como necesites.'**
  String get servicesHourlyFaq2Answer;

  /// Chófer por horas: pregunta frecuente 3.
  ///
  /// In es, this message translates to:
  /// **'¿Puedo ampliar el número de horas?'**
  String get servicesHourlyFaq3Question;

  /// Chófer por horas: respuesta 3.
  ///
  /// In es, this message translates to:
  /// **'Sí, puedes modificar la reserva antes de la hora de inicio. La duración mínima es de 2 horas y la máxima de 24.'**
  String get servicesHourlyFaq3Answer;

  /// Chófer por horas: pregunta frecuente 4.
  ///
  /// In es, this message translates to:
  /// **'¿Puede empezar o terminar en un aeropuerto?'**
  String get servicesHourlyFaq4Question;

  /// Chófer por horas: respuesta 4.
  ///
  /// In es, this message translates to:
  /// **'Sí. El servicio puede empezar o terminar en un aeropuerto, siempre que el inicio y el final estén en la misma ciudad.'**
  String get servicesHourlyFaq4Answer;

  /// Chófer por horas: pregunta frecuente 5.
  ///
  /// In es, this message translates to:
  /// **'¿Cuándo recibiré los datos del chófer?'**
  String get servicesHourlyFaq5Question;

  /// Chófer por horas: respuesta 5.
  ///
  /// In es, this message translates to:
  /// **'Antes de la recogida tendrás en la app el nombre del chófer, el vehículo y su contacto.'**
  String get servicesHourlyFaq5Answer;

  /// Chófer por horas: título del cierre (con salto de línea).
  ///
  /// In es, this message translates to:
  /// **'Reserva el tiempo.\nNosotros ponemos el camino.'**
  String get servicesHourlyClosingTitle;

  /// Chófer por horas: texto del cierre.
  ///
  /// In es, this message translates to:
  /// **'Desde 2 horas, con precio fijo y un chófer profesional a tu entera disposición.'**
  String get servicesHourlyClosingBody;

  /// Recogida inmediata: antetítulo (nombre del servicio).
  ///
  /// In es, this message translates to:
  /// **'Recogida inmediata'**
  String get servicesImmediateEyebrow;

  /// Recogida inmediata: título (con salto de línea).
  ///
  /// In es, this message translates to:
  /// **'Cuando lo\nnecesites.'**
  String get servicesImmediateTitle;

  /// Recogida inmediata: entradilla.
  ///
  /// In es, this message translates to:
  /// **'La misma excelencia de una reserva anticipada, sin planificar.'**
  String get servicesImmediateLead;

  /// Recogida inmediata: garantía propia, título.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento en tiempo real'**
  String get servicesImmediateTrackingTitle;

  /// Recogida inmediata: garantía propia, detalle.
  ///
  /// In es, this message translates to:
  /// **'Ve en el mapa dónde está tu chófer y cuándo llega.'**
  String get servicesImmediateTrackingDetail;

  /// Recogida inmediata: paso 1, título.
  ///
  /// In es, this message translates to:
  /// **'Indica origen y destino'**
  String get servicesImmediateStep1Title;

  /// Recogida inmediata: paso 1, texto.
  ///
  /// In es, this message translates to:
  /// **'Escribe la dirección o elígela en el mapa. Verás el precio final antes de confirmar.'**
  String get servicesImmediateStep1Body;

  /// Recogida inmediata: paso 2, título.
  ///
  /// In es, this message translates to:
  /// **'Confirma con un toque'**
  String get servicesImmediateStep2Title;

  /// Recogida inmediata: paso 2, texto.
  ///
  /// In es, this message translates to:
  /// **'Pagas la reserva. Con el pago confirmado buscamos chófer y te mostramos su nombre y vehículo.'**
  String get servicesImmediateStep2Body;

  /// Recogida inmediata: paso 3, título.
  ///
  /// In es, this message translates to:
  /// **'Síguelo en el mapa'**
  String get servicesImmediateStep3Title;

  /// Recogida inmediata: paso 3, texto.
  ///
  /// In es, this message translates to:
  /// **'Recibe un aviso cuando tu chófer esté en camino y otro cuando haya llegado.'**
  String get servicesImmediateStep3Body;

  /// Recogida inmediata: antetítulo del relato.
  ///
  /// In es, this message translates to:
  /// **'Sin planificar'**
  String get servicesImmediateStoryEyebrow;

  /// Recogida inmediata: título del relato (con salto de línea).
  ///
  /// In es, this message translates to:
  /// **'Lo imprevisto,\ncon la misma elegancia.'**
  String get servicesImmediateStoryTitle;

  /// Recogida inmediata: texto del relato.
  ///
  /// In es, this message translates to:
  /// **'Una reunión que se alarga, un cambio de planes, una cena que merece un final a la altura. La recogida inmediata pone un vehículo premium y un chófer profesional a tu alcance.'**
  String get servicesImmediateStoryBody;

  /// Recogida inmediata: punto del relato.
  ///
  /// In es, this message translates to:
  /// **'Vehículos premium, impecables en cada servicio'**
  String get servicesImmediateStoryPoint1;

  /// Recogida inmediata: punto del relato.
  ///
  /// In es, this message translates to:
  /// **'Chóferes con documentos verificados'**
  String get servicesImmediateStoryPoint2;

  /// Recogida inmediata: punto del relato.
  ///
  /// In es, this message translates to:
  /// **'Precio fijo calculado antes de confirmar, sin tarifas dinámicas'**
  String get servicesImmediateStoryPoint3;

  /// Recogida inmediata: pregunta frecuente 1.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto tarda en llegar el chófer?'**
  String get servicesImmediateFaq1Question;

  /// Recogida inmediata: respuesta 1.
  ///
  /// In es, this message translates to:
  /// **'Depende de tu ubicación y de la disponibilidad. Verás la hora estimada de llegada antes de confirmar y podrás seguir al chófer en el mapa.'**
  String get servicesImmediateFaq1Answer;

  /// Recogida inmediata: pregunta frecuente 2.
  ///
  /// In es, this message translates to:
  /// **'¿El precio cambia según la demanda?'**
  String get servicesImmediateFaq2Question;

  /// Recogida inmediata: respuesta 2.
  ///
  /// In es, this message translates to:
  /// **'No. El precio se fija antes de confirmar y no cambia: sin tarifas dinámicas ni cargos ocultos.'**
  String get servicesImmediateFaq2Answer;

  /// Recogida inmediata: pregunta frecuente 3.
  ///
  /// In es, this message translates to:
  /// **'¿Puedo programar el viaje para más tarde?'**
  String get servicesImmediateFaq3Question;

  /// Recogida inmediata: respuesta 3 (cita el botón «Programar» del inicio).
  ///
  /// In es, this message translates to:
  /// **'Sí. Elige \"Programar\" en el formulario y selecciona el día y la hora que prefieras.'**
  String get servicesImmediateFaq3Answer;

  /// Recogida inmediata: pregunta frecuente 4.
  ///
  /// In es, this message translates to:
  /// **'¿Qué pasa si necesito cancelar?'**
  String get servicesImmediateFaq4Question;

  /// Recogida inmediata: respuesta 4.
  ///
  /// In es, this message translates to:
  /// **'Puedes cancelar desde la app antes de que empiece el viaje. Si según la política de cancelación corresponde un recargo, lo verás antes de confirmar.'**
  String get servicesImmediateFaq4Answer;

  /// Recogida inmediata: título del cierre (con salto de línea).
  ///
  /// In es, this message translates to:
  /// **'Tu chófer,\na un toque.'**
  String get servicesImmediateClosingTitle;

  /// Recogida inmediata: texto del cierre.
  ///
  /// In es, this message translates to:
  /// **'Confirma ahora y sigue a tu chófer en tiempo real hasta la puerta.'**
  String get servicesImmediateClosingBody;

  /// Título de la pantalla Mis viajes.
  ///
  /// In es, this message translates to:
  /// **'Mis viajes'**
  String get tripsTitle;

  /// Botón para volver a cargar la lista de viajes tras un error.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get tripsRetry;

  /// Encabezado de la sección de viajes próximos.
  ///
  /// In es, this message translates to:
  /// **'Próximos'**
  String get tripsUpcoming;

  /// Encabezado de la sección de viajes anteriores (historial).
  ///
  /// In es, this message translates to:
  /// **'Anteriores'**
  String get tripsPast;

  /// Mensaje cuando la persona aún no tiene viajes (dos líneas, con salto de línea).
  ///
  /// In es, this message translates to:
  /// **'Tu primer trayecto\nte está esperando.'**
  String get tripsEmptyMessage;

  /// Botón del estado vacío que lleva a reservar un viaje.
  ///
  /// In es, this message translates to:
  /// **'Reservar ahora'**
  String get tripsEmptyAction;

  /// Título de la tarjeta de un servicio por horas: horas contratadas.
  ///
  /// In es, this message translates to:
  /// **'{hours} h a disposición'**
  String tripsHourlyTitle(int hours);

  /// Línea de la tarjeta de viaje: fecha y hora, y el punto de recogida.
  ///
  /// In es, this message translates to:
  /// **'{when} · desde {origin}'**
  String tripsFrom(String when, String origin);

  /// Acción de la tarjeta de un viaje en curso: seguirlo en el mapa.
  ///
  /// In es, this message translates to:
  /// **'Seguir en el mapa'**
  String get tripsTrackOnMap;

  /// Acción de la tarjeta de un viaje completado sin calificar.
  ///
  /// In es, this message translates to:
  /// **'Calificar viaje'**
  String get tripsRate;

  /// Acción de la tarjeta para abrir la reserva.
  ///
  /// In es, this message translates to:
  /// **'Ver reserva'**
  String get tripsViewBooking;

  /// Etiqueta de una reserva pendiente sin pagar.
  ///
  /// In es, this message translates to:
  /// **'Esperando pago'**
  String get tripsAwaitingPayment;

  /// Etiqueta de una reserva pendiente ya pagada (se busca chófer).
  ///
  /// In es, this message translates to:
  /// **'Pagada'**
  String get tripsPaid;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
