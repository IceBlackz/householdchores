import 'dart:js_interop';

@JS('window.location.origin')
external JSString get _origin;

@JS('window.location.assign')
external void _assign(JSString value);

bool get canOpenWebLinks => true;

String absoluteWebUrl(String path) => _origin.toDart + path;

void openWebPath(String path) {
  _assign(path.toJS);
}
