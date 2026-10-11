import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/class_session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialog.dart';

class AnnouncementFormPage extends StatefulWidget {
  const AnnouncementFormPage({super.key});

  @override
  State<AnnouncementFormPage> createState() =>
      _AnnouncementFormPageState();
}

class _AnnouncementFormPageState
    extends State<AnnouncementFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String? _selectedClassId;
  ClassSession? _selectedClass;

  bool _isSending = false;

  String get _lecturerName {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();

    super.dispose();
  }

  Future<void> _sendAnnouncement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClass == null) {
      showAppDialog(
        context: context,
        title: 'Select Class',
        message: 'Please select a class before sending the announcement.',
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.accent,
      );

      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final selectedClass = _selectedClass!;

      await FirebaseFirestore.instance
          .collection('announcements')
          .add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),

        'courseId': selectedClass.id,
        'courseName': selectedClass.courseName,

        'lecturerId':
        FirebaseAuth.instance.currentUser?.uid ?? '',
        'lecturer': _lecturerName,

        'programmeCode': selectedClass.programmeCode,
        'semester': selectedClass.semester,
        'section': selectedClass.section,

        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showAppDialog(
        context: context,
        title: 'Announcement Sent',
        message:
        'The announcement has been sent to ${selectedClass.courseName}.',
        icon: Icons.check_circle_outline,
        iconColor: AppColors.primary,
      );

      _titleController.clear();
      _messageController.clear();

      setState(() {
        _selectedClass = null;
        _selectedClassId = null;
      });
    } catch (e) {
      if (!mounted) return;

      showAppDialog(
        context: context,
        title: 'Error',
        message:
        'Something went wrong while sending the announcement. Please try again.',
        icon: Icons.error_outline,
        iconColor: AppColors.error,
      );

      debugPrint('Announcement error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Announcement'),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classes')
              .where(
            'lecturer',
            isEqualTo: _lecturerName,
          )
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load classes: ${snapshot.error}',
                ),
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            final classes = docs
                .map(
                  (doc) => ClassSession.fromMap(
                doc.data()
                as Map<String, dynamic>,
                id: doc.id,
              ),
            )
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Send Announcement',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Choose a class and send an update to the students.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedClassId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Class',
                        prefixIcon: Icon(
                          Icons.class_outlined,
                        ),
                      ),
                      items: classes.map((session) {
                        return DropdownMenuItem<String>(
                          value: session.id,
                          child: Text(
                            '${session.courseName} • '
                                '${session.programmeCode} '
                                'S${session.semester}-${session.section}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        final selected = classes.firstWhere(
                              (session) => session.id == value,
                        );

                        setState(() {
                          _selectedClassId = value;
                          _selectedClass = selected;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a class';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _titleController,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Announcement Title',
                        prefixIcon:
                        Icon(Icons.title_rounded),
                        hintText:
                        'Example: Bring Your Laptop',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter a title';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _messageController,
                      minLines: 5,
                      maxLines: 8,
                      maxLength: 500,
                      decoration:
                      const InputDecoration(
                        labelText: 'Message',
                        alignLabelWithHint: true,
                        prefixIcon:
                        Icon(Icons.message_outlined),
                        hintText:
                        'Write your announcement here...',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter a message';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    if (_selectedClass != null)
                      Container(
                        padding:
                        const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary
                              .withValues(
                            alpha: 0.08,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                          border: Border.all(
                            color:
                            AppColors.glassBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recipients',
                              style: TextStyle(
                                fontWeight:
                                FontWeight.w600,
                                color:
                                AppColors.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              '${_selectedClass!.programmeCode} • '
                                  'Semester ${_selectedClass!.semester} • '
                                  'Section ${_selectedClass!.section}',
                              style: const TextStyle(
                                color:
                                AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: _isSending
                          ? null
                          : _sendAnnouncement,
                      icon: _isSending
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.send_rounded,
                      ),
                      label: Text(
                        _isSending
                            ? 'Sending...'
                            : 'Send Announcement',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}