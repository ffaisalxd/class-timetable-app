import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/announcement.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_ui.dart';
import 'announcement_form_page.dart';

class LecturerAnnouncementsPage extends StatelessWidget {
  const LecturerAnnouncementsPage({super.key});

  String get _lecturerName {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? '';
  }

  Future<void> _deleteAnnouncement(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: const Text('This announcement will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('announcements').doc(id).delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement deleted')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete announcement: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/$year • $hour:$minute $period';
  }

  Widget _headerAction(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnnouncementFormPage()),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: .13)),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModernHero(
          eyebrow: 'Communication',
          title: 'Announcements',
          subtitle: 'Keep students updated with class notices',
          trailing: _headerAction(context),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('announcements')
                .where('lecturer', isEqualTo: _lecturerName)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Unable to load announcements.\n${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final announcements = (snapshot.data?.docs ?? [])
                  .map(
                    (doc) => Announcement.fromMap(
                      doc.data() as Map<String, dynamic>,
                      id: doc.id,
                    ),
                  )
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (announcements.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: SurfacePanel(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.campaign_outlined, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No announcements yet',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Create an announcement when you need to update a class.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AnnouncementFormPage()),
                              );
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Create Announcement'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 108),
                itemCount: announcements.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final a = announcements[index];
                  return SurfacePanel(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.campaign_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    a.courseName,
                                    style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () => _deleteAnnouncement(context, a.id),
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          a.message,
                          style: const TextStyle(color: AppColors.textPrimary, height: 1.45, fontSize: 14),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            _MetaChip(icon: Icons.school_outlined, label: a.programmeCode),
                            _MetaChip(icon: Icons.layers_outlined, label: 'Sem ${a.semester}'),
                            _MetaChip(icon: Icons.groups_outlined, label: 'Section ${a.section}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatDate(a.createdAt),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                        ),
                      ],
                    ),
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}
