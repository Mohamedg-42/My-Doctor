enum TreatingDoctorStatus { pending, accepted, rejected, cancelled }

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
    required this.createdAt,
    this.respondedAt,
  });

  bool get isAccepted => status == TreatingDoctorStatus.accepted;
  bool get isPending => status == TreatingDoctorStatus.pending;

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
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'])
          : null,
    );
  }

  static TreatingDoctorStatus _parseStatus(String? s) {
    switch (s) {
      case 'accepted': return TreatingDoctorStatus.accepted;
      case 'rejected': return TreatingDoctorStatus.rejected;
      case 'cancelled': return TreatingDoctorStatus.cancelled;
      default: return TreatingDoctorStatus.pending;
    }
  }
}
