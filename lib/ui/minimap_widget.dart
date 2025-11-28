import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../game/renegade_dungeon_game.dart';

class MinimapWidget extends StatelessWidget {
  final RenegadeDungeonGame game;
  final double size;

  const MinimapWidget({
    Key? key,
    required this.game,
    this.size = 150.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          painter: MinimapPainter(game: game),
        ),
      ),
    );
  }
}

class MinimapPainter extends CustomPainter {
  final RenegadeDungeonGame game;

  MinimapPainter({required this.game})
      : super(repaint: game.player.positionNotifier);
  // We repaint when player moves. Ideally we'd have a notifier for exploration too,
  // but player movement is the main driver.

  @override
  void paint(Canvas canvas, Size size) {
    // if (game.mapComponent == null) return; // mapComponent is late final

    // Scale to fit the map in the minimap view?
    // Or center on player and show a window?
    // Let's center on player and show a window of radius X tiles.

    final double zoom = 4.0; // Pixels per tile on minimap
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    final playerGridPos = game.player.gridPosition;

    // Draw background
    final Paint bgPaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw explored tiles
    final Paint floorPaint = Paint()..color = Colors.grey.withOpacity(0.5);

    // Optimization: Only iterate tiles that would be visible in the minimap
    final int viewRadius = (size.width / 2 / zoom).ceil();
    final int startX = (playerGridPos.x - viewRadius).floor();
    final int endX = (playerGridPos.x + viewRadius).ceil();
    final int startY = (playerGridPos.y - viewRadius).floor();
    final int endY = (playerGridPos.y + viewRadius).ceil();

    for (int x = startX; x <= endX; x++) {
      for (int y = startY; y <= endY; y++) {
        final point = math.Point(x, y);
        if (game.exploredTiles.contains(point)) {
          // Calculate position on minimap relative to center
          final double dx = (x - playerGridPos.x) * zoom + centerX;
          final double dy = (y - playerGridPos.y) * zoom + centerY;

          // Draw tile
          // We could check if it's a wall or floor if we had that info easily accessible
          // For now, just draw explored areas as light grey
          canvas.drawRect(Rect.fromLTWH(dx, dy, zoom, zoom), floorPaint);
        }
      }
    }

    // Draw Player
    final Paint playerPaint = Paint()..color = Colors.greenAccent;
    canvas.drawCircle(Offset(centerX, centerY), 3.0, playerPaint);

    // Draw Enemies (optional, maybe only if close)
    // game.combatManager.currentEnemies... wait, those are in combat.
    // We need enemies in the world. game.world.children...
    // This might be expensive. Let's skip enemies for now or add later.
  }

  @override
  bool shouldRepaint(covariant MinimapPainter oldDelegate) {
    return true; // Repaint every frame/update is safest for smooth movement
  }
}
