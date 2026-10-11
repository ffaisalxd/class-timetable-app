import 'package:flutter/material.dart';

import 'admin_home_page.dart';
import 'manage_users_page.dart';
import 'manage_programmes_page.dart';
import 'profile_page.dart';

import '../widgets/floating_nav_bar.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() =>
      _AdminMainScreenState();
}

class _AdminMainScreenState
    extends State<AdminMainScreen> {
  int _currentIndex = 0;

  void _goToPage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminHomePage(
        onManageUsers: () => _goToPage(1),
        onManageProgrammes: () => _goToPage(2),
      ),
      const ManageUsersPage(),
      const ManageProgrammesPage(),
      const ProfilePage(),
    ];

    const items = [
      (
      icon: Icons.dashboard_rounded,
      label: 'Home',
      ),
      (
      icon: Icons.people_alt_rounded,
      label: 'Users',
      ),
      (
      icon: Icons.school_rounded,
      label: 'Programmes',
      ),
      (
      icon: Icons.person_rounded,
      label: 'Profile',
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: _goToPage,
        items: items,
      ),
    );
  }
}