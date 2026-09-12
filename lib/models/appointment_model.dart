enum AppointmentStatus {
  pending,
  confirmed,
  cancelled,
  completed,
  inProgress,
  noShow,
}

enum AppointmentType { inPerson, teleconsultation }

class AppointmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String? patientAvatar;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String? doctorAvatar;
  final DateTime scheduledAt;
  final int durationMinutes;
  final AppointmentStatus status;
  final AppointmentType type;
  final String? reason;
  final String? notes;
  final double? consultationPrice;
  final bool isPaid;
  final bool hasReminder;
  final DateTime? reminderAt;
  final String? videoRoomId;
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientAvatar,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    this.doctorAvatar,
    required this.scheduledAt,
    this.durationMinutes = 30,
    this.status = AppointmentStatus.pending,
    this.type = AppointmentType.inPerson,
    this.reason,
    this.notes,
    this.consultationPrice,
    this.isPaid = false,
    this.hasReminder = true,
    this.reminderAt,
    this.videoRoomId,
    required this.createdAt,
  });

  bool get isUpcoming =>
      scheduledAt.isAfter(DateTime.now()) &&
      (status == AppointmentStatus.pending ||
          status == AppointmentStatus.confirmed);

  bool get isPast => scheduledAt.isBefore(DateTime.now());

  bool get isTeleconsultation => type == AppointmentType.teleconsultation;

  String get statusLabel {
    switch (status) {
      case AppointmentStatus.pending:
        return 'En attente';
      case AppointmentStatus.confirmed:
        return 'Confirmé';
      case AppointmentStatus.cancelled:
        return 'Annulé';
      case AppointmentStatus.completed:
        return 'Terminé';
      case AppointmentStatus.inProgress:
        return 'En cours';
      case AppointmentStatus.noShow:
        return 'Absent';
    }
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientName: json['patient_name'] ?? '',
      patientAvatar: json['patient_avatar'],
      doctorId: json['doctor_id'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      doctorSpecialty: json['doctor_specialty'] ?? '',
      doctorAvatar: json['doctor_avatar'],
      scheduledAt: DateTime.tryParse(json['scheduled_at'] ?? '') ?? DateTime.now(),
      durationMinutes: json['duration_minutes'] ?? 30,
      status: _parseStatus(json['status']),
      type: json['type'] == 'teleconsultation'
          ? AppointmentType.teleconsultation
          : AppointmentType.inPerson,
      reason: json['reason'],
      notes: json['notes'],
      consultationPrice: json['consultation_price']?.toDouble(),
      isPaid: json['is_paid'] ?? false,
      hasReminder: json['has_reminder'] ?? true,
      reminderAt: json['reminder_at'] != null
          ? DateTime.tryParse(json['reminder_at'])
          : null,
      videoRoomId: json['video_room_id'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  static AppointmentStatus _parseStatus(String? s) {
    switch (s) {
      case 'confirmed': return AppointmentStatus.confirmed;
      case 'cancelled': return AppointmentStatus.cancelled;
      case 'completed': return AppointmentStatus.completed;
      case 'in_progress': return AppointmentStatus.inProgress;
      case 'no_show': return AppointmentStatus.noShow;
      default: return AppointmentStatus.pending;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'patient_name': patientName,
        'patient_avatar': patientAvatar,
        'doctor_id': doctorId,
        'doctor_name': doctorName,
        'doctor_specialty': doctorSpecialty,
        'doctor_avatar': doctorAvatar,
        'scheduled_at': scheduledAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'status': status.name,
        'type': type.name,
        'reason': reason,
        'notes': notes,
        'consultation_price': consultationPrice,
        'is_paid': isPaid,
        'has_reminder': hasReminder,
        'reminder_at': reminderAt?.toIso8601String(),
        'video_room_id': videoRoomId,
        'created_at': createdAt.toIso8601String(),
      };

  AppointmentModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientAvatar,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    String? doctorAvatar,
    DateTime? scheduledAt,
    int? durationMinutes,
    AppointmentStatus? status,
    AppointmentType? type,
    String? reason,
    String? notes,
    double? consultationPrice,
    bool? isPaid,
    bool? hasReminder,
    DateTime? reminderAt,
    String? videoRoomId,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientAvatar: patientAvatar ?? this.patientAvatar,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      doctorAvatar: doctorAvatar ?? this.doctorAvatar,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      consultationPrice: consultationPrice ?? this.consultationPrice,
      isPaid: isPaid ?? this.isPaid,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderAt: reminderAt ?? this.reminderAt,
      videoRoomId: videoRoomId ?? this.videoRoomId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
