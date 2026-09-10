import '../../../../core/security/session_refresher.dart';
import '../../domain/usecases/refresh_session_use_case.dart';

class SessionRefresherImpl implements SessionRefresher {
  final RefreshSessionUseCase _refreshSessionUseCase;

  const SessionRefresherImpl({required this._refreshSessionUseCase});

  @override
  Future<String?> refreshAccessToken() async {
    final session = await _refreshSessionUseCase();

    return session.accessToken;
  }
}
