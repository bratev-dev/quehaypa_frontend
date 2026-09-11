enum RegisterStep { credentials, roleSelection, personalDetails, interests }

enum UserRole { user, organizer }

enum RegisterStatus { initial, loading, success, error }

class RegisterState {
  final RegisterStep currentStep;
  final RegisterStatus status;
  final UserRole? selectedRole;
  final String email;
  final String password;
  final String name;
  final String lastname;
  final String username;
  final String birthDate;
  final String cc;
  final List<String> selectedInterests;
  final String? errorMessage;

  const RegisterState({
    this.currentStep = RegisterStep.credentials,
    this.status = RegisterStatus.initial,
    this.selectedRole,
    this.email = '',
    this.password = '',
    this.name = '',
    this.lastname = '',
    this.username = '',
    this.birthDate = '',
    this.cc = '',
    this.selectedInterests = const [],
    this.errorMessage,
  });

  RegisterState copyWith({
    RegisterStep? currentStep,
    RegisterStatus? status,
    UserRole? selectedRole,
    String? email,
    String? password,
    String? name,
    String? lastname,
    String? username,
    String? birthDate,
    String? cc,
    List<String>? selectedInterests,
    String? errorMessage,
  }) {
    return RegisterState(
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      selectedRole: selectedRole ?? this.selectedRole,
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      lastname: lastname ?? this.lastname,
      username: username ?? this.username,
      birthDate: birthDate ?? this.birthDate,
      cc: cc ?? this.cc,
      selectedInterests: selectedInterests ?? this.selectedInterests,
      errorMessage: errorMessage,
    );
  }
}
