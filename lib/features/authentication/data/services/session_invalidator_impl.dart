import '../../../../core/security/session_events.dart';
import '../../../../core/security/session_invalidator.dart';
import '../../../../core/security/token_manager.dart';

class SessionInvalidatorImpl implements SessionInvalidator {
    final TokenManager _tokenManager;
    final SessionEvents _sessionEvents;

    const SessionInvalidatorImpl({
        required this._tokenManager,
        required this._sessionEvents,
    });

    @override
    Future<void> invalidateSession() async {
        await _tokenManager.clearSession();

        _sessionEvents.notifySessionInvalidated();
    }
}