import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/models.dart';
import '../../../../l10n/l10n.dart';
import '../../data/driver_registration_repository.dart';
import '../../data/image_prep.dart';

/// Pasos de la solicitud, en orden. [security] solo existe con
/// config/security.mfaEnforced: el TOTP se da de alta antes del envío.
enum RegistrationStep { personal, vehicle, documents, security, summary }

class RegistrationState extends Equatable {
  const RegistrationState({
    this.loading = true,
    this.loadError,
    this.view,
    this.secondFactor = SecondFactorState.none,
    this.page = RegistrationStep.personal,
    this.saving = false,
    this.uploading = const {},
    this.uploadErrors = const {},
    this.fieldErrors = const [],
    this.message,
    this.messageSeq = 0,
  });

  final bool loading;
  final String? loadError;
  final DriverApplicationView? view;
  final SecondFactorState secondFactor;
  final RegistrationStep page;

  /// Guardando un paso o enviando.
  final bool saving;

  /// Documentos subiéndose ahora (un segundo toque no sube otra vez).
  final Set<DriverDocType> uploading;
  final Map<DriverDocType, String> uploadErrors;

  /// Campos que el servidor marcó (details.fields).
  final List<String> fieldErrors;

  /// Aviso puntual; [messageSeq] sube con cada uno.
  final String? message;
  final int messageSeq;

  DriverApplication get app => view?.application ?? DriverApplication.empty;
  bool get mfaEnforced => view?.mfaEnforced ?? false;

  List<RegistrationStep> get steps => [
        RegistrationStep.personal,
        RegistrationStep.vehicle,
        RegistrationStep.documents,
        if (mfaEnforced) RegistrationStep.security,
        RegistrationStep.summary,
      ];

  /// El TOTP que pide el envío está listo (o no se exige).
  bool get securityReady =>
      !mfaEnforced || secondFactor == SecondFactorState.inSession;

  bool get canSubmit => app.canSubmit && securityReady && !saving;

  /// Enviada o en revisión: solo se muestra el estado.
  bool get waitingReview =>
      app.status == DriverAppStatus.submitted ||
      app.status == DriverAppStatus.inReview;

  RegistrationState copyWith({
    bool? loading,
    String? loadError,
    bool clearLoadError = false,
    DriverApplicationView? view,
    SecondFactorState? secondFactor,
    RegistrationStep? page,
    bool? saving,
    Set<DriverDocType>? uploading,
    Map<DriverDocType, String>? uploadErrors,
    List<String>? fieldErrors,
    String? message,
  }) =>
      RegistrationState(
        loading: loading ?? this.loading,
        loadError: clearLoadError ? null : (loadError ?? this.loadError),
        view: view ?? this.view,
        secondFactor: secondFactor ?? this.secondFactor,
        page: page ?? this.page,
        saving: saving ?? this.saving,
        uploading: uploading ?? this.uploading,
        uploadErrors: uploadErrors ?? this.uploadErrors,
        fieldErrors: fieldErrors ?? this.fieldErrors,
        message: message,
        messageSeq: message != null ? messageSeq + 1 : messageSeq,
      );

  @override
  List<Object?> get props => [
        loading,
        loadError,
        view?.application.status,
        view?.application.step,
        view?.application.documents.length,
        view?.mfaEnforced,
        view,
        secondFactor,
        page,
        saving,
        uploading,
        uploadErrors,
        fieldErrors,
        message,
        messageSeq,
      ];
}

class RegistrationCubit extends Cubit<RegistrationState> {
  RegistrationCubit({
    required DriverRegistrationRepository repository,
    required ImagePrep imagePrep,
  })  : _repo = repository,
        _prep = imagePrep,
        super(const RegistrationState());

  final DriverRegistrationRepository _repo;
  final ImagePrep _prep;

  String _msg(Failure f) => f.message;

