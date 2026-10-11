import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/class_session.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/academic_options.dart';
import '../widgets/app_dialog.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() =>
      _EditProfilePageState();
}

class _EditProfilePageState
    extends State<EditProfilePage> {
  late final TextEditingController _nameController;

  File? _pickedImage;
  String? _existingPhotoUrl;

  String _role = '';
  String? _programmeCode;
  int? _semester;
  int? _section;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    _nameController = TextEditingController(
      text: user?.displayName ?? '',
    );

    _existingPhotoUrl = user?.photoURL;

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      if (!mounted) return;

      setState(() {
        _role =
            (data['role'] ?? '').toString().toLowerCase();

        _programmeCode =
            data['programmeCode']?.toString();

        final semester = data['semester'];
        final section = data['section'];

        _semester =
        semester is int ? semester : null;

        _section =
        section is int ? section : null;

        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Failed to load profile information: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (picked == null) return;

    if (!mounted) return;

    setState(() {
      _pickedImage = File(picked.path);
    });
  }

  Future<void> _refreshStudentReminders() async {
    if (_role != 'student' ||
        _programmeCode == null ||
        _semester == null ||
        _section == null) {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where(
        'programmeCode',
        isEqualTo: _programmeCode,
      )
          .where(
        'semester',
        isEqualTo: _semester,
      )
          .where(
        'section',
        isEqualTo: _section,
      )
          .get();

      final classes = snapshot.docs
          .map(
            (doc) => ClassSession.fromMap(
          doc.data(),
          id: doc.id,
        ),
      )
          .toList();

      final prefs =
      await SharedPreferences.getInstance();

      final reminderMinutes =
          prefs.getInt('reminder_minutes') ?? 30;

      await NotificationService
          .scheduleClassReminders(
        classes,
        reminderMinutes,
      );
    } catch (e) {
      debugPrint(
        'Failed to refresh student reminders: $e',
      );
    }
  }

  Future<void> _handleSave() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final name = _nameController.text.trim();

    if (name.isEmpty) {
      showAppDialog(
        context: context,
        title: 'Name Required',
        message: 'Please enter your name.',
        icon: Icons.error_outline,
        iconColor: AppColors.error,
      );

      return;
    }

    if (_role == 'student' &&
        (_semester == null || _section == null)) {
      showAppDialog(
        context: context,
        title: 'Student Information Required',
        message:
        'Please select your semester and section.',
        icon: Icons.error_outline,
        iconColor: AppColors.error,
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? photoUrl = _existingPhotoUrl;

      if (_pickedImage != null) {
        try {
          final ref = FirebaseStorage.instance
              .ref()
              .child(
            'profile_pictures/${user.uid}.jpg',
          );

          await ref.putFile(
            _pickedImage!,
            SettableMetadata(
              contentType: 'image/jpeg',
            ),
          );

          photoUrl = await ref.getDownloadURL();
        } on FirebaseException catch (e) {
          debugPrint(
            'Profile image upload failed: '
                '${e.code} - ${e.message}',
          );

          if (!mounted) return;

          showAppDialog(
            context: context,
            title: 'Upload Failed',
            message:
            e.message ??
                'The profile picture could not be uploaded.',
            icon: Icons.error_outline,
            iconColor: AppColors.error,
          );

          return;
        }
      }

      await user.updateDisplayName(name);

      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      final updateData = <String, dynamic>{
        'name': name,
        'photoUrl': ?photoUrl,
      };

      if (_role == 'student') {
        updateData.addAll({
          'semester': _semester,
          'section': _section,
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        updateData,
        SetOptions(merge: true),
      );

      if (_role == 'student') {
        await _refreshStudentReminders();
      }

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      debugPrint(
        'Failed to save profile: $e',
      );

      if (!mounted) return;

      showAppDialog(
        context: context,
        title: 'Error',
        message:
        'Something went wrong while saving. Please try again.',
        icon: Icons.error_outline,
        iconColor: AppColors.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor:
                        AppColors.primary
                            .withValues(
                          alpha: 0.15,
                        ),
                        backgroundImage:
                        _pickedImage != null
                            ? FileImage(
                          _pickedImage!,
                        )
                            : _existingPhotoUrl !=
                            null
                            ? NetworkImage(
                          _existingPhotoUrl!,
                        )
                            : null,
                        child: _pickedImage ==
                            null &&
                            _existingPhotoUrl ==
                                null
                            ? Text(
                          _nameController
                              .text
                              .isNotEmpty
                              ? _nameController
                              .text[0]
                              .toUpperCase()
                              : '?',
                          style:
                          const TextStyle(
                            fontSize: 36,
                            fontWeight:
                            FontWeight
                                .w800,
                            color: AppColors
                                .primary,
                          ),
                        )
                            : null,
                      ),

                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration:
                          const BoxDecoration(
                            color:
                            AppColors.primary,
                            shape:
                            BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons
                                .camera_alt_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: TextButton(
                  onPressed: _pickImage,
                  child: const Text(
                    'Change Photo',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller:
                _nameController,
                decoration:
                const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(
                    Icons
                        .person_outline_rounded,
                  ),
                ),
              ),

              if (_role == 'student') ...[
                const SizedBox(height: 18),

                TextFormField(
                  initialValue:
                  _programmeCode ?? '',
                  enabled: false,
                  decoration:
                  const InputDecoration(
                    labelText: 'Programme',
                    prefixIcon: Icon(
                      Icons.school_outlined,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<int>(
                  initialValue:
                  _semester,
                  decoration:
                  const InputDecoration(
                    labelText: 'Semester',
                    prefixIcon: Icon(
                      Icons
                          .layers_outlined,
                    ),
                  ),
                  items: kSemesterOptions
                      .map(
                        (semester) =>
                        DropdownMenuItem(
                          value: semester,
                          child: Text(
                            'Semester $semester',
                          ),
                        ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _semester = value;
                    });
                  },
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<int>(
                  initialValue:
                  _section,
                  decoration:
                  const InputDecoration(
                    labelText: 'Section',
                    prefixIcon: Icon(
                      Icons
                          .groups_outlined,
                    ),
                  ),
                  items: kSectionOptions
                      .map(
                        (section) =>
                        DropdownMenuItem(
                          value: section,
                          child: Text(
                            'Section $section',
                          ),
                        ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _section = value;
                    });
                  },
                ),

                const SizedBox(height: 8),

                const Text(
                  'Changing your semester or section will update the timetable and reminders shown for your account.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color:
                    AppColors.textSecondary,
                  ),
                ),
              ],

              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed:
                _isSaving
                    ? null
                    : _handleSave,
                icon: _isSaving
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
                  Icons
                      .save_outlined,
                ),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : 'Save Changes',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}