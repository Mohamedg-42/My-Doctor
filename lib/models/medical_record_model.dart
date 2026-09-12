enum RecordType { consultation, prescription, labResult, imaging, vaccination, surgery }

class MedicalDocument {
  final String id;
  final String name;
  final String url;
  final String type;
  final int sizeBytes;
  final DateTime uploadedAt;
  final String uploadedBy;

  MedicalDocument({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.sizeBytes,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '${sizeBytes}B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  factory MedicalDocument.fromJson(Map<String, dynamic> json) {
    return MedicalDocument(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      type: json['type'] ?? 'document',
      sizeBytes: json['size_bytes'] ?? 0,
      uploadedAt: DateTime.tryParse(json['uploaded_at'] ?? '') ?? DateTime.now(),
      uploadedBy: json['uploaded_by'] ?? '',
    );
  }
}

class MedicalRecord {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final RecordType type;
  final String title;
  final String? description;
  final String? diagnosis;
  final String? prescription;
  final String? notes;
  final List<MedicalDocument> documents;
  final List<String> tags;
  final bool isConfidential;
  final DateTime consultationDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.type,
    required this.title,
    this.description,
    this.diagnosis,
    this.prescription,
    this.notes,
    this.documents = const [],
    this.tags = const [],
    this.isConfidential = false,
    required this.consultationDate,
    required this.createdAt,
    this.updatedAt,
  });

  String get typeLabel {
    switch (type) {
      case RecordType.consultation: return 'Consultation';
      case RecordType.prescription: return 'Ordonnance';
      case RecordType.labResult: return 'Résultat d\'analyse';
      case RecordType.imaging: return 'Imagerie médicale';
      case RecordType.vaccination: return 'Vaccination';
      case RecordType.surgery: return 'Intervention chirurgicale';
    }
  }

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientName: json['patient_name'] ?? '',
      doctorId: json['doctor_id'] ?? '',
      doctorName: json['doctor_name'] ?? '',
      doctorSpecialty: json['doctor_specialty'] ?? '',
      type: _parseType(json['type']),
      title: json['title'] ?? '',
      description: json['description'],
      diagnosis: json['diagnosis'],
      prescription: json['prescription'],
      notes: json['notes'],
      documents: (json['documents'] as List? ?? [])
          .map((d) => MedicalDocument.fromJson(d))
          .toList(),
      tags: List<String>.from(json['tags'] ?? []),
      isConfidential: json['is_confidential'] ?? false,
      consultationDate: DateTime.tryParse(json['consultation_date'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  static RecordType _parseType(String? t) {
    switch (t) {
      case 'prescription': return RecordType.prescription;
      case 'lab_result': return RecordType.labResult;
      case 'imaging': return RecordType.imaging;
      case 'vaccination': return RecordType.vaccination;
      case 'surgery': return RecordType.surgery;
      default: return RecordType.consultation;
    }
  }
}
