import 'package:cloud_firestore/cloud_firestore.dart';

class ConsultationModel {
  final String id;
  final String patientId;
  final String? doctorId; // Optional - can be null if not yet assigned
  final String status; // "pending" | "in_review" | "completed" | "cancelled"
  final String urgency; // "normal" | "urgent" | "emergency"
  final String title;
  final String description;
  final List<AttachmentModel> attachments;
  final DoctorResponseModel? doctorResponse;
  final int? patientRating;
  final String? patientFeedback;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime termsAcceptedAt;

  // Cached doctor info (not from Firestore, fetched separately)
  String? doctorName;
  String? doctorSpecialty;

  ConsultationModel({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.status,
    required this.urgency,
    required this.title,
    required this.description,
    required this.attachments,
    this.doctorResponse,
    this.patientRating,
    this.patientFeedback,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.termsAcceptedAt,
    this.doctorName,
    this.doctorSpecialty,
  });

  // Create from Firestore document
  factory ConsultationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ConsultationModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'],
      status: data['status'] ?? 'pending',
      urgency: data['urgency'] ?? 'normal',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      attachments: (data['attachments'] as List<dynamic>?)
              ?.map((e) => AttachmentModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      doctorResponse: data['doctorResponse'] != null
          ? DoctorResponseModel.fromMap(
              data['doctorResponse'] as Map<String, dynamic>)
          : null,
      patientRating: data['patientRating'],
      patientFeedback: data['patientFeedback'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      termsAcceptedAt: (data['termsAcceptedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'status': status,
      'urgency': urgency,
      'title': title,
      'description': description,
      'attachments': attachments.map((e) => e.toMap()).toList(),
      'doctorResponse': doctorResponse?.toMap(),
      'patientRating': patientRating,
      'patientFeedback': patientFeedback,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'termsAcceptedAt': Timestamp.fromDate(termsAcceptedAt),
    };
  }

  // Copy with method for updating fields
  ConsultationModel copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? status,
    String? urgency,
    String? title,
    String? description,
    List<AttachmentModel>? attachments,
    DoctorResponseModel? doctorResponse,
    int? patientRating,
    String? patientFeedback,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? termsAcceptedAt,
    String? doctorName,
    String? doctorSpecialty,
  }) {
    return ConsultationModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      status: status ?? this.status,
      urgency: urgency ?? this.urgency,
      title: title ?? this.title,
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
      doctorResponse: doctorResponse ?? this.doctorResponse,
      patientRating: patientRating ?? this.patientRating,
      patientFeedback: patientFeedback ?? this.patientFeedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
    );
  }
}

// Attachment model for uploaded files
class AttachmentModel {
  final String name;
  final String url;
  final String type; // "image" | "pdf" | "document"
  final DateTime uploadedAt;

  AttachmentModel({
    required this.name,
    required this.url,
    required this.type,
    required this.uploadedAt,
  });

  factory AttachmentModel.fromMap(Map<String, dynamic> map) {
    return AttachmentModel(
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      type: map['type'] ?? 'document',
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'type': type,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}

// Doctor response model
class DoctorResponseModel {
  final String text;
  final DateTime respondedAt;
  final bool followUpNeeded;

  DoctorResponseModel({
    required this.text,
    required this.respondedAt,
    required this.followUpNeeded,
  });

  factory DoctorResponseModel.fromMap(Map<String, dynamic> map) {
    return DoctorResponseModel(
      text: map['text'] ?? '',
      respondedAt: (map['respondedAt'] as Timestamp).toDate(),
      followUpNeeded: map['followUpNeeded'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'respondedAt': Timestamp.fromDate(respondedAt),
      'followUpNeeded': followUpNeeded,
    };
  }
}
