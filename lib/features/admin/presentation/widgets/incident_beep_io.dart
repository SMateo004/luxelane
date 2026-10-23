import 'package:flutter/services.dart';

/// Aviso sonoro del sistema (móvil y escritorio).
void playIncidentBeep() => SystemSound.play(SystemSoundType.alert);
