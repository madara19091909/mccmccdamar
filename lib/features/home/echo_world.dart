import 'dart:math' as math;

import 'package:echo/core/theme/app_theme.dart';
import 'package:echo/data/models/memory.dart';
import 'package:echo/data/models/memory_category.dart';
import 'package:flutter/material.dart';

class WorldNode {
  const WorldNode({
    required this.memory,
    required this.position,
    required this.radius,
    required this.color,
  });

  final Memory memory;
  final Offset position;
  final double radius;
  final Color color;
}

class WorldIsland {
  const WorldIsland({
    required this.category,
    required this.center,
    required this.nodes,
  });

  final MemoryCategory category;
  final Offset center;
  final List<WorldNode> nodes;
}

class WorldLayout {
  const WorldLayout({required this.core, required this.islands});

  final Offset core;
  final List<WorldIsland> islands;

  Iterable<WorldNode> get allNodes sync* {
    for (final island in islands) {
      yield* island.nodes;
    }
  }
}

/// Deterministic layout: every category with memories becomes an "island"
/// placed on an ellipse around the ECHO core. Memories spiral out of it.
WorldLayout layoutWorld(
  Size size,
  List<Memory> memories,
  List<MemoryCategory> categories, {
  int maxNodes = 300,
}) {
  final core = Offset(size.width / 2, size.height / 2);
  if (size.width < 60 || size.height < 60) {
    return WorldLayout(core: core, islands: const <WorldIsland>[]);
  }

  final byCategory = <String, List<Memory>>{};
  for (final memory in memories.take(maxNodes)) {
    byCategory.putIfAbsent(memory.categoryId, () => <Memory>[]).add(memory);
  }
  final used = categories.where((c) => byCategory.containsKey(c.id)).toList();

  final radiusX = size.width * 0.30;
  final radiusY = size.height * 0.30;
  final spacing =
      (math.min(size.width, size.height) * 0.04).clamp(10.0, 22.0).toDouble();

  final islands = <WorldIsland>[];
  for (var i = 0; i < used.length; i++) {
    final category = used[i];
    final angle = -math.pi / 2 + 2 * math.pi * i / used.length;
    final center = Offset(
      core.dx + math.cos(angle) * radiusX,
      core.dy + math.sin(angle) * radiusY,
    );
    final list = <Memory>[...byCategory[category.id]!]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final nodes = <WorldNode>[];
    for (var k = 0; k < list.length; k++) {
      final memory = list[k];
      final theta = k * 2.399963;
      final distance = spacing * math.sqrt(k + 0.6) * 1.5;
      final rawX = center.dx + math.cos(theta) * distance;
      final rawY = center.dy + math.sin(theta) * distance;
      nodes.add(WorldNode(
        memory: memory,
        position: Offset(
          rawX.clamp(14.0, size.width - 14).toDouble(),
          rawY.clamp(14.0, size.height - 14).toDouble(),
        ),
        radius: 5 + memory.importance * 1.6,
        color: memory.color,
      ));
    }
    islands.add(WorldIsland(category: category, center: center, nodes: nodes));
  }
  return WorldLayout(core: core, islands: islands);
}

/// Interactive 2D "space" of memories (zoom with pinch, drag when zoomed,
/// tap a point to open it). Drawn with CustomPainter - not real 3D.
class EchoWorld extends StatefulWidget {
  const EchoWorld({
    super.key,
    required this.memories,
    required this.categories,
    required this.animate,
    required this.onOpenMemory,
  });

  final List<Memory> memories;
  final List<MemoryCategory> categories;

  /// False = light mode: static stars, no continuous animation.
  final bool animate;
  final ValueChanged<Memory> onOpenMemory;

  @override
  State<EchoWorld> createState() => _EchoWorldState();
}

