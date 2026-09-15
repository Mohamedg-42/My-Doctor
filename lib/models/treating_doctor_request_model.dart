enum TreatingDoctorStatus { pending, accepted, rejected, cancelled, referred }

class TreatingDoctorRequest {
  final String id;
  final String patientId;
  final String patientName;
  final String? patientAvatar;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String message;
  final TreatingDoctorStatus status;
  final bool isPaid;
  final double amount;
  final String? paymentMethod;
  final String? paymentRef;
  final String? rejectionReason;
  final String? referredFromDoctorId;
  final String? referredFromDoctorName;
  final String? referredToDoctorId;
  final String? referredToDoctorName;
  final String? referralNote;
  final DateTime createdAt;
  final DateTime? respondedAt;

  TreatingDoctorRequest({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientAvatar,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.message,
    this.status = TreatingDoctorStatus.pending,
    this.isPaid = false,
    this.amount = 750,
    this.paymentMethod,
    this.paymentRef,
    this.rejectionReason,
    this.referredFromDoctorId,
    this.referredFromDoctorName,
    this.referredToDoctorId,
    this.referredToDoctorName,
    this.referralNote,
    required this.createdAt,
    this.respondedAt,
  });

  bool get isAccepted => status == TreatingDoctorStatus.accepted;
  bool get isPending => status == TreatingDoctorStatus.pending;
  bool get isRejected => status == TreatingDoctorStatus.rejected;
  bool get isCancelled => status == TreatingDoctorStatus.cancelled;
  bool get isReferred => status == TreatingDoctorStatus.referred || referredFromDoctorId != null;
  DateTime get updatedAt => respondedAt ?? createdAt;

  static const String defaultMessage =
      'Bonjour Docteur, je souhaite que vous soyez mon médecin traitant ou mon médecin de famille.';

  factory TreatingDoctorRequest.fromJson(Map<String, dynamic> json) {
    return TreatingDoctorRequest(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientName: json['patient_name'] ?? '',
      patientAvatar: json['patient_avatar'],
      doctorId: json['doctor_id'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      doctorSpecialty: json['doctor_specialty'] ?? '',
      message: json['message'] ?? defaultMessage,
      status: _parseStatus(json['status']),
      isPaid: json['is_paid'] ?? false,
      amount: (json['amount'] ?? 750).toDouble(),
      paymentMethod: json['payment_method'],
      paymentRef: json['payment_ref'],
      rejectionReason: json['rejection_reason'],
      referredFromDoctorId: json['referred_from_doctor_id'],
      referredFromDoctorName: json['referred_from_doctor_name'],
      referredToDoctorId: json['referred_to_doctor_id'],
      referredToDoctorName: json['referred_to_doctor_name'],
      referralNote: json['referral_note'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'patient_name': patientName,
    'patient_avatar': patientAvatar,
    'doctor_id': doctorId,
    'doctor_name': doctorName,
    'doctor_specialty': doctorSpecialty,
    'message': message,
    'status': status.name,
    'is_paid': isPaid,
    'amount': amount,
    'payment_method': paymentMethod,
    'payment_ref': paymentRef,
    'rejection_reason': rejectionReason,
    'referred_from_doctor_id': referredFromDoctorId,
    'referred_from_doctor_name': referredFromDoctorName,
    'referred_to_doctor_id': referredToDoctorId,
    'referred_to_doctor_name': referredToDoctorName,
    'referral_note': referralNote,
    'created_at': createdAt.toIso8601String(),
    'responded_at': respondedAt?.toIso8601String(),
  };

  static TreatingDoctorStatus _parseStatus(String? s) {
    switch (s) {
      case 'accepted': return TreatingDoctorStatus.accepted;
      case 'rejected': return TreatingDoctorStatus.rejected;
      case 'cancelled': return TreatingDoctorStatus.cancelled;
      case 'referred': return TreatingDoctorStatus.referred;
      default: return TreatingDoctorStatus.pending;
    }
  }
}

extension TreatingDoctorStatusExt on TreatingDoctorStatus {
  String get label {
    switch (this) {
      case TreatingDoctorStatus.pending:
        return 'En attente';
      case TreatingDoctorStatus.accepted:
        return 'Acceptée';
      case TreatingDoctorStatus.rejected:
        return 'Refusée';
      case TreatingDoctorStatus.cancelled:
        return 'Annulée';
      case TreatingDoctorStatus.referred:
        return 'Référée';
    }
  }
}

