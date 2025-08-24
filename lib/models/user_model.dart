import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a User.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final Timestamp? createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  /// Creates a User instance from a Firestore document.
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown User',
      email: data['email'] as String? ?? 'No email',
      role: data['role'] as String? ?? 'Student',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  /// Creates a User instance from a Map (for cache deserialization).
  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      id: data['id'] as String? ?? data['_id'] as String? ?? '',
      name: data['name'] as String? ?? 'Unknown User',
      email: data['email'] as String? ?? 'No email',
      role: data['role'] as String? ?? 'Student',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  /// Converts the User instance to a Map for Firestore updates.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt,
    };
  }
}