class _EchoWorldState extends State<EchoWorld>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  WorldLayout _layout = const WorldLayout(
    core: Offset.zero,
    islands: <WorldIsland>[],
  );

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(EchoWorld oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.animate) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(Offset position) {
    WorldNode? best;
    var bestDistance = double.infinity;
    for (final node in _layout.allNodes) {
      final distance = (node.position - position).distance;
      if (distance <= node.radius + 16 && distance < bestDistance) {
        best = node;
        bestDistance = distance;
      }
    }
    if (best != null) widget.onOpenMemory(best.memory);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        final height =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 360.0;
        final size = Size(width, height);
        _layout = layoutWorld(size, widget.memories, widget.categories);
        return ClipRect(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _handleTap(details.localPosition),
              child: SizedBox(
                width: width,
                height: height,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: EchoWorldPainter(
                      layout: _layout,
                      animation: _controller,
                      animate: widget.animate,
                      dark: dark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class EchoWorldPainter extends CustomPainter {
  EchoWorldPainter({
    required this.layout,
    required this.animation,
    required this.animate,
    required this.dark,
  }) : super(repaint: animation);

  final WorldLayout layout;
  final Animation<double> animation;
  final bool animate;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animate ? animation.value : 0.5;
    _paintStars(canvas, size, t);
    for (final island in layout.islands) {
      _paintIsland(canvas, island);
    }
    _paintCore(canvas, t);
  }

  void _paintStars(Canvas canvas, Size size, double t) {
    final random = math.Random(42);
    final count = animate ? 110 : 60;
    final paint = Paint();
    final base = dark ? Colors.white : AppColors.violet;
    for (var i = 0; i < count; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = 0.4 + random.nextDouble() * 1.2;
      final phase = random.nextDouble() * math.pi * 2;
      final twinkle = animate
          ? 0.35 + 0.55 * (0.5 + 0.5 * math.sin(t * math.pi * 2 + phase))
          : 0.55;
      paint.color = base.withValues(alpha: twinkle * (dark ? 1 : 0.35));
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  void _paintIsland(Canvas canvas, WorldIsland island) {
    final color = island.category.color;
    var extent = 50.0;
    for (final node in island.nodes) {
      extent = math.max(extent, (node.position - island.center).distance + 30);
    }

    final glow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: dark ? 0.22 : 0.16),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: island.center, radius: extent));
    canvas.drawCircle(island.center, extent, glow);

    final line = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < island.nodes.length; i++) {
      canvas.drawLine(
        island.nodes[i - 1].position,
        island.nodes[i].position,
        line,
      );
    }

    final halo = Paint();
    final body = Paint();
    final spark = Paint()..color = Colors.white.withValues(alpha: 0.75);
    for (final node in island.nodes) {
      halo.color = node.color.withValues(alpha: 0.2);
      canvas.drawCircle(node.position, node.radius * 2.2, halo);
      body.color = node.color;
      canvas.drawCircle(node.position, node.radius, body);
      canvas.drawCircle(
        node.position.translate(-node.radius * 0.3, -node.radius * 0.3),
        node.radius * 0.28,
        spark,
      );
    }

    final label = TextPainter(
      text: TextSpan(
        text: island.category.name,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    final labelY = math.max(2.0, island.center.dy - extent + 4);
    label.paint(canvas, Offset(island.center.dx - label.width / 2, labelY));
  }

  void _paintCore(Canvas canvas, double t) {
    final pulse = animate ? math.sin(t * math.pi) : 0.5;
    final radius = 13 + 2.5 * pulse;
    final halo = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          AppColors.violet.withValues(alpha: 0.5),
          AppColors.violet.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: layout.core, radius: radius * 3.2));
    canvas.drawCircle(layout.core, radius * 3.2, halo);

    final fill = Paint()
      ..shader = RadialGradient(
        colors: <Color>[Colors.white, AppColors.cyan, AppColors.violet],
        stops: const <double>[0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: layout.core, radius: radius));
    canvas.drawCircle(layout.core, radius, fill);

    final label = TextPainter(
      text: TextSpan(
        text: 'ECHO',
        style: TextStyle(
          color: dark ? Colors.white70 : Colors.black54,
          fontSize: 10,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(
      canvas,
      Offset(layout.core.dx - label.width / 2, layout.core.dy + radius + 6),
    );
  }

  @override
  bool shouldRepaint(EchoWorldPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.animate != animate ||
        oldDelegate.dark != dark;
  }
}
