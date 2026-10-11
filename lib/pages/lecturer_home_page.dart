import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/class_session.dart';
import '../theme/app_theme.dart';
import '../utils/subject_colors.dart';
import '../utils/time_utils.dart';
import '../widgets/modern_ui.dart';
import '../services/notification_service.dart';

import 'notification_settings_page.dart';
import 'class_detail_page.dart';

const List<String> _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

class LecturerHomePage extends StatefulWidget {
  const LecturerHomePage({super.key});

  @override
  State<LecturerHomePage> createState() =>
      _LecturerHomePageState();
}

class _LecturerHomePageState
    extends State<LecturerHomePage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
          (_) async {
        await _scheduleLecturerReminders();
      },
    );
  }

  String get _todayName =>
      _weekdayNames[
      DateTime.now().weekday - 1];

  String get _todayFormatted {
    final now = DateTime.now();

    return '$_todayName, '
        '${now.day} '
        '${_monthNames[now.month - 1]}';
  }

  String get _fullDisplayName {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user?.displayName != null &&
        user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    if (user?.email != null) {
      return user!.email!
          .split('@')
          .first;
    }

    return 'Lecturer';
  }

  // =====================================================
  // SCHEDULE LECTURER CLASS REMINDERS
  // =====================================================

  Future<void>
  _scheduleLecturerReminders() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final userDoc =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();

      if (data == null) return;

      final lecturerName =
      (data['name'] ??
          user.displayName ??
          '')
          .toString()
          .trim();

      if (lecturerName.isEmpty) {
        return;
      }

      final prefs =
      await SharedPreferences
          .getInstance();

      final minutes =
          prefs.getInt(
            'reminder_minutes',
          ) ??
              30;

      final snapshot =
      await FirebaseFirestore.instance
          .collection('classes')
          .where(
        'lecturer',
        isEqualTo:
        lecturerName,
      )
          .get();

      final classes =
      snapshot.docs
          .map(
            (doc) =>
            ClassSession.fromMap(
              doc.data(),
              id: doc.id,
            ),
      )
          .toList();

      await NotificationService
          .scheduleClassReminders(
        classes,
        minutes,
      );

      debugPrint(
        'Lecturer reminders scheduled: '
            '${classes.length} classes, '
            '$minutes minutes before.',
      );
    } catch (e) {
      debugPrint(
        'Failed to schedule lecturer reminders: $e',
      );
    }
  }

  ClassSession? _findNextClass(
      List<ClassSession> todaysClasses,
      ) {
    final now = DateTime.now();

    final nowMinutes =
        now.hour * 60 + now.minute;

    ClassSession? next;
    int? nextStart;

    for (final session
    in todaysClasses) {
      final start =
      parseTimeToMinutes(
        session.startTime,
      );

      if (start == null) continue;

      if (start >= nowMinutes &&
          (nextStart == null ||
              start < nextStart)) {
        next = session;
        nextStart = start;
      }
    }

    return next;
  }

  Widget _heroAction({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
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
                .withValues(alpha: .12),
            borderRadius:
            BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white
                  .withValues(alpha: .13),
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

  Widget _nextTeachingCard(
      BuildContext context,
      ClassSession session,
      ) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ClassDetailPage(
                  session: session,
                ),
          ),
        );
      },
      child: Container(
        padding:
        const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white
              .withValues(alpha: .11),
          borderRadius:
          BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white
                .withValues(alpha: .14),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration:
              BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(
                  17,
                ),
              ),
              child: const Icon(
                Icons
                    .cast_for_education_rounded,
                color:
                AppColors.primaryDark,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  const Text(
                    'NEXT TEACHING SESSION',
                    style: TextStyle(
                      color:
                      Colors.white60,
                      fontSize: 9,
                      fontWeight:
                      FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    session.courseName,
                    maxLines: 1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      color:
                      Colors.white,
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    session.classType ==
                        'online'
                        ? 'Online • '
                        '${session.startTime} - '
                        '${session.endTime}'
                        : '${session.room} • '
                        '${session.startTime} - '
                        '${session.endTime}',
                    style: TextStyle(
                      color: Colors.white
                          .withValues(
                        alpha: .75,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .arrow_forward_ios_rounded,
              color: Colors.white60,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  Widget _teachingCard(
      BuildContext context,
      ClassSession session,
      ) {
    final color =
    colorForSubject(
      session.courseName,
    );

    return InkWell(
      borderRadius:
      BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ClassDetailPage(
                  session: session,
                ),
          ),
        );
      },
      child: Container(
        padding:
        const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(22),
          border: Border.all(
            color:
            AppColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 58,
              decoration:
              BoxDecoration(
                color: color,
                borderRadius:
                BorderRadius.circular(
                  99,
                ),
              ),
            ),

            const SizedBox(width: 14),

            Container(
              width: 44,
              height: 44,
              decoration:
              BoxDecoration(
                color:
                color.withValues(
                  alpha: .11,
                ),
                borderRadius:
                BorderRadius.circular(
                  14,
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
                size: 21,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    session.courseName,
                    maxLines: 1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.w800,
                      color: AppColors
                          .textPrimary,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .schedule_rounded,
                        size: 14,
                        color: AppColors
                            .textSecondary,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Text(
                        '${session.startTime} - '
                            '${session.endTime}',
                        style:
                        const TextStyle(
                          fontSize: 11.5,
                          color: AppColors
                              .textSecondary,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      const Icon(
                        Icons
                            .location_on_outlined,
                        size: 14,
                        color: AppColors
                            .textSecondary,
                      ),

                      const SizedBox(
                        width: 4,
                      ),

                      Flexible(
                        child: Text(
                          session.classType ==
                              'online'
                              ? 'Online'
                              : session.room,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 11.5,
                            color: AppColors
                                .textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .chevron_right_rounded,
              color:
              AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return StreamBuilder<QuerySnapshot>(
      stream:
      FirebaseFirestore.instance
          .collection('classes')
          .where(
        'lecturer',
        isEqualTo:
        _fullDisplayName,
      )
          .snapshots(),

      builder:
          (context, snapshot) {
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
            child:
            CircularProgressIndicator(),
          );
        }

        final docs =
            snapshot.data?.docs ?? [];

        final allClasses =
        docs.map(
              (doc) {
            return ClassSession.fromMap(
              doc.data()
              as Map<String, dynamic>,
              id: doc.id,
            );
          },
        ).toList();

        final todaysClasses =
        allClasses
            .where(
              (c) =>
          c.day ==
              _todayName,
        )
            .toList();

        final roomsToday =
            todaysClasses
                .map(
                  (c) => c.room,
            )
                .where(
                  (r) =>
              r.isNotEmpty,
            )
                .toSet()
                .length;

        final nextClass =
        _findNextClass(
          todaysClasses,
        );

        return Column(
          children: [
            ModernHero(
              eyebrow:
              'Lecturer workspace',

              title:
              'Welcome, $_fullDisplayName',

              subtitle:
              _todayFormatted,

              trailing:
              _heroAction(
                icon: Icons
                    .notifications_none_rounded,
                tooltip:
                'Reminder settings',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const NotificationSettingsPage(),
                    ),
                  );

                  // Reschedule reminders
                  // after returning from settings.
                  await _scheduleLecturerReminders();
                },
              ),

              bottom:
              nextClass != null
                  ? _nextTeachingCard(
                context,
                nextClass,
              )
                  : Container(
                padding:
                const EdgeInsets
                    .all(
                  16,
                ),
                decoration:
                BoxDecoration(
                  color: Colors
                      .white
                      .withValues(
                    alpha:
                    .10,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    20,
                  ),
                  border:
                  Border.all(
                    color: Colors
                        .white
                        .withValues(
                      alpha:
                      .12,
                    ),
                  ),
                ),
                child:
                const Row(
                  children: [
                    Icon(
                      Icons
                          .event_available_rounded,
                      color:
                      Colors
                          .white70,
                    ),
                    SizedBox(
                      width:
                      10,
                    ),
                    Text(
                      'No more teaching sessions today',
                      style:
                      TextStyle(
                        color:
                        Colors
                            .white,
                        fontWeight:
                        FontWeight
                            .w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SafeArea(
                top: false,
                child: ListView(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    20,
                    18,
                    20,
                    108,
                  ),
                  children: [
                    Row(
                      children: [
                        MetricTile(
                          icon: Icons
                              .today_rounded,
                          value:
                          '${todaysClasses.length}',
                          label:
                          'Classes today',
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        MetricTile(
                          icon: Icons
                              .date_range_rounded,
                          value:
                          '${allClasses.length}',
                          label:
                          'Weekly load',
                          color:
                          const Color(
                            0xFF5B6EE1,
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        MetricTile(
                          icon: Icons
                              .meeting_room_outlined,
                          value:
                          '$roomsToday',
                          label:
                          'Rooms today',
                          color:
                          AppColors
                              .success,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 26,
                    ),

                    const SectionHeading(
                      title:
                      "Today's teaching",
                      subtitle:
                      'Your sessions for the day',
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    if (todaysClasses
                        .isEmpty)
                      const SurfacePanel(
                        child: Padding(
                          padding:
                          EdgeInsets
                              .symmetric(
                            vertical: 22,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons
                                    .free_breakfast_outlined,
                                size: 34,
                                color:
                                AppColors
                                    .primary,
                              ),

                              SizedBox(
                                height: 10,
                              ),

                              Text(
                                'No classes scheduled today',
                                style:
                                TextStyle(
                                  fontWeight:
                                  FontWeight
                                      .w800,
                                  color:
                                  AppColors
                                      .textPrimary,
                                ),
                              ),

                              SizedBox(
                                height: 4,
                              ),

                              Text(
                                'Your teaching schedule is clear for today.',
                                style:
                                TextStyle(
                                  color:
                                  AppColors
                                      .textSecondary,
                                  fontSize:
                                  12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...todaysClasses.map(
                            (session) =>
                            Padding(
                              padding:
                              const EdgeInsets
                                  .only(
                                bottom: 10,
                              ),
                              child:
                              _teachingCard(
                                context,
                                session,
                              ),
                            ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}