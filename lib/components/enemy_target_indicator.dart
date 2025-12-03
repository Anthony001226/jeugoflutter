// lib/components/enemy_target_indicator.dart

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Visual indicator showing which enemy is currently targeted
class EnemyTargetIndicator extends PositionComponent {
  final SpriteAnimationComponent enemy;
  late final RectangleComponent _border;
  double _pulseTime = 0;

  EnemyTargetIndicator({required this.enemy})
      : super(
          size: Vector2(180, 180),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    // Animated border that pulses
    // Animated border removed as per user request
    /*
    _border = RectangleComponent(
      size: Vector2(180, 180),
      paint: Paint()
        ..color = Colors.yellow.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
      anchor: Anchor.center,
    );
    add(_border);
    */

    // Arrow pointing down at enemy
    final arrow = _ArrowComponent();
    arrow.position = Vector2(0, -100);
    add(arrow);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Follow enemy position
    position = enemy.position;

    // Pulse animation
    _pulseTime += dt * 3;
    /*
    final pulse = (math.sin(_pulseTime) + 1) / 2; // 0 to 1
    _border.paint.strokeWidth = 3 + pulse * 2; // 3 to 5
    _border.paint.color = Colors.yellow.withOpacity(0.6 + pulse * 0.3);
    */
  }
}

/// Simple arrow pointing down
class _ArrowComponent extends PositionComponent {
  _ArrowComponent() : super(size: Vector2(40, 40), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0) // Top center
      ..lineTo(-15, -20) // Top left
      ..lineTo(-5, -20) // Inner left
      ..lineTo(-5, -30) // Bottom left
      ..lineTo(5, -30) // Bottom right
      ..lineTo(5, -20) // Inner right
      ..lineTo(15, -20) // Top right
      ..close();

    canvas.drawPath(path, paint);

    // Outline
    paint
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, paint);
  }
}
