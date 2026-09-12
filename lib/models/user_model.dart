enum UserRole { patient, doctor, admin }

enum AccountStatus { pending, active, suspended, rejected }

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final UserRole role;
  final AccountStatus status;
  final String? avatarUrl;
  final bool is2FAEnabled;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  // Photo locale en base64 (prise lors de l'inscription, prioritaire sur avatarUrl)
  final String? avatarBase64;

  // Extended CMU/profile fields
  final String? cmuNumber;
  final DateTime? birthDate;
  final String? gender;
  final String? profession;
  final String? commune;
  final String? city;
  final String? idPhotoUrl;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.status = AccountStatus.pending,
    this.avatarUrl,
    this.avatarBase64,
    this.is2FAEnabled = true,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    required this.createdAt,
    this.lastLoginAt,
    this.cmuNumber,
    this.birthDate,
    this.gender,
    this.profession,
    this.commune,
    this.city,
    this.idPhotoUrl,
  });

  String get fullName => '${lastName.toUpperCase()} $firstName';

  String get initials {
    String f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  /// Display name: LASTNAME Firstname(s) form
  String get displayName => '${lastName.toUpperCase()} $firstName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: _parseRole(json['role']),
      status: _parseStatus(json['status']),
      avatarUrl: json['avatar_url'],
      is2FAEnabled: json['is_2fa_enabled'] ?? true,
      isEmailVerified: json['is_email_verified'] ?? false,
      isPhoneVerified: json['is_phone_verified'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'])
          : null,
      cmuNumber: json['cmu_number'],
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'])
          : null,
      gender: json['gender'],
      profession: json['profession'],
      commune: json['commune'],
      city: json['city'],
      idPhotoUrl: json['id_photo_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'role': role.name,
        'status': status.name,
        'avatar_url': avatarUrl,
        'is_2fa_enabled': is2FAEnabled,
        'is_email_verified': isEmailVerified,
        'is_phone_verified': isPhoneVerified,
        'created_at': createdAt.toIso8601String(),
        'last_login_at': lastLoginAt?.toIso8601String(),
        'cmu_number': cmuNumber,
        'birth_date': birthDate?.toIso8601String(),
        'gender': gender,
        'profession': profession,
        'commune': commune,
        'city': city,
        'id_photo_url': idPhotoUrl,
      };

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    AccountStatus? status,
    String? avatarUrl,
    String? avatarBase64,
    bool? is2FAEnabled,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? cmuNumber,
    DateTime? birthDate,
    String? gender,
    String? profession,
    String? commune,
    String? city,
    String? idPhotoUrl,
  }) {
    return UserModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      is2FAEnabled: is2FAEnabled ?? this.is2FAEnabled,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      cmuNumber: cmuNumber ?? this.cmuNumber,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      profession: profession ?? this.profession,
      commune: commune ?? this.commune,
      city: city ?? this.city,
      idPhotoUrl: idPhotoUrl ?? this.idPhotoUrl,
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'doctor':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.patient;
    }
  }

  static AccountStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return AccountStatus.active;
      case 'suspended':
        return AccountStatus.suspended;
      case 'rejected':
        return AccountStatus.rejected;
      default:
        return AccountStatus.pending;
    }
  }
}
