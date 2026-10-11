import 'package:flutter/material.dart';

import 'lecturer_home_page.dart';
import 'my_classes_page.dart';
import 'lecturer_announcements_page.dart';
import 'profile_page.dart';
import '../widgets/floating_nav_bar.dart';

class LecturerMainScreen extends StatefulWidget {
  const LecturerMainScreen({super.key});

  @override
  State<LecturerMainScreen> createState() => _LecturerMainScreenState();
}

class _LecturerMainScreenState extends State<LecturerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    LecturerHomePage(),
    MyClassesPage(),
    LecturerAnnouncementsPage(),
    ProfilePage(),
  ];

  static const _items = [
    (
    icon: Icons.home_rounded,
    label: 'Home',
    ),
    (
    icon: Icons.class_rounded,
    label: 'Classes',
    ),
    (
    icon: Icons.campaign_rounded,
    label: 'Notices',
    ),
    (
    icon: Icons.person_rounded,
    label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _items,
      ),
    );
  }
}