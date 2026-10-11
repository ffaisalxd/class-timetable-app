import 'package:flutter/material.dart';

import 'home_page.dart';
import 'search_page.dart';
import 'calendar_page.dart';
import 'profile_page.dart';
import 'weekly_timetable_page.dart';
import '../widgets/floating_nav_bar.dart';
import '../services/reminder_sync_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
  });

  @override
  State<MainScreen> createState() =>
      _MainScreenState();
}

class _MainScreenState
    extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages =
  const [
    HomePage(),
    SearchPage(),
    WeeklyTimetablePage(),
    CalendarPage(),
    ProfilePage(),
  ];

  @override
  Widget build(
      BuildContext context,
      ) {
    return ReminderSyncManager(
      child: Scaffold(
        extendBody: true,

        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),

        bottomNavigationBar:
        FloatingNavBar(
          currentIndex:
          _currentIndex,

          onTap: (index) {
            setState(() {
              _currentIndex =
                  index;
            });
          },

          items: const [
            (
            icon:
            Icons.home_rounded,
            label: 'Home',
            ),
            (
            icon:
            Icons.search_rounded,
            label: 'Search',
            ),
            (
            icon:Icons.view_week_rounded,
            label: 'Weekly',
            ),
            (
            icon: Icons
                .calendar_month_rounded,
            label: 'Calendar',
            ),
            (
            icon:
            Icons.person_rounded,
            label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}