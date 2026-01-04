import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;

  // Extended profile fields
  final DateTime? dateOfBirth;
  final String? gender;
  final String? phone;
  final String preferredLanguage;
  final String userType;
  final bool profileCompleted;

  // Medical Basics
  final String? height;
  final String? weight;
  final String? bloodType;

  // Runtime flag - set when user is loaded from doctors collection
  // This is NOT stored in Firestore
  final bool isDoctor;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.preferredLanguage = 'en',
    this.userType = 'patient',
    this.profileCompleted = false,
    this.height,
    this.weight,
    this.bloodType,
    this.isDoctor = false,
  });

  // Create UserModel from Firebase User
  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      dateOfBirth: _parseDateTime(map['dateOfBirth']),
      gender: map['gender'],
      phone: map['phone'],
      preferredLanguage: map['preferredLanguage'] ?? 'en',
      userType: map['userType'] ?? 'patient',
      profileCompleted: map['profileCompleted'] ?? false,
      height: map['height'],
      weight: map['weight'],
      bloodType: map['bloodType'],
    );
  }

  /// Parse DateTime from various formats (String, Timestamp, or null)
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'gender': gender,
      'phone': phone,
      'preferredLanguage': preferredLanguage,
      'userType': userType,
      'profileCompleted': profileCompleted,
      'height': height,
      'weight': weight,
      'bloodType': bloodType,
    };
  }

  // Copy with method for immutability
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? dateOfBirth,
    String? gender,
    String? phone,
    String? preferredLanguage,
    String? userType,
    bool? profileCompleted,
    String? height,
    String? weight,
    String? bloodType,
    bool? isDoctor,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      userType: userType ?? this.userType,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bloodType: bloodType ?? this.bloodType,
      isDoctor: isDoctor ?? this.isDoctor,
    );
  }

  /// Value-based equality for Set deduplication
  @override
  bool operator ==(Object other) => other is UserModel && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;
}
