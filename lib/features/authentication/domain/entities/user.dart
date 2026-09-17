class User {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime? birthDate;
  final String? profilePictureUrl;
  final bool isActive;

  const User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.birthDate,
    this.profilePictureUrl,
    required this.isActive,
  });
}
