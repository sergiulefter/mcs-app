import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

class ConsultationModel {
  final String id;
  final String patientId;
  final String? doctorId; // Optional - can be null if not yet assigned
  final String status; // "pending" | "in_review" | "info_requested" | "completed" | "cancelled"
  final String urgency; // "normal" | "urgent" | "emergency"
  final String title;
  final String description;
  final List<AttachmentModel> attachments;
  final DoctorResponseModel? doctorResponse;
  final List<InfoRequestModel> infoRequests;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime termsAcceptedAt;

  // Cached doctor info (not from Firestore, fetched separately)
  String? doctorName;
  String? doctorSpecialty;
  String? patientName;
  String? patientEmail;

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
    this.infoRequests = const [],
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.termsAcceptedAt,
    this.doctorName,
    this.doctorSpecialty,
    this.patientName,
    this.patientEmail,
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
      infoRequests: (data['infoRequests'] as List<dynamic>?)
              ?.map((e) => InfoRequestModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      completedAt: data['completedAt'] != null
          ? _parseDate(data['completedAt'])
          : null,
      termsAcceptedAt: _parseDate(data['termsAcceptedAt']),
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
      'infoRequests': infoRequests.map((info) => info.toMap()).toList(),
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
    List<InfoRequestModel>? infoRequests,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? termsAcceptedAt,
    String? doctorName,
    String? doctorSpecialty,
    String? patientName,
    String? patientEmail,
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
      infoRequests: infoRequests ?? this.infoRequests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      patientName: patientName ?? this.patientName,
      patientEmail: patientEmail ?? this.patientEmail,
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
      uploadedAt: _parseDate(map['uploadedAt']),
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
  final String? recommendations;
  final DateTime respondedAt;
  final bool followUpNeeded;
  final List<AttachmentModel> responseAttachments;

  DoctorResponseModel({
    required this.text,
    this.recommendations,
    required this.respondedAt,
    required this.followUpNeeded,
    this.responseAttachments = const [],
  });

  factory DoctorResponseModel.fromMap(Map<String, dynamic> map) {
    return DoctorResponseModel(
      text: map['text'] ?? '',
      respondedAt: _parseDate(map['respondedAt']),
      followUpNeeded: map['followUpNeeded'] ?? false,
      recommendations: map['recommendations'],
      responseAttachments: (map['responseAttachments'] as List<dynamic>?)
              ?.map((e) => AttachmentModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'recommendations': recommendations,
      'respondedAt': Timestamp.fromDate(respondedAt),
      'followUpNeeded': followUpNeeded,
      'responseAttachments':
          responseAttachments.map((attachment) => attachment.toMap()).toList(),
    };
  }
}

// Info request model
class InfoRequestModel {
  final String message;
  final List<String> questions;
  final String doctorId;
  final DateTime requestedAt;

  InfoRequestModel({
    required this.message,
    required this.questions,
    required this.doctorId,
    required this.requestedAt,
  });

  factory InfoRequestModel.fromMap(Map<String, dynamic> map) {
    return InfoRequestModel(
      message: map['message'] ?? '',
      questions: (map['questions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      doctorId: map['doctorId'] ?? '',
      requestedAt: _parseDate(map['requestedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'questions': questions,
      'doctorId': doctorId,
      'requestedAt': Timestamp.fromDate(requestedAt),
    };
  }
}

// Extension for consultation color helpers
extension ConsultationColors on ConsultationModel {
  Color getStatusColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    switch (status) {
      case 'pending':
        return semantic.warning;
      case 'in_review':
        return colorScheme.primary;
      case 'info_requested':
        return semantic.warning;
      case 'completed':
        return semantic.success;
      case 'cancelled':
        return semantic.error;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }
}
