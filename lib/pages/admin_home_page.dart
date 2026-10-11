import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/modern_ui.dart';

class AdminHomePage extends StatelessWidget {
  final VoidCallback onManageUsers;
  final VoidCallback onManageProgrammes;

  const AdminHomePage({
    super.key,
    required this.onManageUsers,
    required this.onManageProgrammes,
  });

  String get _adminName {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();

    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    return 'Administrator';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModernHero(
          eyebrow: 'Administration',
          title: 'Welcome, $_adminName',
          subtitle: 'System overview and management',
          trailing: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .snapshots(),
            builder: (context, usersSnapshot) {
              if (usersSnapshot.hasError) {
                return _ErrorState(
                  message: 'Unable to load user information.',
                );
              }

              if (usersSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final userDocs = usersSnapshot.data?.docs ?? [];

              int students = 0;
              int lecturers = 0;
              int admins = 0;

              for (final doc in userDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final role =
                (data['role'] ?? '').toString().toLowerCase();

                if (role == 'student') {
                  students++;
                } else if (role == 'lecturer') {
                  lecturers++;
                } else if (role == 'admin') {
                  admins++;
                }
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('programmes')
                    .snapshots(),
                builder: (context, programmesSnapshot) {
                  if (programmesSnapshot.hasError) {
                    return _ErrorState(
                      message:
                      'Unable to load programme information.',
                    );
                  }

                  if (programmesSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final programmeCount =
                      programmesSnapshot.data?.docs.length ?? 0;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('classes')
                        .snapshots(),
                    builder: (context, classesSnapshot) {
                      if (classesSnapshot.hasError) {
                        return _ErrorState(
                          message:
                          'Unable to load class information.',
                        );
                      }

                      if (classesSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final classCount =
                          classesSnapshot.data?.docs.length ?? 0;

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          110,
                        ),
                        children: [
                          const SectionHeading(
                            title: 'System Overview',
                            subtitle:
                            'Live information from the database',
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: [
                              MetricTile(
                                icon: Icons.people_alt_rounded,
                                value: userDocs.length.toString(),
                                label: 'Total Users',
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              MetricTile(
                                icon: Icons.school_outlined,
                                value: students.toString(),
                                label: 'Students',
                                color: AppColors.success,
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              MetricTile(
                                icon: Icons.co_present_rounded,
                                value: lecturers.toString(),
                                label: 'Lecturers',
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 12),
                              MetricTile(
                                icon:
                                Icons.admin_panel_settings_outlined,
                                value: admins.toString(),
                                label: 'Admins',
                                color: AppColors.accent,
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              MetricTile(
                                icon: Icons.account_tree_outlined,
                                value: programmeCount.toString(),
                                label: 'Programmes',
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 12),
                              MetricTile(
                                icon: Icons.calendar_month_outlined,
                                value: classCount.toString(),
                                label: 'Classes',
                                color: AppColors.primary,
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          const SectionHeading(
                            title: 'Quick Actions',
                            subtitle:
                            'Manage core system information',
                          ),

                          const SizedBox(height: 14),

                          _QuickActionCard(
                            icon: Icons.manage_accounts_rounded,
                            title: 'Manage Users',
                            subtitle:
                            'Students, lecturers and administrators',
                            onTap: onManageUsers,
                          ),

                          const SizedBox(height: 12),

                          _QuickActionCard(
                            icon: Icons.school_rounded,
                            title: 'Manage Programmes',
                            subtitle:
                            'Add, edit or remove study programmes',
                            onTap: onManageProgrammes,
                          ),

                          const SizedBox(height: 28),

                          const SectionHeading(
                            title: 'System Status',
                          ),

                          const SizedBox(height: 14),

                          const SurfacePanel(
                            child: Row(
                              children: [
                                _StatusIcon(),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'System Online',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color:
                                          AppColors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Firebase services are connected and system data is available.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color:
                                          AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryDark,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.check_circle_outline_rounded,
        color: AppColors.success,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: AppColors.error,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}