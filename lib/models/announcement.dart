import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String message;
  final String courseName;
  final String lecturer;
  final String programmeCode;
  final int semester;
  final int section;
  final DateTime createdAt;

  Announcement({
    this.id = '',
    required this.title,
    required this.message,
    required this.courseName,
    required this.lecturer,
    required this.programmeCode,
    required this.semester,
    required this.section,
    required this.createdAt,
  });

  factory Announcement.fromMap(
      Map<String, dynamic> data, {
        String id = '',
      }) {
    final rawCreatedAt = data['createdAt'];

    DateTime createdAt;

    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else {
      createdAt = DateTime.now();
    }

    return Announcement(
      id: id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      courseName: data['courseName'] ?? '',
      lecturer: data['lecturer'] ?? '',
      programmeCode: data['programmeCode'] ?? '',
      semester: data['semester'] is int ? data['semester'] : 0,
      section: data['section'] is int ? data['section'] : 0,
      createdAt: createdAt,
    );
  }
}