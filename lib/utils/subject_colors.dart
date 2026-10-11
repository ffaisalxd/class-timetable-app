import 'package:flutter/material.dart';

const List<Color> _subjectPalette = [
  Color(0xFF0E8C7F),
  Color(0xFFFF6B4A),
  Color(0xFF5B6EE1),
  Color(0xFFE0A62E),
  Color(0xFFD1547B),
  Color(0xFF3FA796),
  Color(0xFF8B5CF6),
];

Color colorForSubject(String courseName) {
  final hash = courseName.codeUnits.fold(0, (prev, unit) => prev + unit);
  return _subjectPalette[hash % _subjectPalette.length];
}