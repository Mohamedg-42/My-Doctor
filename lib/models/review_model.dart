class ReviewModel {
  final String id;
  final String patientId;
  final String patientName;
  final String? patientAvatar;
  final String doctorId;
  final String doctorName;
  final String? appointmentId;
  final double rating; // 1-5
  final String? comment;
  final bool isAnonymous;
  final bool isVerified;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientAvatar,
    required this.doctorId,
    this.doctorName = '',
    this.appointmentId,
    required this.rating,
    this.comment,
    this.isAnonymous = false,
    this.isVerified = false,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientName: json['patient_name'] ?? '',
      patientAvatar: json['patient_avatar'],
      doctorId: json['doctor_id'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      appointmentId: json['appointment_id'],
      rating: (json['rating'] ?? 5.0).toDouble(),
      comment: json['comment'],
      isAnonymous: json['is_anonymous'] ?? false,
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class MedicationReminder {
  final String id;
  final String userId;
  final String medicationName;
  final String dosage;
  final List<String> scheduledTimes;
  final List<bool> daysOfWeek; // [lun, mar, mer, jeu, ven, sam, dim]
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? notes;
  final String? doctorId;

  MedicationReminder({
    required this.id,
    required this.userId,
    required this.medicationName,
    required this.dosage,
    required this.scheduledTimes,
    required this.daysOfWeek,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.notes,
    this.doctorId,
  });

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    return MedicationReminder(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      medicationName: json['medication_name'] ?? '',
      dosage: json['dosage'] ?? '',
      scheduledTimes: List<String>.from(json['scheduled_times'] ?? []),
      daysOfWeek: List<bool>.from(json['days_of_week'] ?? List.filled(7, true)),
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      isActive: json['is_active'] ?? true,
      notes: json['notes'],
      doctorId: json['doctor_id'],
    );
  }
}
