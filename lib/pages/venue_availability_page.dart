import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/glass_card.dart';

const List<String> _weekdayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

const int _campusOpenMinutes = 8 * 60;
const int _campusCloseMinutes = 18 * 60;

class VenueAvailabilityPage extends StatefulWidget {
  const VenueAvailabilityPage({super.key});

  @override
  State<VenueAvailabilityPage> createState() => _VenueAvailabilityPageState();
}

class _VenueAvailabilityPageState extends State<VenueAvailabilityPage> {
  String? _selectedRoom;
  late String _selectedDay;
  List<String> _rooms = [];
  bool _loadingRooms = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _weekdayNames[DateTime.now().weekday - 1];
    _loadRooms();
  }

  void _loadRooms() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .where('classType', isEqualTo: 'physical')
        .get();

    final rooms = snapshot.docs
        .map((doc) => (doc.data()['room'] ?? '') as String)
        .where((room) => room.isNotEmpty)
        .toSet()
        .toList();
    rooms.sort();

    setState(() {
      _rooms = rooms;
      _selectedRoom = rooms.isNotEmpty ? rooms.first : null;
      _loadingRooms = false;
    });
  }

  String _formatMinutes(int minutes) {
    int hour = minutes ~/ 60;
    final minute = minutes % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    return '${hour.toString()}:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Venue Availability', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Check if a room is free before booking', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: _loadingRooms
                  ? const Center(child: CircularProgressIndicator())
                  : _rooms.isEmpty
                  ? const Center(child: Text('No physical rooms found yet. Add a physical class first.'))
                  : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRoom,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Room', prefixIcon: Icon(Icons.location_on_outlined)),
                    items: _rooms.map((room) => DropdownMenuItem(value: room, child: Text(room))).toList(),
                    onChanged: (value) => setState(() => _selectedRoom = value),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDay,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Day', prefixIcon: Icon(Icons.calendar_today_outlined)),
                    items: _weekdayNames.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                    onChanged: (value) => setState(() => _selectedDay = value!),
                  ),
                  const SizedBox(height: 24),
                  if (_selectedRoom != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('classes')
                          .where('room', isEqualTo: _selectedRoom)
                          .where('day', isEqualTo: _selectedDay)
                          .where('classType', isEqualTo: 'physical')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data?.docs ?? [];

                        final busySlots = <({int start, int end, String courseName})>[];
                        for (final doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final start = parseTimeToMinutes(data['startTime'] ?? '');
                          final end = parseTimeToMinutes(data['endTime'] ?? '');
                          if (start == null || end == null) continue;
                          busySlots.add((start: start, end: end, courseName: data['courseName'] ?? ''));
                        }
                        busySlots.sort((a, b) => a.start.compareTo(b.start));

                        final freeSlots = <({int start, int end})>[];
                        var cursor = _campusOpenMinutes;
                        for (final slot in busySlots) {
                          if (slot.start > cursor) {
                            freeSlots.add((start: cursor, end: slot.start));
                          }
                          cursor = slot.end > cursor ? slot.end : cursor;
                        }
                        if (cursor < _campusCloseMinutes) {
                          freeSlots.add((start: cursor, end: _campusCloseMinutes));
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_selectedRoom on $_selectedDay',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            if (busySlots.isEmpty)
                              _statusCard(
                                icon: Icons.check_circle_outline,
                                color: AppColors.primary,
                                title: 'Free all day',
                                subtitle: 'No classes booked in this room on $_selectedDay.',
                              )
                            else ...[
                              const Text('Booked', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 8),
                              ...busySlots.map((slot) => _statusCard(
                                icon: Icons.event_busy,
                                color: AppColors.error,
                                title: slot.courseName,
                                subtitle: '${_formatMinutes(slot.start)} - ${_formatMinutes(slot.end)}',
                              )),
                              const SizedBox(height: 16),
                              const Text('Available', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 8),
                              if (freeSlots.isEmpty)
                                _statusCard(
                                  icon: Icons.event_busy,
                                  color: AppColors.textSecondary,
                                  title: 'No free slots',
                                  subtitle: 'This room is fully booked from ${_formatMinutes(_campusOpenMinutes)} to ${_formatMinutes(_campusCloseMinutes)}.',
                                )
                              else
                                ...freeSlots.map((slot) => _statusCard(
                                  icon: Icons.event_available,
                                  color: AppColors.primary,
                                  title: 'Free',
                                  subtitle: '${_formatMinutes(slot.start)} - ${_formatMinutes(slot.end)}',
                                )),
                            ],
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard({required IconData icon, required Color color, required String title, required String subtitle}) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}