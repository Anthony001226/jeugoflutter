import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../game/renegade_dungeon_game.dart';

class MinimapWidget extends StatelessWidget {
  final RenegadeDungeonGame game;
  final double size;

  const MinimapWidget({
    Key? key,
    required this.game,
    this.size = 180.0,
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

  @override
  void paint(Canvas canvas, Size size) {


    final double zoom = 6.0;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    final playerGridPos = game.player.gridPosition;

    final Paint bgPaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final Paint floorPaint = Paint()..color = Colors.grey.withOpacity(0.5);

    final int viewRadius = (size.width / 2 / zoom).ceil();
    final int startX = (playerGridPos.x - viewRadius).floor();
    final int endX = (playerGridPos.x + viewRadius).ceil();
    final int startY = (playerGridPos.y - viewRadius).floor();
    final int endY = (playerGridPos.y + viewRadius).ceil();

    for (int x = startX; x <= endX; x++) {
      for (int y = startY; y <= endY; y++) {
        final point = math.Point(x, y);
        if (game.exploredTiles.contains(point)) {
          final double dx = (x - playerGridPos.x) * zoom + centerX;
          final double dy = (y - playerGridPos.y) * zoom + centerY;

          canvas.drawRect(Rect.fromLTWH(dx, dy, zoom, zoom), floorPaint);
        }
      }
    }

    final Paint playerPaint = Paint()..color = Colors.greenAccent;
    canvas.drawCircle(Offset(centerX, centerY), 3.0, playerPaint);

  }

  @override
  bool shouldRepaint(covariant MinimapPainter oldDelegate) {
    return true;
  }
}
