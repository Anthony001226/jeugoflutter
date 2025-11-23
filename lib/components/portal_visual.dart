import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

class PortalVisual extends PositionComponent {
  PortalVisual({required Vector2 position})
      : super(position: position, size: Vector2.all(32), anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      (size / 2).toOffset(),
      16,
      BasicPalette.blue.withAlpha(150).paint(),
    );
    canvas.drawCircle(
      (size / 2).toOffset(),
      10,
      BasicPalette.cyan.withAlpha(200).paint(),
    );
  }
}
