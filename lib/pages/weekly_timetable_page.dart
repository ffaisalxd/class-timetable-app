import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/class_session.dart';
import '../theme/app_theme.dart';
import '../utils/current_user_programme.dart';
import '../utils/subject_colors.dart';
import '../utils/time_utils.dart';
import '../widgets/modern_ui.dart';

import 'class_detail_page.dart';

class WeeklyTimetablePage extends StatefulWidget {
  const WeeklyTimetablePage({super.key});

  @override
  State<WeeklyTimetablePage> createState() =>
      _WeeklyTimetablePageState();
}

class _WeeklyTimetablePageState
    extends State<WeeklyTimetablePage> {
  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  late String _selectedDay;

  @override
  void initState() {
    super.initState();

    final todayIndex =
        DateTime.now().weekday - 1;

    _selectedDay =
    _days[todayIndex];
  }

  String _shortDay(String day) {
    switch (day) {
      case 'Monday':
        return 'Mon';
      case 'Tuesday':
        return 'Tue';
      case 'Wednesday':
        return 'Wed';
      case 'Thursday':
        return 'Thu';
      case 'Friday':
        return 'Fri';
      case 'Saturday':
        return 'Sat';
      case 'Sunday':
        return 'Sun';
      default:
        return day;
    }
  }

  List<ClassSession> _sortClasses(
      List<ClassSession> classes,
      ) {
    classes.sort((a, b) {
      final aTime =
          parseTimeToMinutes(
            a.startTime,
          ) ??
              0;

      final bTime =
          parseTimeToMinutes(
            b.startTime,
          ) ??
              0;

      return aTime.compareTo(bTime);
    });

    return classes;
  }

  Widget _classCard(
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
        margin:
        const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
        const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            22,
          ),
          border: Border.all(
            color:
            AppColors.glassBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 78,
              decoration:
              BoxDecoration(
                color: color,
                borderRadius:
                BorderRadius.circular(
                  99,
                ),
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
                    session.courseName,
                    maxLines: 2,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 15,
                      fontWeight:
                      FontWeight.w800,
                      color: AppColors
                          .textPrimary,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .schedule_rounded,
                        size: 15,
                        color: AppColors
                            .textSecondary,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          '${session.startTime} - ${session.endTime}',
                          style:
                          const TextStyle(
                            fontSize: 12,
                            fontWeight:
                            FontWeight
                                .w600,
                            color: AppColors
                                .textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Row(
                    children: [
                      Icon(
                        session.classType ==
                            'online'
                            ? Icons
                            .videocam_outlined
                            : Icons
                            .location_on_outlined,
                        size: 15,
                        color: AppColors
                            .textSecondary,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          session.classType ==
                              'online'
                              ? 'Online class'
                              : session.room,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 12,
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

            const SizedBox(
              width: 8,
            ),

            Container(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration:
              BoxDecoration(
                color:
                color.withValues(
                  alpha: .10,
                ),
                borderRadius:
                BorderRadius.circular(
                  999,
                ),
              ),
              child: Text(
                session.classType ==
                    'online'
                    ? 'ONLINE'
                    : 'PHYSICAL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                  FontWeight.w800,
                  color: color,
                ),
              ),
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
    return FutureBuilder<
        ({
        String? programmeCode,
        int? semester,
        int? section,
        })>(
      future:
      getCurrentUserEnrollment(),
      builder:
          (context, enrollmentSnapshot) {
        if (enrollmentSnapshot
            .connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
            CircularProgressIndicator(),
          );
        }

        final enrollment =
            enrollmentSnapshot.data;

        if (enrollment == null ||
            !isEnrollmentComplete(
              enrollment,
            )) {
          return const Column(
            children: [
              ModernHero(
                eyebrow: 'Schedule',
                title:
                'Weekly Timetable',
                subtitle:
                'View your classes for the week',
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding:
                    EdgeInsets.all(
                      24,
                    ),
                    child: Text(
                      'Your programme, semester, or section is not set up yet.',
                      textAlign:
                      TextAlign
                          .center,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return StreamBuilder<
            QuerySnapshot>(
          stream:
          FirebaseFirestore.instance
              .collection(
            'classes',
          )
              .where(
            'programmeCode',
            isEqualTo:
            enrollment
                .programmeCode,
          )
              .where(
            'semester',
            isEqualTo:
            enrollment
                .semester,
          )
              .where(
            'section',
            isEqualTo:
            enrollment
                .section,
          )
              .snapshots(),

          builder:
              (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load timetable: ${snapshot.error}',
                ),
              );
            }

            if (snapshot
                .connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child:
                CircularProgressIndicator(),
              );
            }

            final classes =
            (snapshot.data?.docs ??
                [])
                .map(
                  (doc) =>
                  ClassSession
                      .fromMap(
                    doc.data()
                    as Map<
                        String,
                        dynamic>,
                    id: doc.id,
                  ),
            )
                .toList();

            final selectedClasses =
            _sortClasses(
              classes
                  .where(
                    (session) =>
                session.day ==
                    _selectedDay,
              )
                  .toList(),
            );

            return Column(
              children: [
                const ModernHero(
                  eyebrow: 'Schedule',
                  title:
                  'Weekly Timetable',
                  subtitle:
                  'View your classes throughout the week',
                ),

                Padding(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    16,
                    18,
                    16,
                    8,
                  ),
                  child:
                  SingleChildScrollView(
                    scrollDirection:
                    Axis.horizontal,
                    child: Row(
                      children:
                      _days.map(
                            (day) {
                          final selected =
                              _selectedDay ==
                                  day;

                          return Padding(
                            padding:
                            const EdgeInsets
                                .only(
                              right: 8,
                            ),
                            child:
                            ChoiceChip(
                              label: Text(
                                _shortDay(
                                  day,
                                ),
                              ),
                              selected:
                              selected,
                              onSelected:
                                  (_) {
                                setState(
                                      () {
                                    _selectedDay =
                                        day;
                                  },
                                );
                              },
                              selectedColor:
                              AppColors
                                  .primary,
                              labelStyle:
                              TextStyle(
                                color: selected
                                    ? Colors
                                    .white
                                    : AppColors
                                    .textPrimary,
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                          );
                        },
                      ).toList(),
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
                        12,
                        20,
                        110,
                      ),
                      children: [
                        SectionHeading(
                          title:
                          _selectedDay,
                          subtitle:
                          '${selectedClasses.length} '
                              '${selectedClasses.length == 1 ? 'class' : 'classes'} scheduled',
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        if (selectedClasses
                            .isEmpty)
                          const SurfacePanel(
                            child: Padding(
                              padding:
                              EdgeInsets
                                  .symmetric(
                                vertical:
                                36,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons
                                        .event_available_rounded,
                                    size: 38,
                                    color:
                                    AppColors
                                        .primary,
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    'No classes scheduled',
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
                                    'Enjoy your free time.',
                                    style:
                                    TextStyle(
                                      color:
                                      AppColors
                                          .textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...selectedClasses
                              .map(
                                (session) =>
                                _classCard(
                                  context,
                                  session,
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
      },
    );
  }
}