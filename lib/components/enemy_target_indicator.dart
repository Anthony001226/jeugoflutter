
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Visual indicator showing which enemy is currently targeted
class EnemyTargetIndicator extends PositionComponent {
  final SpriteAnimationComponent enemy;

  EnemyTargetIndicator({required this.enemy})
      : super(
          size: Vector2(180, 180),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    final arrow = _ArrowComponent();
    arrow.position = Vector2(0, -100);
    add(arrow);
  }

  @override
  void update(double dt) {
    super.update(dt);

    position = enemy.position;
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
      ..moveTo(0, 0)
      ..lineTo(-15, -20)
      ..lineTo(-5, -20)
      ..lineTo(-5, -30)
      ..lineTo(5, -30)
      ..lineTo(5, -20)
      ..lineTo(15, -20)
      ..close();

    canvas.drawPath(path, paint);

    paint
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, paint);
  }
}
