class ClassSession {
  final String id;
  final String courseName;
  final String lecturer;
  final String room;
  final String startTime;
  final String endTime;
  final String day;
  final String programmeCode;
  final int semester;
  final int section;
  final String classType;

  ClassSession({
    this.id = '',
    required this.courseName,
    required this.lecturer,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.day,
    this.programmeCode = '',
    this.semester = 0,
    this.section = 0,
    this.classType = 'physical',
  });

  factory ClassSession.fromMap(Map<String, dynamic> data, {String id = ''}) {
    return ClassSession(
      id: id,
      courseName: data['courseName'] ?? '',
      lecturer: data['lecturer'] ?? '',
      room: data['room'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      day: data['day'] ?? '',
      programmeCode: data['programmeCode'] ?? '',
      semester: data['semester'] is int ? data['semester'] : 0,
      section: data['section'] is int ? data['section'] : 0,
      classType: data['classType'] ?? 'physical',
    );
  }
}