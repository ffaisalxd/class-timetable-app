import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<({String? programmeCode, int? semester, int? section})> getCurrentUserEnrollment() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return (programmeCode: null, semester: null, section: null);

  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final data = doc.data();

  final code = data?['programmeCode'];
  final semester = data?['semester'];
  final section = data?['section'];

  return (
  programmeCode: (code is String && code.isNotEmpty) ? code : null,
  semester: semester is int && semester > 0 ? semester : null,
  section: section is int && section > 0 ? section : null,
  );
}

bool isEnrollmentComplete(({String? programmeCode, int? semester, int? section}) enrollment) {
  return enrollment.programmeCode != null && enrollment.semester != null && enrollment.section != null;
}