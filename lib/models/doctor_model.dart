class DoctorModel {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String specialty;
  final String orderNumber; // Numéro d'ordre 5 chiffres exactement
  final String? bio;
  final String? avatarUrl;
  final String? avatarBase64; // Photo locale en base64 (inscription réelle)
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final double rating;
  final int reviewCount;
  final int patientCount;
  final int experienceYears;
  final double successRate;
  final double consultationPrice;
  final bool isAvailable;
  final bool isVerified;
  final bool isOnline;
  final List<String> availableDays;
  final Map<String, List<String>> availableSlots;
  final List<String> documentUrls;
  final String? diplomaUrl;
  final String? idCardUrl;
  final String? proCardUrl;
  final String? whatsappNumber;
  final DateTime createdAt;
  final double? distanceKm;

  DoctorModel({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.specialty,
    required this.orderNumber,
    this.bio,
    this.avatarUrl,
    this.avatarBase64,
    this.latitude = 5.3599517,
    this.longitude = -4.0082563,
    this.address,
    this.city = 'Abidjan',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.patientCount = 0,
    this.experienceYears = 0,
    this.successRate = 99.0,
    this.consultationPrice = 15000,
    this.isAvailable = true,
    this.isVerified = false,
    this.isOnline = false,
    this.availableDays = const [],
    this.availableSlots = const {},
    this.documentUrls = const [],
    this.diplomaUrl,
    this.idCardUrl,
    this.proCardUrl,
    this.whatsappNumber,
    required this.createdAt,
    this.distanceKm,
  });

  String get fullName => 'Dr. $firstName $lastName';
  String get initials {
    String f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  String get formattedPrice => '${consultationPrice.toStringAsFixed(0)} F CFA';
  String get formattedRating => rating.toStringAsFixed(1);
  String get formattedDistance =>
      distanceKm != null ? '${distanceKm!.toStringAsFixed(1)} km' : '';
  String get formattedPatients =>
      patientCount > 999 ? '${(patientCount / 1000).toStringAsFixed(0)}k+' : '$patientCount+';

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      specialty: json['specialty'] ?? 'Généraliste',
      orderNumber: json['order_number'] ?? '',
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      avatarBase64: json['avatar_base64'],
      latitude: (json['latitude'] ?? 5.3599517).toDouble(),
      longitude: (json['longitude'] ?? -4.0082563).toDouble(),
      address: json['address'],
      city: json['city'] ?? 'Abidjan',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      patientCount: json['patient_count'] ?? 0,
      experienceYears: json['experience_years'] ?? 0,
      successRate: (json['success_rate'] ?? 99.0).toDouble(),
      consultationPrice: (json['consultation_price'] ?? 15000).toDouble(),
      isAvailable: json['is_available'] ?? true,
      isVerified: json['is_verified'] ?? false,
      isOnline: json['is_online'] ?? false,
      availableDays: List<String>.from(json['available_days'] ?? []),
      availableSlots: Map<String, List<String>>.from(
        (json['available_slots'] ?? {}).map(
          (k, v) => MapEntry(k, List<String>.from(v)),
        ),
      ),
      documentUrls: List<String>.from(json['document_urls'] ?? []),
      diplomaUrl: json['diploma_url'],
      idCardUrl: json['id_card_url'],
      proCardUrl: json['pro_card_url'],
      whatsappNumber: json['whatsapp_number'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      distanceKm: json['distance_km']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'specialty': specialty,
        'order_number': orderNumber,
        'bio': bio,
        'avatar_url': avatarUrl,
        'avatar_base64': avatarBase64,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'city': city,
        'rating': rating,
        'review_count': reviewCount,
        'patient_count': patientCount,
        'experience_years': experienceYears,
        'success_rate': successRate,
        'consultation_price': consultationPrice,
        'is_available': isAvailable,
        'is_verified': isVerified,
        'is_online': isOnline,
        'available_days': availableDays,
        'available_slots': availableSlots,
        'document_urls': documentUrls,
        'diploma_url': diplomaUrl,
        'id_card_url': idCardUrl,
        'pro_card_url': proCardUrl,
        'whatsapp_number': whatsappNumber,
        'created_at': createdAt.toIso8601String(),
      };
}