  /// Carga (o recarga) la solicitud. [jump]: ir al primer paso pendiente.
  Future<void> load({bool jump = true}) async {
    emit(state.copyWith(loading: true, clearLoadError: true));
    final r = await _repo.getApplication();
    final second = await _repo.secondFactor();
    if (isClosed) return;
    r.fold(
      (f) => emit(state.copyWith(loading: false, loadError: _msg(f))),
      (view) {
        final a = view.application;
        final page = !jump
            ? state.page
            : a.personal == null
                ? RegistrationStep.personal
                : a.vehicle == null
                    ? RegistrationStep.vehicle
                    : RegistrationStep.documents;
        emit(state.copyWith(
          loading: false,
          view: view,
          secondFactor: second,
          page: page,
        ));
      },
    );
  }

  void goTo(RegistrationStep step) {
    if (state.steps.contains(step)) emit(state.copyWith(page: step));
  }

  void next() {
    final i = state.steps.indexOf(state.page);
    if (i >= 0 && i + 1 < state.steps.length) goTo(state.steps[i + 1]);
  }

  void back() {
    final i = state.steps.indexOf(state.page);
    if (i > 0) goTo(state.steps[i - 1]);
  }

  Future<bool> _save(Map<String, dynamic> step) async {
    if (state.saving) return false;
    emit(state.copyWith(saving: true, fieldErrors: const []));
    final r = await _repo.saveStep(step);
    if (isClosed) return false;
    return r.fold((f) {
      emit(state.copyWith(
        saving: false,
        message: _msg(f),
        fieldErrors: f is RegistrationFailure ? f.fields ?? const [] : const [],
      ));
      return false;
    }, (_) async {
      emit(state.copyWith(saving: false));
      await load(jump: false);
      next();
      return true;
    });
  }

  Future<bool> savePersonal(DriverPersonalData data) => _save(data.toStep());

  Future<bool> saveVehicle(DriverVehicleData data) => _save(data.toStep());

  /// Prepara (resolución, JPEG sin EXIF) y sube una foto de [type].
  Future<bool> uploadPhoto(
    DriverDocType type,
    Uint8List raw, {
    DateTime? expiresAt,
  }) async {
    if (state.uploading.contains(type)) return false;
    if (!uploadsSupported) {
      emit(state.copyWith(message: L10n.current.regWebUploadBlocked));
      return false;
    }
    final errors = {...state.uploadErrors}..remove(type);
    emit(state.copyWith(
      uploading: {...state.uploading, type},
      uploadErrors: errors,
    ));
    final prepared = await _prep.prepare(raw);
    if (prepared.image == null) {
      final text = prepared.issue == ImageIssue.tooSmall
          ? L10n.current.regPhotoTooSmall
          : L10n.current.regPhotoUnreadable;
      _endUpload(type, text);
      return false;
    }
    final r = await _repo.uploadDocument(
      type: type,
      // La misma versión en cada reintento hasta que el servidor la
      // registre: no se duplica.
      version: state.app.nextVersion(type),
      bytes: prepared.image!.bytes,
      contentType: PreparedImage.contentType,
      expiresAt: expiresAt,
    );
    if (isClosed) return false;
    return r.fold((f) {
      _endUpload(type, _msg(f));
      return false;
    }, (_) async {
      _endUpload(type, null);
      await load(jump: false);
      return true;
    });
  }

  void _endUpload(DriverDocType type, String? error) {
    if (isClosed) return;
    final errors = {...state.uploadErrors};
    if (error != null) errors[type] = error;
    emit(state.copyWith(
      uploading: {...state.uploading}..remove(type),
      uploadErrors: errors,
    ));
  }

  /// Vuelve a mirar el segundo factor (tras el alta o volver a entrar).
  Future<void> refreshSecondFactor() async {
    final s = await _repo.secondFactor();
    if (!isClosed) emit(state.copyWith(secondFactor: s));
  }

  Future<bool> submit() async {
    if (state.saving) return false;
    if (!state.securityReady) {
      emit(state.copyWith(message: L10n.current.regSecurityNeededToSubmit));
      return false;
    }
    emit(state.copyWith(saving: true));
    final r = await _repo.submit();
    if (isClosed) return false;
    return r.fold((f) {
      emit(state.copyWith(saving: false, message: _msg(f)));
      return false;
    }, (_) async {
      emit(state.copyWith(saving: false));
      await load(jump: false);
      return true;
    });
  }
}
