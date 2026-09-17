class Organizer {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String identificationDocument;
  final String? reason;
  final String? contactPhone;
  final bool isActive;

  const Organizer({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.identificationDocument,
    this.reason,
    this.contactPhone,
    required this.isActive,
  });
}
