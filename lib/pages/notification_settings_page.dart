import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/class_session.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends State<NotificationSettingsPage> {
  int _selectedMinutes = 30;
  bool _isLoading = true;
  bool _isCustom = false;

  final TextEditingController _customController =
  TextEditingController();

  static const List<int> _presetOptions = [
    10,
    15,
    30,
    60,
  ];

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _loadPreference() async {
    final prefs =
    await SharedPreferences.getInstance();

    final saved =
        prefs.getInt('reminder_minutes') ??
            30;

    if (!mounted) return;

    setState(() {
      _selectedMinutes = saved;
      _isCustom =
      !_presetOptions.contains(saved);

      if (_isCustom) {
        _customController.text =
        '$saved';
      }

      _isLoading = false;
    });
  }

  Future<void> _savePreference(
      int minutes,
      ) async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setInt(
      'reminder_minutes',
      minutes,
    );

    if (!mounted) return;

    setState(() {
      _selectedMinutes = minutes;
      _isCustom =
      !_presetOptions.contains(
        minutes,
      );
    });

    await _rescheduleReminders(
      minutes,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Reminders set to $minutes minutes before class',
        ),
      ),
    );
  }

  Future<void> _rescheduleReminders(
      int minutes,
      ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final userDoc =
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = userDoc.data();

    if (data == null) {
      return;
    }

    final role =
    (data['role'] ?? '')
        .toString()
        .toLowerCase();

    List<ClassSession> classes = [];

    // =====================================================
    // STUDENT REMINDERS
    // =====================================================

    if (role == 'student') {
      final programmeCode =
      data['programmeCode'];

      final semester =
      data['semester'];

      final section =
      data['section'];

      if (programmeCode == null ||
          semester == null ||
          section == null) {
        return;
      }

      final snapshot =
      await FirebaseFirestore.instance
          .collection('classes')
          .where(
        'programmeCode',
        isEqualTo:
        programmeCode,
      )
          .where(
        'semester',
        isEqualTo:
        semester,
      )
          .where(
        'section',
        isEqualTo:
        section,
      )
          .get();

      classes = snapshot.docs
          .map(
            (doc) =>
            ClassSession.fromMap(
              doc.data(),
              id: doc.id,
            ),
      )
          .toList();
    }

    // =====================================================
    // LECTURER REMINDERS
    // =====================================================

    else if (role == 'lecturer') {
      final lecturerName =
      (data['name'] ??
          user.displayName ??
          '')
          .toString();

      if (lecturerName.isEmpty) {
        return;
      }

      final snapshot =
      await FirebaseFirestore.instance
          .collection('classes')
          .where(
        'lecturer',
        isEqualTo:
        lecturerName,
      )
          .get();

      classes = snapshot.docs
          .map(
            (doc) =>
            ClassSession.fromMap(
              doc.data(),
              id: doc.id,
            ),
      )
          .toList();
    }

    // Admin does not need class reminders.
    else {
      return;
    }

    await NotificationService
        .scheduleClassReminders(
      classes,
      minutes,
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
        ),
      ),
      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : ListView(
        padding:
        const EdgeInsets.all(24),
        children: [
          const Text(
            'Remind me before class',
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Choose how early you want to be notified. Default is 30 minutes.',
            style: TextStyle(
              color: AppColors
                  .textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          RadioGroup<int>(
            groupValue: _isCustom
                ? -1
                : _selectedMinutes,
            onChanged: (value) {
              if (value == null) {
                return;
              }

              if (value == -1) {
                setState(() {
                  _isCustom = true;
                });

                return;
              }

              setState(() {
                _isCustom = false;
              });

              _savePreference(
                value,
              );
            },
            child: Column(
              children: [
                ..._presetOptions.map(
                      (minutes) {
                    return RadioListTile<
                        int>(
                      value:
                      minutes,
                      title: Text(
                        '$minutes minutes before',
                      ),
                      activeColor:
                      AppColors
                          .primary,
                    );
                  },
                ),

                const RadioListTile<
                    int>(
                  value: -1,
                  title:
                  Text('Custom'),
                  activeColor:
                  AppColors
                      .primary,
                ),
              ],
            ),
          ),

          if (_isCustom)
            Padding(
              padding:
              const EdgeInsets
                  .only(
                left: 16,
                right: 16,
                bottom: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child:
                    TextField(
                      controller:
                      _customController,
                      keyboardType:
                      TextInputType
                          .number,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Minutes before class',
                        suffixText:
                        'min',
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  ElevatedButton(
                    onPressed: () {
                      final value =
                      int.tryParse(
                        _customController
                            .text
                            .trim(),
                      );

                      if (value ==
                          null ||
                          value <=
                              0) {
                        ScaffoldMessenger
                            .of(
                            context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Enter a valid number of minutes',
                            ),
                          ),
                        );

                        return;
                      }

                      _savePreference(
                        value,
                      );
                    },
                    child: const Text(
                      'Apply',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}