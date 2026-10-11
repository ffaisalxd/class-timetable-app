import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/class_session.dart';
import '../models/programme.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialog.dart';
import '../utils/conflict_checker.dart';
import '../utils/academic_options.dart';
import '../utils/time_utils.dart';
import '../services/notification_service.dart';

class ClassFormPage extends StatefulWidget {
  final ClassSession? existingClass;

  const ClassFormPage({super.key, this.existingClass});

  @override
  State<ClassFormPage> createState() => _ClassFormPageState();
}

class _ClassFormPageState extends State<ClassFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _courseNameController;
  late final TextEditingController _roomController;
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late String _selectedDay;
  String? _selectedProgrammeCode;
  int? _selectedSemester;
  int? _selectedSection;
  late String _classType;

  bool _isLoading = false;

  bool get _isEditing => widget.existingClass != null;

  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingClass;
    _courseNameController = TextEditingController(text: existing?.courseName ?? '');
    _roomController = TextEditingController(text: existing?.room ?? '');
    _startTimeController = TextEditingController(text: existing?.startTime ?? '');
    _endTimeController = TextEditingController(text: existing?.endTime ?? '');
    _selectedDay = existing?.day ?? _weekdays.first;
    _selectedProgrammeCode = (existing?.programmeCode.isNotEmpty == true) ? existing!.programmeCode : null;
    _selectedSemester = (existing != null && existing.semester > 0) ? existing.semester : null;
    _selectedSection = (existing != null && existing.section > 0) ? existing.section : null;
    _classType = existing?.classType ?? 'physical';
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _roomController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final initial = parseTimeToMinutes(controller.text);
    final initialTimeOfDay = initial != null
        ? TimeOfDay(hour: initial ~/ 60, minute: initial % 60)
        : TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTimeOfDay,
    );

    if (picked == null) return;
    if (!mounted) return;

    final localizations = MaterialLocalizations.of(context);
    final formattedTime = localizations.formatTimeOfDay(
      picked,
      alwaysUse24HourFormat: false,
    );

    setState(() {
      controller.text = formattedTime;
    });
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final lecturerName = FirebaseAuth.instance.currentUser?.displayName ?? '';

    final result = await checkConflicts(
      day: _selectedDay,
      room: _roomController.text.trim(),
      lecturer: lecturerName,
      startTime: _startTimeController.text.trim(),
      endTime: _endTimeController.text.trim(),
      excludeId: widget.existingClass?.id,
    );

    if (!mounted) return;

    if (result.hasConflicts) {
      setState(() {
        _isLoading = false;
      });

      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Schedule Conflict'),
          content: Text(result.messages.join('\n\n')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Edit Details'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );

      if (proceed != true) return;

      setState(() {
        _isLoading = true;
      });
    }

    await _saveToFirestore(lecturerName);
  }

  Future<void> _saveToFirestore(String lecturerName) async {
    final data = {
      'courseName': _courseNameController.text.trim(),
      'lecturer': lecturerName,
      'room': _roomController.text.trim(),
      'startTime': _startTimeController.text.trim(),
      'endTime': _endTimeController.text.trim(),
      'day': _selectedDay,
      'programmeCode': _selectedProgrammeCode ?? '',
      'semester': _selectedSemester ?? 0,
      'section': _selectedSection ?? 0,
      'classType': _classType,
    };

    try {
      if (_isEditing) {
        final existing = widget.existingClass!;

        final String newStartTime =
        _startTimeController.text.trim();

        final String newEndTime =
        _endTimeController.text.trim();

        final String newRoom =
        _roomController.text.trim();

        final bool formatChanged =
            existing.classType != _classType;

        final bool scheduleChanged =
            existing.day != _selectedDay ||
                existing.startTime != newStartTime ||
                existing.endTime != newEndTime ||
                existing.room != newRoom;

        await FirebaseFirestore.instance
            .collection('classes')
            .doc(existing.id)
            .update(data);

        if (formatChanged || scheduleChanged) {
          String title;
          String message;

          //
          // Only the class format changed.
          //
          if (formatChanged && !scheduleChanged) {
            title = 'Class Format Updated';

            if (_classType == 'online') {
              message =
              '${existing.courseName} will now be conducted '
                  'online from $newStartTime to $newEndTime.';
            } else {
              message =
              '${existing.courseName} will now be held in '
                  '$newRoom from $newStartTime to $newEndTime.';
            }
          }

          //
          // Day, time, room, or multiple details changed.
          //
          else {
            title = 'Class Rescheduled';

            if (_classType == 'online') {
              message =
              '${existing.courseName} has been rescheduled to '
                  '$_selectedDay, $newStartTime - $newEndTime online.';
            } else {
              message =
              '${existing.courseName} has been rescheduled to '
                  '$_selectedDay, $newStartTime - $newEndTime '
                  'in $newRoom.';
            }
          }

          await NotificationService.showClassUpdate(
            title: title,
            message: message,
          );
        }
      } else {
        await FirebaseFirestore.instance
            .collection('classes')
            .add(data);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showAppDialog(
        context: context,
        title: 'Error',
        message: 'Something went wrong while saving. Please try again.',
        icon: Icons.error_outline,
        iconColor: AppColors.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Class' : 'Add Class')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _courseNameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Course Name', prefixIcon: Icon(Icons.menu_book_outlined)),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'physical', label: Text('Physical'), icon: Icon(Icons.meeting_room_outlined)),
                    ButtonSegment(value: 'online', label: Text('Online'), icon: Icon(Icons.videocam_outlined)),
                  ],
                  selected: {_classType},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _classType = selection.first;
                      if (_classType == 'online') {
                        _roomController.text = '';
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_classType == 'physical')
                  TextFormField(
                    controller: _roomController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Room / Venue', prefixIcon: Icon(Icons.location_on_outlined)),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                  )
                else
                  TextFormField(
                    controller: _roomController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Meeting Link', prefixIcon: Icon(Icons.link)),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDay,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Day', prefixIcon: Icon(Icons.calendar_today_outlined)),
                  items: _weekdays.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDay = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('programmes').snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    final programmes = docs
                        .map((doc) => Programme.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
                        .toList();

                    return DropdownButtonFormField<String>(
                      initialValue:
                      _selectedProgrammeCode,

                      isExpanded: true,

                      dropdownColor:
                      AppColors.surface,

                      style: const TextStyle(
                        color:
                        AppColors.textPrimary,
                      ),

                      decoration:
                      const InputDecoration(
                        labelText: 'Programme',
                        prefixIcon:
                        Icon(
                          Icons.school_outlined,
                        ),
                      ),

                      items:
                      programmes.map((p) {
                        return DropdownMenuItem<String>(
                          value: p.code,

                          child: Text(
                            '${p.code} - ${p.name}',
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),

                      selectedItemBuilder:
                          (context) {
                        return programmes.map((p) {
                          return Align(
                            alignment:
                            Alignment.centerLeft,
                            child: Text(
                              '${p.code} - ${p.name}',
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                            ),
                          );
                        }).toList();
                      },

                      onChanged: (value) {
                        setState(() {
                          _selectedProgrammeCode =
                              value;
                        });
                      },

                      validator: (value) =>
                      value == null
                          ? 'Please select a programme'
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedSemester,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Semester'),
                        items: kSemesterOptions
                            .map((s) => DropdownMenuItem(value: s, child: Text('Semester $s')))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSemester = value;
                          });
                        },
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedSection,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(labelText: 'Section'),
                        items: kSectionOptions
                            .map((s) => DropdownMenuItem(value: s, child: Text('Section $s')))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSection = value;
                          });
                        },
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startTimeController,
                        readOnly: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          prefixIcon: Icon(Icons.access_time_rounded),
                        ),
                        onTap: () => _pickTime(_startTimeController),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          if (parseTimeToMinutes(value) == null) return 'Invalid time';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeController,
                        readOnly: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          prefixIcon: Icon(Icons.access_time_rounded),
                        ),
                        onTap: () => _pickTime(_endTimeController),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          final end = parseTimeToMinutes(value);
                          if (end == null) return 'Invalid time';
                          final start = parseTimeToMinutes(_startTimeController.text);
                          if (start != null && end <= start) return 'Must be after start';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(_isEditing ? 'Save Changes' : 'Add Class'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}