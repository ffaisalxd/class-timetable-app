import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/class_session.dart';
import '../theme/app_theme.dart';
import '../utils/subject_colors.dart';
import '../utils/current_user_programme.dart';
import '../widgets/modern_ui.dart';
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

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  String get _selectedWeekdayName =>
      _weekdayNames[_selectedDay.weekday - 1];

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String _shortDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  List<ClassSession> _sortClasses(
      List<ClassSession> classes,
      ) {
    classes.sort((a, b) {
      return a.startTime.compareTo(b.startTime);
    });

    return classes;
  }

  Widget _buildClassCard(
      BuildContext context,
      ClassSession session,
      ) {
    final color =
    colorForSubject(session.courseName);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.glassBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDeep
                  .withValues(
                alpha: 0.04,
              ),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 74,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                BorderRadius.circular(99),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.courseName,
                          maxLines: 2,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w800,
                            color:
                            AppColors.textPrimary,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(
                            alpha: 0.10,
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
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 9),

                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color:
                        AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${session.startTime} - ${session.endTime}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w600,
                          color:
                          AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(
                        session.classType ==
                            'online'
                            ? Icons.videocam_outlined
                            : Icons
                            .location_on_outlined,
                        size: 15,
                        color:
                        AppColors.textSecondary,
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          session.classType ==
                              'online'
                              ? 'Online class'
                              : session.room,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color:
                            AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            const Padding(
              padding: EdgeInsets.only(
                top: 24,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color:
                AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyAgenda() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius:
                BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No classes scheduled',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You have no classes on $_selectedWeekdayName.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:
                AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<
        ({
        String? programmeCode,
        int? semester,
        int? section,
        })>(
      future: getCurrentUserEnrollment(),
      builder: (
          context,
          enrollmentSnapshot,
          ) {
        if (enrollmentSnapshot.connectionState ==
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
                title: 'Calendar',
                subtitle:
                'View your academic timetable',
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding:
                    EdgeInsets.all(24),
                    child: Text(
                      'Your programme, semester, or section is not set up yet. Please contact an admin.',
                      textAlign:
                      TextAlign.center,
                      style: TextStyle(
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return StreamBuilder<
            QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classes')
              .where(
            'programmeCode',
            isEqualTo:
            enrollment.programmeCode,
          )
              .where(
            'semester',
            isEqualTo:
            enrollment.semester,
          )
              .where(
            'section',
            isEqualTo:
            enrollment.section,
          )
              .snapshots(),
          builder: (
              context,
              snapshot,
              ) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding:
                  const EdgeInsets.all(
                    24,
                  ),
                  child: Text(
                    'Unable to load calendar.\n${snapshot.error}',
                    textAlign:
                    TextAlign.center,
                  ),
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

            final allClasses = docs
                .map(
                  (doc) =>
                  ClassSession.fromMap(
                    doc.data()
                    as Map<String,
                        dynamic>,
                    id: doc.id,
                  ),
            )
                .toList();

            List<ClassSession>
            classesForDay(
                DateTime day,
                ) {
              final weekday =
              _weekdayNames[
              day.weekday - 1];

              return _sortClasses(
                allClasses
                    .where(
                      (session) =>
                  session.day ==
                      weekday,
                )
                    .toList(),
              );
            }

            final selectedClasses =
            classesForDay(
              _selectedDay,
            );

            return Column(
              children: [
                ModernHero(
                  eyebrow: 'Schedule',
                  title: 'Calendar',
                  subtitle:
                  'Plan your academic week at a glance',
                  trailing: Container(
                    width: 46,
                    height: 46,
                    decoration:
                    BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.12,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .calendar_month_rounded,
                      color: Colors.white,
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
                        16,
                        18,
                        16,
                        110,
                      ),
                      children: [
                        SurfacePanel(
                          padding:
                          const EdgeInsets
                              .fromLTRB(
                            14,
                            12,
                            14,
                            14,
                          ),
                          child: TableCalendar(
                            firstDay:
                            DateTime.utc(
                              2024,
                              1,
                              1,
                            ),
                            lastDay:
                            DateTime.utc(
                              2030,
                              12,
                              31,
                            ),
                            focusedDay:
                            _focusedDay,

                            selectedDayPredicate:
                                (day) =>
                                isSameDay(
                                  _selectedDay,
                                  day,
                                ),

                            eventLoader: (day) =>
                                classesForDay(
                                  day,
                                ),

                            onDaySelected: (
                                selectedDay,
                                focusedDay,
                                ) {
                              setState(() {
                                _selectedDay =
                                    selectedDay;
                                _focusedDay =
                                    focusedDay;
                              });
                            },

                            calendarFormat:
                            CalendarFormat
                                .month,

                            rowHeight: 48,

                            headerStyle:
                            HeaderStyle(
                              formatButtonVisible:
                              false,
                              titleCentered:
                              false,
                              headerPadding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              titleTextStyle:
                              const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.w800,
                                color: AppColors
                                    .textPrimary,
                              ),
                              leftChevronIcon:
                              const Icon(
                                Icons
                                    .chevron_left_rounded,
                                color:
                                AppColors.primary,
                              ),
                              rightChevronIcon:
                              const Icon(
                                Icons
                                    .chevron_right_rounded,
                                color:
                                AppColors.primary,
                              ),
                              decoration:
                              const BoxDecoration(),
                            ),

                            daysOfWeekStyle:
                            const DaysOfWeekStyle(
                              weekdayStyle:
                              TextStyle(
                                fontSize: 11,
                                fontWeight:
                                FontWeight.w800,
                                color: AppColors
                                    .textSecondary,
                              ),
                              weekendStyle:
                              TextStyle(
                                fontSize: 11,
                                fontWeight:
                                FontWeight.w800,
                                color: AppColors
                                    .textSecondary,
                              ),
                            ),

                            calendarStyle:
                            CalendarStyle(
                              outsideDaysVisible:
                              true,
                              cellMargin:
                              const EdgeInsets
                                  .all(
                                4,
                              ),
                              markersMaxCount: 1,

                              markerDecoration:
                              const BoxDecoration(
                                color: AppColors
                                    .accent,
                                shape:
                                BoxShape.circle,
                              ),

                              markerSize: 5,

                              defaultTextStyle:
                              const TextStyle(
                                fontSize: 13,
                                fontWeight:
                                FontWeight.w600,
                                color: AppColors
                                    .textPrimary,
                              ),

                              weekendTextStyle:
                              const TextStyle(
                                fontSize: 13,
                                fontWeight:
                                FontWeight.w600,
                                color: AppColors
                                    .textPrimary,
                              ),

                              outsideTextStyle:
                              TextStyle(
                                fontSize: 13,
                                color: AppColors
                                    .textSecondary
                                    .withValues(
                                  alpha: 0.4,
                                ),
                              ),

                              todayDecoration:
                              BoxDecoration(
                                color: AppColors
                                    .primarySoft,
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  12,
                                ),
                                border:
                                Border.all(
                                  color: AppColors
                                      .primary
                                      .withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),

                              todayTextStyle:
                              const TextStyle(
                                fontSize: 13,
                                color: AppColors
                                    .primaryDark,
                                fontWeight:
                                FontWeight.w800,
                              ),

                              selectedDecoration:
                              BoxDecoration(
                                gradient:
                                AppColors
                                    .blueGradient,
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  12,
                                ),
                              ),

                              selectedTextStyle:
                              const TextStyle(
                                color:
                                Colors.white,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        Container(
                          padding:
                          const EdgeInsets
                              .all(
                            18,
                          ),
                          decoration:
                          BoxDecoration(
                            gradient:
                            const LinearGradient(
                              begin: Alignment
                                  .topLeft,
                              end: Alignment
                                  .bottomRight,
                              colors: [
                                AppColors
                                    .primaryDeep,
                                AppColors
                                    .primaryDark,
                              ],
                            ),
                            borderRadius:
                            BorderRadius.circular(
                              24,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration:
                                BoxDecoration(
                                  color: Colors
                                      .white
                                      .withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    16,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _selectedDay
                                        .day
                                        .toString(),
                                    style:
                                    const TextStyle(
                                      color:
                                      Colors.white,
                                      fontSize: 22,
                                      fontWeight:
                                      FontWeight
                                          .w800,
                                    ),
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
                                      _selectedWeekdayName,
                                      style:
                                      const TextStyle(
                                        color: Colors
                                            .white,
                                        fontSize: 18,
                                        fontWeight:
                                        FontWeight
                                            .w800,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                      _shortDate(
                                        _selectedDay,
                                      ),
                                      style:
                                      TextStyle(
                                        color: Colors
                                            .white
                                            .withValues(
                                          alpha: 0.72,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration:
                                BoxDecoration(
                                  color: Colors
                                      .white
                                      .withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    999,
                                  ),
                                ),
                                child: Text(
                                  '${selectedClasses.length} ${selectedClasses.length == 1 ? 'class' : 'classes'}',
                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.white,
                                    fontSize: 11,
                                    fontWeight:
                                    FontWeight
                                        .w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        SectionHeading(
                          title:
                          'Daily Schedule',
                          subtitle:
                          selectedClasses
                              .isEmpty
                              ? 'No classes for the selected day'
                              : 'Your classes for $_selectedWeekdayName',
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        if (selectedClasses
                            .isEmpty)
                          SizedBox(
                            height: 220,
                            child:
                            _emptyAgenda(),
                          )
                        else
                          ...selectedClasses
                              .map(
                                (session) =>
                                Padding(
                                  padding:
                                  const EdgeInsets
                                      .only(
                                    bottom: 12,
                                  ),
                                  child:
                                  _buildClassCard(
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
      },
    );
  }
}