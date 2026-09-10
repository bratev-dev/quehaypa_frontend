import 'dart:async';

class SessionEvents {
  final StreamController<void> _sessionInvalidatedController =
      StreamController<void>.broadcast();

  Stream<void> get onSessionInvalidated => _sessionInvalidatedController.stream;

  void notifySessionInvalidated() {
    _sessionInvalidatedController.add(null);
  }

  void dispose() {
    _sessionInvalidatedController.close();
  }
}
