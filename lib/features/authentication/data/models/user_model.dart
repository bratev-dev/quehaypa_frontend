import '../../domain/entities/user.dart';

class UserModel {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime? birthDate;
  final String? profilePictureUrl;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.birthDate,
    this.profilePictureUrl,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? birthDate;
    final rawBirthDate = json['birthDate'];

    if (rawBirthDate is String && rawBirthDate.isNotEmpty) {
      birthDate = DateTime.tryParse(rawBirthDate);
    }

    final rawId = json['id'];
    if (rawId is! num) {
      throw const FormatException('Campo id ausente o inválido en UserModel');
    }

    return UserModel(
      id: rawId.toInt(),
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      birthDate: birthDate,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  User toEntity() {
    return User(
      id: id,
      username: username,
      firstName: firstName,
      lastName: lastName,
      email: email,
      birthDate: birthDate,
      profilePictureUrl: profilePictureUrl,
      isActive: isActive,
    );
  }
}
