import 'package:cloud_firestore/cloud_firestore.dart';
import 'time_utils.dart';

class ConflictResult {
  final List<String> messages;
  ConflictResult(this.messages);
  bool get hasConflicts => messages.isNotEmpty;
}

Future<ConflictResult> checkConflicts({
  required String day,
  required String room,
  required String lecturer,
  required String startTime,
  required String endTime,
  String? excludeId,
}) async {
  final newStart = parseTimeToMinutes(startTime);
  final newEnd = parseTimeToMinutes(endTime);
  if (newStart == null || newEnd == null) return ConflictResult([]);

  final snapshot = await FirebaseFirestore.instance
      .collection('classes')
      .where('day', isEqualTo: day)
      .get();

  final messages = <String>[];

  for (final doc in snapshot.docs) {
    if (doc.id == excludeId) continue;

    final data = doc.data();
    final existingStart = parseTimeToMinutes(data['startTime'] ?? '');
    final existingEnd = parseTimeToMinutes(data['endTime'] ?? '');
    if (existingStart == null || existingEnd == null) continue;

    final overlaps = newStart < existingEnd && newEnd > existingStart;
    if (!overlaps) continue;

    if (data['room'] == room) {
      messages.add(
        'Room "$room" is already booked for "${data['courseName']}" (${data['startTime']} - ${data['endTime']}).',
      );
    }
    if (data['lecturer'] == lecturer) {
      messages.add(
        'You already have "${data['courseName']}" at this time (${data['startTime']} - ${data['endTime']}).',
      );
    }
  }

  return ConflictResult(messages);
}