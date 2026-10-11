import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/class_session.dart';
import '../theme/app_theme.dart';
import '../utils/subject_colors.dart';
import '../utils/time_utils.dart';
import '../utils/current_user_programme.dart';
import '../services/notification_service.dart';
import '../widgets/modern_ui.dart';
import 'notification_settings_page.dart';
import 'class_detail_page.dart';
import 'student_announcements_page.dart';

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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription<QuerySnapshot>? _classSubscription;

  List<ClassSession> _allClasses = [];

  bool _loadingClasses = true;

  String get _todayName => _weekdayNames[DateTime.now().weekday - 1];

  String get _todayFormatted {
    final now = DateTime.now();

    return '$_todayName, '
        '${now.day} '
        '${_monthNames[now.month - 1]}';
  }

  String get _fullDisplayName {
    final user = FirebaseAuth.instance.currentUser;

    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    if (user?.email != null) {
      return user!.email!.split('@').first;
    }

    return 'there';
  }


  @override
  void initState() {
    super.initState();


    _setupStudentClassListener();
  }

  Future<void> _setupStudentClassListener() async {

    final enrollment = await getCurrentUserEnrollment();

    if (!isEnrollmentComplete(enrollment)) {


      if (mounted) {
        setState(() {
          _loadingClasses = false;
        });
      }

      return;
    }


    final query = FirebaseFirestore.instance
        .collection('classes')
        .where('programmeCode', isEqualTo: enrollment.programmeCode)
        .where('semester', isEqualTo: enrollment.semester)
        .where('section', isEqualTo: enrollment.section);


    _classSubscription = query.snapshots().listen(
      (snapshot) async {

        final classes = snapshot.docs
            .map(
              (doc) => ClassSession.fromMap(
                doc.data(),
                id: doc.id,
              ),
            )
            .toList();



        final prefs = await SharedPreferences.getInstance();

        final int reminderMinutes = prefs.getInt('reminder_minutes') ?? 30;

        await NotificationService.scheduleClassReminders(
          classes,
          reminderMinutes,
        );


        if (!mounted) return;

        setState(() {
          _allClasses = classes;
          _loadingClasses = false;
        });
      },
      onError: (error) {

        if (!mounted) return;

        setState(() {
          _loadingClasses = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _classSubscription?.cancel();

    super.dispose();
  }

  ClassSession? _findNextClass(List<ClassSession> todaysClasses) {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    ClassSession? next;
    int? nextStart;

    for (final session in todaysClasses) {
      final start = parseTimeToMinutes(session.startTime);

      if (start == null) {
        continue;
      }

      if (start >= nowMinutes && (nextStart == null || start < nextStart)) {
        next = session;
        nextStart = start;
      }
    }

    return next;
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: .13)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _nextClassCard(BuildContext context, ClassSession session) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClassDetailPage(session: session)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: .14)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                session.classType == 'online'
                    ? Icons.videocam_rounded
                    : Icons.menu_book_rounded,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UP NEXT',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.courseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.classType == 'online'
                        ? 'Online • ${session.startTime} - ${session.endTime}'
                        : '${session.room} • ${session.startTime} - ${session.endTime}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 15),
          ],
        ),
      ),
    );
  }

  Widget _classCard(BuildContext context, ClassSession session) {
    final color = colorForSubject(session.courseName);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClassDetailPage(session: session)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 58,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                session.classType == 'online' ? Icons.videocam_outlined : Icons.school_outlined,
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.courseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 5),
                      Text(
                        '${session.startTime} - ${session.endTime}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        session.classType == 'online' ? Icons.language_rounded : Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          session.classType == 'online' ? 'Online' : session.room,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingClasses) {
      return const Center(child: CircularProgressIndicator());
    }

    final todaysClasses = _allClasses.where((c) => c.day == _todayName).toList();
    final roomsToday = todaysClasses.map((c) => c.room).where((r) => r.isNotEmpty).toSet().length;
    final nextClass = _findNextClass(todaysClasses);

    return Column(
      children: [
        ModernHero(
          eyebrow: 'Student dashboard',
          title: 'Hi, $_fullDisplayName',
          subtitle: _todayFormatted,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconButton(
                icon: Icons.campaign_outlined,
                tooltip: 'Announcements',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentAnnouncementsPage()),
                ),
              ),
              const SizedBox(width: 8),
              _iconButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Reminder settings',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationSettingsPage()),
                ),
              ),
            ],
          ),
          bottom: nextClass != null
              ? _nextClassCard(context, nextClass)
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: .12)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: Colors.white70),
                      SizedBox(width: 10),
                      Text(
                        'No more classes coming up today',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 108),
              children: [
                Row(
                  children: [
                    MetricTile(
                      icon: Icons.today_rounded,
                      value: '${todaysClasses.length}',
                      label: 'Classes today',
                    ),
                    const SizedBox(width: 10),
                    MetricTile(
                      icon: Icons.calendar_month_rounded,
                      value: '${_allClasses.length}',
                      label: 'Weekly classes',
                      color: const Color(0xFF5B6EE1),
                    ),
                    const SizedBox(width: 10),
                    MetricTile(
                      icon: Icons.meeting_room_outlined,
                      value: '$roomsToday',
                      label: 'Rooms today',
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const SectionHeading(
                  title: "Today's schedule",
                  subtitle: 'Your classes, at a glance',
                ),
                const SizedBox(height: 12),
                if (todaysClasses.isEmpty)
                  SurfacePanel(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.event_available_rounded, color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Clear schedule today',
                            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No classes are scheduled for today.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...todaysClasses.map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _classCard(context, session),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
