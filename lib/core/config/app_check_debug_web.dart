import 'dart:js_interop';

@JS('self.FIREBASE_APPCHECK_DEBUG_TOKEN')
external set _debugToken(JSString value);

/// La SDK web de App Check lee este global antes de activarse (solo debug).
void setAppCheckDebugToken(String token) => _debugToken = token.toJS;
