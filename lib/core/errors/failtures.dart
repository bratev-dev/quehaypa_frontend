abstract class Failure {
    final String message;

    const Failure(this.message);
}

class NetworkFailure extends Failure {
    const NetworkFailure(super.message);
}

class UnauthorizedFailure extends Failure {
    const UnauthorizedFailure(super.message);
}

class AuthenticationFailure extends Failure {
    const AuthenticationFailure(super.message);
}

class ServerFailure extends Failure {
    const ServerFailure(super.message);
}

class StorageFailure extends Failure {
    const StorageFailure(super.message);
}

class UnknownFailure extends Failure {
    const UnknownFailure(super.message);
}