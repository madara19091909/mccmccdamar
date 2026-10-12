import 'dart:ui' show Color;

import 'package:echo/core/constants.dart';

class MemoryCategory {
  const MemoryCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconKey,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final int colorValue;
  final String iconKey;
  final int sortOrder;

  Color get color => Color(colorValue);

  bool get isProtected => id == kFallbackCategoryId;

  MemoryCategory copyWith({
    String? name,
    int? colorValue,
    String? iconKey,
    int? sortOrder,
  }) {
    return MemoryCategory(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'color': colorValue,
        'icon': iconKey,
        'sort_order': sortOrder,
      };

  factory MemoryCategory.fromMap(Map<String, Object?> map) {
    return MemoryCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      colorValue: map['color'] as int,
      iconKey: (map['icon'] as String?) ?? 'star',
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'color': colorValue,
        'icon': iconKey,
        'sortOrder': sortOrder,
      };
}

const List<MemoryCategory> kDefaultCategories = <MemoryCategory>[
  MemoryCategory(
      id: 'life',
      name: 'حياتي',
      colorValue: 0xFF4FE3D6,
      iconKey: 'favorite',
      sortOrder: 0),
  MemoryCategory(
      id: 'thoughts',
      name: 'أفكاري',
      colorValue: 0xFF8B7CFF,
      iconKey: 'lightbulb',
      sortOrder: 1),
  MemoryCategory(
      id: 'achievements',
      name: 'إنجازاتي',
      colorValue: 0xFFFFC857,
      iconKey: 'trophy',
      sortOrder: 2),
  MemoryCategory(
      id: 'goals',
      name: 'أهدافي',
      colorValue: 0xFFFF7AC6,
      iconKey: 'flag',
      sortOrder: 3),
  MemoryCategory(
      id: 'moments',
      name: 'لحظات مهمة',
      colorValue: 0xFF5EA8FF,
      iconKey: 'star',
      sortOrder: 4),
  MemoryCategory(
      id: 'diary',
      name: 'يومياتي',
      colorValue: 0xFFFF9F68,
      iconKey: 'book',
      sortOrder: 5),
  MemoryCategory(
      id: 'future',
      name: 'أفكار مستقبلية',
      colorValue: 0xFF7BE495,
      iconKey: 'rocket',
      sortOrder: 6),
];
