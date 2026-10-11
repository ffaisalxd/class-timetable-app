import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/class_session.dart';
import '../theme/app_theme.dart';
import '../utils/subject_colors.dart';
import '../widgets/pill_tag.dart';
import '../widgets/glass_card.dart';
import '../widgets/modern_ui.dart';
import '../widgets/app_dialog.dart';
import '../services/notification_service.dart';

import 'class_form_page.dart';
import 'venue_availability_page.dart';

class MyClassesPage extends StatefulWidget {
  const MyClassesPage({super.key});

  @override
  State<MyClassesPage> createState() =>
      _MyClassesPageState();
}

class _MyClassesPageState extends State<MyClassesPage> {
  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = '';

  String get _lecturerName {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? '';
  }

  late final Stream<QuerySnapshot>
  _classesStream;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(
      BuildContext context,
      ClassSession session,
      ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Cancel this class?',
        ),
        content: Text(
          'This will remove "${session.courseName}" '
              'from the timetable.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Keep it'),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                await NotificationService
                    .cancelClassReminder(
                  session.id,
                );

                await FirebaseFirestore.instance
                    .collection('classes')
                    .doc(session.id)
                    .delete();

                await NotificationService.showClassUpdate(
                  title: 'Class Cancelled',
                  message:
                  '${session.courseName} scheduled for '
                      '${session.day}, ${session.startTime} - ${session.endTime} '
                      'has been cancelled.',
                );

                if (!context.mounted) return;

                showAppDialog(
                  context: context,
                  title: 'Class Removed',
                  message:
                  '"${session.courseName}" has been cancelled and removed from the timetable.',
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.primary,
                );
              } catch (e) {
                debugPrint(
                  'Failed to cancel class: $e',
                );
              }
            },
            child: const Text(
              'Cancel Class',
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _classesStream =
        FirebaseFirestore.instance
            .collection('classes')
            .where(
          'lecturer',
          isEqualTo:
          _lecturerName,
        )
            .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModernHero(
          eyebrow: 'Teaching schedule',
          title: 'My Classes',
          subtitle:
          'Manage sessions, rooms and class updates',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderAction(
                icon: Icons.meeting_room_outlined,
                tooltip: 'Venue availability',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const VenueAvailabilityPage(),
                    ),
                  );
                },
              ),

              const SizedBox(width: 8),

              _HeaderAction(
                icon: Icons.add_rounded,
                tooltip: 'Add class',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const ClassFormPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: SafeArea(
            top: false,
            child: StreamBuilder<QuerySnapshot>(
              stream: _classesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Something went wrong: '
                          '${snapshot.error}',
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs =
                    snapshot.data?.docs ?? [];

                final classes = docs
                    .map(
                      (doc) =>
                      ClassSession.fromMap(
                        doc.data()
                        as Map<String, dynamic>,
                        id: doc.id,
                      ),
                )
                    .toList();

                final query = _searchQuery
                    .trim()
                    .toLowerCase();

                final filteredClasses =
                classes.where((session) {
                  if (query.isEmpty) {
                    return true;
                  }

                  return session.courseName
                      .toLowerCase()
                      .contains(query) ||
                      session.room
                          .toLowerCase()
                          .contains(query) ||
                      session.day
                          .toLowerCase()
                          .contains(query) ||
                      session.programmeCode
                          .toLowerCase()
                          .contains(query) ||
                      session.classType
                          .toLowerCase()
                          .contains(query);
                }).toList();

                return ListView(
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    100,
                  ),
                  children: [
                    TextField(
                      controller:
                      _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText:
                        'Search course, room, programme or day',
                        prefixIcon:
                        const Icon(
                          Icons.search_rounded,
                        ),
                        suffixIcon:
                        _searchQuery.isEmpty
                            ? null
                            : IconButton(
                          onPressed: () {
                            _searchController
                                .clear();

                            setState(() {
                              _searchQuery =
                              '';
                            });
                          },
                          icon:
                          const Icon(
                            Icons
                                .close_rounded,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (classes.isEmpty)
                      const Padding(
                        padding:
                        EdgeInsets.only(
                          top: 80,
                        ),
                        child: Center(
                          child: Text(
                            'You have no classes yet. Tap + to add one.',
                            textAlign:
                            TextAlign.center,
                            style: TextStyle(
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ),
                      )
                    else if (filteredClasses
                        .isEmpty)
                      const Padding(
                        padding:
                        EdgeInsets.only(
                          top: 80,
                        ),
                        child: Center(
                          child: Text(
                            'No matching classes found.',
                            style: TextStyle(
                              color: AppColors
                                  .textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filteredClasses.map(
                            (session) {
                          final color =
                          colorForSubject(
                            session.courseName,
                          );

                          return GlassCard(
                            margin:
                            const EdgeInsets
                                .only(
                              bottom: 14,
                            ),
                            padding:
                            const EdgeInsets
                                .all(
                              18,
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration:
                                      BoxDecoration(
                                        color: color
                                            .withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                          12,
                                        ),
                                      ),
                                      child: Icon(
                                        session.classType ==
                                            'online'
                                            ? Icons
                                            .videocam_outlined
                                            : Icons
                                            .menu_book_rounded,
                                        color: color,
                                        size: 22,
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 14,
                                    ),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          Text(
                                            session
                                                .courseName,
                                            style:
                                            const TextStyle(
                                              fontWeight:
                                              FontWeight
                                                  .bold,
                                              fontSize:
                                              15,
                                              color:
                                              AppColors
                                                  .textPrimary,
                                            ),
                                          ),

                                          const SizedBox(
                                            height: 2,
                                          ),

                                          Text(
                                            session.classType ==
                                                'online'
                                                ? 'Online • ${session.startTime} - ${session.endTime}'
                                                : '${session.room} • ${session.startTime} - ${session.endTime}',
                                            style:
                                            const TextStyle(
                                              color:
                                              AppColors
                                                  .textSecondary,
                                              fontSize:
                                              13,
                                            ),
                                          ),

                                          const SizedBox(
                                            height: 3,
                                          ),

                                          Text(
                                            '${session.programmeCode} • Semester ${session.semester} • Section ${session.section}',
                                            style:
                                            const TextStyle(
                                              color:
                                              AppColors
                                                  .textSecondary,
                                              fontSize:
                                              11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    PillTag(
                                      label: session
                                          .day
                                          .toUpperCase(),
                                      color: color,
                                    ),
                                  ],
                                ),

                                Divider(
                                  height: 20,
                                  color: AppColors
                                      .glassBorder,
                                ),

                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator
                                            .push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                ClassFormPage(
                                                  existingClass:
                                                  session,
                                                ),
                                          ),
                                        );
                                      },
                                      icon:
                                      const Icon(
                                        Icons
                                            .edit_outlined,
                                        size: 18,
                                      ),
                                      label:
                                      const Text(
                                        'Edit',
                                      ),
                                    ),

                                    TextButton.icon(
                                      onPressed: () =>
                                          _confirmDelete(
                                            context,
                                            session,
                                          ),
                                      style:
                                      TextButton
                                          .styleFrom(
                                        foregroundColor:
                                        AppColors
                                            .error,
                                      ),
                                      icon:
                                      const Icon(
                                        Icons
                                            .delete_outline,
                                        size: 18,
                                      ),
                                      label:
                                      const Text(
                                        'Cancel',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(15),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white
                .withValues(
              alpha: .12,
            ),
            borderRadius:
            BorderRadius.circular(
              15,
            ),
            border: Border.all(
              color: Colors.white
                  .withValues(
                alpha: .13,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}