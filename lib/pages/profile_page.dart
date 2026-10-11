import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dialog.dart';
import '../widgets/modern_ui.dart';
import 'splash_page.dart';
import 'notification_settings_page.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String get _displayName {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return user?.email?.split('@').first ?? 'User';
  }

  String get _email => FirebaseAuth.instance.currentUser?.email ?? '';

  Future<Map<String, dynamic>> _fetchProfileData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {'role': 'student'};
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data() ?? {'role': 'student'};
  }

  Color _colorForRole(String role) {
    switch (role) {
      case 'admin':
        return AppColors.warning;
      case 'lecturer':
        return AppColors.primary;
      default:
        return const Color(0xFF5B6EE1);
    }
  }

  void _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashPage()),
      (route) => false,
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 21),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
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
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchProfileData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <String, dynamic>{};
        final role = (data['role'] ?? 'student').toString();
        final programmeCode = data['programmeCode']?.toString();
        final semester = data['semester'];
        final section = data['section'];
        final roleColor = _colorForRole(role);

        return Column(
          children: [
            ModernHero(
              eyebrow: 'Account',
              title: _displayName,
              subtitle: _email,
              bottom: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withValues(alpha: .13)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Text(
                              _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: .16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  role.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .92),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                    letterSpacing: .7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (programmeCode != null && programmeCode.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '$programmeCode${semester != null ? ' • Semester $semester' : ''}${section != null ? ' • Section $section' : ''}',
                              style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 12),
                            ),
                          ],
                        ],
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 108),
                  children: [
                    const SectionHeading(
                      title: 'Account settings',
                      subtitle: 'Manage your profile and preferences',
                    ),
                    const SizedBox(height: 12),
                    SurfacePanel(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        children: [
                          _actionTile(
                            icon: Icons.person_outline_rounded,
                            title: 'Edit profile',
                            subtitle: 'Update your personal information',
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfilePage()),
                              );
                              if (context.mounted) {
                                (context as Element).markNeedsBuild();
                              }
                            },
                          ),
                          const Divider(),
                          _actionTile(
                            icon: Icons.lock_outline_rounded,
                            title: 'Change password',
                            subtitle: 'Keep your account secure',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                              );
                            },
                          ),
                          if (role != 'admin') ...[
                            const Divider(),

                            _actionTile(
                              icon:
                              Icons.notifications_none_rounded,
                              title: 'Notification settings',
                              subtitle:
                              'Choose when class reminders appear',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const NotificationSettingsPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: () async {
                        final confirmed = await showConfirmDialog(
                          context: context,
                          title: 'Log Out',
                          message: 'Are you sure you want to log out?',
                          confirmLabel: 'Log Out',
                          icon: Icons.logout_rounded,
                          iconColor: AppColors.error,
                          isDanger: true,
                        );
                        if (confirmed && context.mounted) {
                          _handleLogout(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.error.withValues(alpha: .16)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.logout_rounded, color: AppColors.error),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Log out',
                                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppColors.error),
                          ],
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
