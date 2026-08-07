/// Frontend-only representation of the currently signed-in user.
///
/// This is a plain data model — no authentication, no backend, no persistence.
/// It exists purely so the Profile screen has structured data to render.
class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photoPath;
  final DateTime? registrationDate;
  final bool isDeleted;
  final DateTime? deletionDate;
  final String registrationType;

  const UserProfileModel({
    this.id = '',
    required this.name,
    required this.email,
    required this.phone,
    this.photoPath,
    this.registrationDate,
    this.isDeleted = false,
    this.deletionDate,
    this.registrationType = 'signup',
  });

  UserProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoPath,
    bool clearPhoto = false,
    DateTime? registrationDate,
    bool? isDeleted,
    DateTime? deletionDate,
    String? registrationType,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      registrationDate: registrationDate ?? this.registrationDate,
      isDeleted: isDeleted ?? this.isDeleted,
      deletionDate: deletionDate ?? this.deletionDate,
      registrationType: registrationType ?? this.registrationType,
    );
  }

  /// Derive initials (e.g. "John Doe" → "JD") for the avatar fallback.
  /// Single-word names fall back to their first letter.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }
}
