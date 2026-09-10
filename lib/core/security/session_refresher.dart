abstract interface class SessionRefresher {
    Future<String?> refreshAccessToken();
}