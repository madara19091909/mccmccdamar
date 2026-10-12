import 'dart:convert';
import 'dart:math';
import 'dart:ui' show Color;

class Memory {
  const Memory({
    required this.id,
    required this.title,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    required this.categoryId,
    required this.colorValue,
    this.body = '',
    this.tags = const <String>[],
    this.iconKey = 'star',
    this.importance = 3,
    this.images = const <String>[],
  });

  final String id;
  final String title;
  final String body;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String categoryId;
  final List<String> tags;
  final int colorValue;
  final String iconKey;

  /// 1 (normal) to 5 (very important).
  final int importance;

  /// File names inside the app's private image folder.
  final List<String> images;

  Color get color => Color(colorValue);

  static final Random _random = Random();

  static String newId() {
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final salt = _random.nextInt(1 << 30).toRadixString(36);
    return '$time$salt';
  }

  Memory copyWith({
    String? title,
    String? body,
    DateTime? occurredAt,
    DateTime? updatedAt,
    String? categoryId,
    List<String>? tags,
    int? colorValue,
    String? iconKey,
    int? importance,
    List<String>? images,
  }) {
    return Memory(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      colorValue: colorValue ?? this.colorValue,
      iconKey: iconKey ?? this.iconKey,
      importance: importance ?? this.importance,
      images: images ?? this.images,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'title': title,
        'body': body,
        'occurred_at': occurredAt.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'category_id': categoryId,
        'tags': jsonEncode(tags),
        'color': colorValue,
        'icon': iconKey,
        'importance': importance,
        'images': jsonEncode(images),
      };

  factory Memory.fromMap(Map<String, Object?> map) {
    return Memory(
      id: map['id'] as String,
      title: map['title'] as String,
      body: (map['body'] as String?) ?? '',
      occurredAt:
          DateTime.fromMillisecondsSinceEpoch(map['occurred_at'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      categoryId: map['category_id'] as String,
      tags: _decodeStringList(map['tags'] as String?),
      colorValue: map['color'] as int,
      iconKey: (map['icon'] as String?) ?? 'star',
      importance: (map['importance'] as int?) ?? 3,
      images: _decodeStringList(map['images'] as String?),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'body': body,
        'occurredAt': occurredAt.millisecondsSinceEpoch,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'categoryId': categoryId,
        'tags': tags,
        'color': colorValue,
        'icon': iconKey,
        'importance': importance,
        'images': images,
      };

  static List<String> _decodeStringList(String? raw) {
    if (raw == null || raw.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.whereType<String>().toList();
    } on FormatException {
      // Fall through to the empty list.
    }
    return const <String>[];
  }
}
