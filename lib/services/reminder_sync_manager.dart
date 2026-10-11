import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_session.dart';
import '../utils/current_user_programme.dart';
import 'notification_service.dart';

class ReminderSyncManager extends StatefulWidget {
  final Widget child;

  const ReminderSyncManager({super.key, required this.child});

  @override
  State<ReminderSyncManager> createState() => _ReminderSyncManagerState();
}

class _ReminderSyncManagerState extends State<ReminderSyncManager> {
  StreamSubscription<QuerySnapshot>? _subscription;
  Map<String, ClassSession> _lastKnownClasses = {};
  int _reminderMinutes = 30;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() async {
    final enrollment = await getCurrentUserEnrollment();
    if (!isEnrollmentComplete(enrollment)) return;

    final prefs = await SharedPreferences.getInstance();
    _reminderMinutes = prefs.getInt('reminder_minutes') ?? 30;

    final query = FirebaseFirestore.instance
        .collection('classes')
        .where('programmeCode', isEqualTo: enrollment.programmeCode)
        .where('semester', isEqualTo: enrollment.semester)
        .where('section', isEqualTo: enrollment.section);

    _subscription = query.snapshots().listen(_handleSnapshot);
  }

  void _handleSnapshot(QuerySnapshot snapshot) {
    final newClasses = <String, ClassSession>{};
    for (final doc in snapshot.docs) {
      final session = ClassSession.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
      newClasses[session.id] = session;
    }

    // A class present before but missing now was deleted/cancelled.
    for (final oldId in _lastKnownClasses.keys) {
      if (!newClasses.containsKey(oldId)) {
        NotificationService.cancelClassReminder(oldId);
      }
    }

    // A class that's new, or whose relevant fields changed, needs its
    // reminder (re)scheduled under its own stable ID.
    for (final entry in newClasses.entries) {
      final id = entry.key;
      final session = entry.value;
      final previous = _lastKnownClasses[id];

      final isNewOrChanged = previous == null ||
          previous.day != session.day ||
          previous.startTime != session.startTime ||
          previous.endTime != session.endTime ||
          previous.room != session.room ||
          previous.classType != session.classType;

      if (isNewOrChanged) {
        NotificationService.scheduleSingleClassReminder(session, _reminderMinutes);
      }
    }

    _lastKnownClasses = newClasses;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}