import 'dart:js_interop';

extension type _HouseholdChoresConfig(JSObject _) implements JSObject {
  external JSString? get backendUrl;
}

@JS('HOUSEHOLDCHORES_CONFIG')
external _HouseholdChoresConfig? get _config;

String? runtimeBackendUrl() {
  final value = _config?.backendUrl?.toDart;
  if (value == null || value.trim().isEmpty) return null;

  return value.trim().replaceAll(RegExp(r'/+$'), '');
}
