import 'package:flutter/material.dart';
import '../models/class_session.dart';
import '../theme/app_theme.dart';
import '../utils/subject_colors.dart';
import '../widgets/pill_tag.dart';

class ClassDetailPage extends StatelessWidget {
  final ClassSession session;

  const ClassDetailPage({super.key, required this.session});

  Widget _detailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = colorForSubject(session.courseName);
    final isOnline = session.classType == 'online';

    return Scaffold(
      appBar: AppBar(title: const Text('Class Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      isOnline ? Icons.videocam_outlined : Icons.menu_book_rounded,
                      color: color,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    session.courseName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PillTag(label: session.day.toUpperCase(), color: color),
                      const SizedBox(width: 8),
                      PillTag(
                        label: isOnline ? 'ONLINE' : 'PHYSICAL',
                        color: isOnline ? const Color(0xFF5B6EE1) : AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                children: [
                  _detailRow(
                    icon: Icons.person_outline,
                    label: 'Lecturer',
                    value: session.lecturer.isNotEmpty ? session.lecturer : 'Not assigned',
                  ),
                  Divider(height: 1, color: AppColors.glassBorder),
                  _detailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: '${session.startTime} - ${session.endTime}',
                  ),
                  Divider(height: 1, color: AppColors.glassBorder),
                  _detailRow(
                    icon: isOnline ? Icons.link : Icons.location_on_outlined,
                    label: isOnline ? 'Meeting Link' : 'Room / Venue',
                    value: session.room.isNotEmpty ? session.room : 'Not specified',
                  ),
                  if (session.programmeCode.isNotEmpty) ...[
                    Divider(height: 1, color: AppColors.glassBorder),
                    _detailRow(
                      icon: Icons.school_outlined,
                      label: 'Programme',
                      value: session.programmeCode,
                    ),
                  ],
                  if (session.semester > 0 || session.section > 0) ...[
                    Divider(height: 1, color: AppColors.glassBorder),
                    _detailRow(
                      icon: Icons.groups_outlined,
                      label: 'Semester / Section',
                      value: 'Semester ${session.semester} • Section ${session.section}',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}