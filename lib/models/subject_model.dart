import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a Subject.
class Subject {
  final String id;
  final String name;
  final String description;
  final String? assignedKpId;
  final bool isActive;
  final String? status;
  final Timestamp? createdAt;

  Subject({
    required this.id,
    required this.name,
    required this.description,
    this.assignedKpId,
    required this.isActive,
    this.status,
    this.createdAt,
  });

  /// Creates a Subject instance from a Firestore document.
  factory Subject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Subject(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Subject',
      description: data['description'] as String? ?? 'No description available.',
      assignedKpId: data['assignedKpId'] as String?,
      isActive: data['isActive'] as bool? ?? false,
      status: data['status'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  /// Converts the Subject instance to a Map for Firestore updates.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'assignedKpId': assignedKpId,
      'isActive': isActive,
      'status': status,
      'createdAt': createdAt,
    };
  }
}