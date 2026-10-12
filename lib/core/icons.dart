import 'package:flutter/material.dart';

const Map<String, IconData> kIconChoices = <String, IconData>{
  'star': Icons.star_rounded,
  'favorite': Icons.favorite_rounded,
  'lightbulb': Icons.lightbulb_rounded,
  'trophy': Icons.emoji_events_rounded,
  'flag': Icons.flag_rounded,
  'book': Icons.menu_book_rounded,
  'rocket': Icons.rocket_launch_rounded,
  'camera': Icons.photo_camera_rounded,
  'travel': Icons.flight_rounded,
  'music': Icons.music_note_rounded,
  'work': Icons.work_rounded,
  'home': Icons.home_rounded,
  'sun': Icons.wb_sunny_rounded,
  'moon': Icons.nightlight_round,
  'school': Icons.school_rounded,
  'fitness': Icons.fitness_center_rounded,
};

IconData iconFor(String key) => kIconChoices[key] ?? Icons.circle;

/// Colors offered when creating memories and categories (ARGB values).
const List<int> kPaletteColors = <int>[
  0xFF8B7CFF,
  0xFF4FE3D6,
  0xFFFF7AC6,
  0xFFFFC857,
  0xFF5EA8FF,
  0xFFFF9F68,
  0xFF7BE495,
  0xFFFF6B6B,
];
