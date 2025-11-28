import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../game/renegade_dungeon_game.dart';

class FullMapOverlay extends StatelessWidget {
  final RenegadeDungeonGame game;
  final VoidCallback onClose;

  const FullMapOverlay({
    Key? key,
    required this.game,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Stack(
        children: [
          // Map Content
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CustomPaint(
                size: Size(
                  MediaQuery.of(context).size.width * 0.9,
                  MediaQuery.of(context).size.height * 0.9,
                ),
                painter: FullMapPainter(game: game),
              ),
            ),
          ),

          // Header / Controls
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WORLD MAP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PixelFont',
                      ),
                    ),
                    Text(
                      'Zone: ${game.currentMapName}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // Legend
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(Colors.greenAccent, 'Player'),
                  _buildLegendItem(Colors.grey, 'Explored'),
                  _buildLegendItem(Colors.black, 'Unknown', isBorder: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool isBorder = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              border: isBorder ? Border.all(color: Colors.white54) : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class FullMapPainter extends CustomPainter {
  final RenegadeDungeonGame game;

  FullMapPainter({required this.game});

  @override
  void paint(Canvas canvas, Size size) {
    // if (game.mapComponent == null) return; // mapComponent is late final

    // Determine scale to fit map in view
    // We want to show the whole map if possible, or at least a large chunk
    // Let's assume we want to fit the whole map into the available size

    // Map dimensions in tiles
    final double mapTilesX = game.mapComponent.tileMap.map.width.toDouble();
    final double mapTilesY = game.mapComponent.tileMap.map.height.toDouble();

    // Calculate scale to fit
    final double scaleX = size.width / mapTilesX;
    final double scaleY = size.height / mapTilesY;
    final double scale = math.min(scaleX, scaleY); // Keep aspect ratio

    // Center the map
    final double offsetX = (size.width - (mapTilesX * scale)) / 2;
    final double offsetY = (size.height - (mapTilesY * scale)) / 2;

    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    // Draw background (border of the map)
    final Paint borderPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(Rect.fromLTWH(0, 0, mapTilesX, mapTilesY), borderPaint);

    // Draw explored tiles
    final Paint exploredPaint = Paint()..color = Colors.grey.withOpacity(0.6);

    for (final point in game.exploredTiles) {
      canvas.drawRect(
          Rect.fromLTWH(point.x.toDouble(), point.y.toDouble(), 1.05,
              1.05), // Slight overlap to avoid gaps
          exploredPaint);
    }

    // Draw Player
    final playerPos = game.player.gridPosition;
    final Paint playerPaint = Paint()..color = Colors.greenAccent;
    // Draw player slightly larger than a tile for visibility
    canvas.drawCircle(Offset(playerPos.x, playerPos.y), 1.5, playerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
