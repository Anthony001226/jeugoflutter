// lib/ui/map_tab_view.dart

import 'package:flutter/material.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class MapTabView extends StatelessWidget {
  final RenegadeDungeonGame game;

  const MapTabView({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la zona actual
          Text(
            'Zona Actual: ${_getMapName()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Información del mapa
          Text(
            'Dimensiones: ${game.mapComponent.tileMap.map.width} x ${game.mapComponent.tileMap.map.height}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Posición del jugador: (${game.player.gridPosition.x.toInt()}, ${game.player.gridPosition.y.toInt()})',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          // Mapa visual
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a),
                border: Border.all(color: const Color(0xFF444444)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomPaint(
                  painter: MinimapPainter(game: game),
                  child: Container(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Leyenda
          _buildLegend(),
        ],
      ),
    );
  }

  String _getMapName() {
    // Por ahora retorna un nombre por defecto
    // En el futuro, esto se puede expandir para soportar múltiples mapas
    return 'Mazmorra Principal';
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(Colors.blue, 'Jugador'),
          _buildLegendItem(Colors.grey, 'Obstáculos'),
          _buildLegendItem(Colors.black, 'Piso'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.white54),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Custom painter que dibuja un minimapa del nivel actual
class MinimapPainter extends CustomPainter {
  final RenegadeDungeonGame game;

  MinimapPainter({required this.game});

  @override
  void paint(Canvas canvas, Size size) {
    final mapWidth = game.mapComponent.tileMap.map.width;
    final mapHeight = game.mapComponent.tileMap.map.height;

    // Calcula el tamaño de cada "pixel" del mapa
    final tileWidth = size.width / mapWidth;
    final tileHeight = size.height / mapHeight;
    final tileSize = tileWidth < tileHeight ? tileWidth : tileHeight;

    // Centra el mapa si es necesario
    final offsetX = (size.width - (mapWidth * tileSize)) / 2;
    final offsetY = (size.height - (mapHeight * tileSize)) / 2;

    final collisionData = game.collisionLayer.data;

    if (collisionData != null) {
      // Dibuja cada tile del mapa
      for (int y = 0; y < mapHeight; y++) {
        for (int x = 0; x < mapWidth; x++) {
          final tileIndex = y * mapWidth + x;
          if (tileIndex >= collisionData.length) continue;

          final isWall = collisionData[tileIndex] != 0;

          final paint = Paint()
            ..color = isWall ? Colors.grey.shade700 : Colors.black
            ..style = PaintingStyle.fill;

          canvas.drawRect(
            Rect.fromLTWH(
              offsetX + x * tileSize,
              offsetY + y * tileSize,
              tileSize,
              tileSize,
            ),
            paint,
          );
        }
      }
    }

    // Dibuja la posición del jugador
    final playerX = game.player.gridPosition.x;
    final playerY = game.player.gridPosition.y;

    final playerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Dibuja un círculo para el jugador (más visible)
    canvas.drawCircle(
      Offset(
        offsetX + (playerX * tileSize) + (tileSize / 2),
        offsetY + (playerY * tileSize) + (tileSize / 2),
      ),
      tileSize * 1.5, // Un poco más grande que un tile
      playerPaint,
    );

    // Añade un borde blanco al jugador para mejor visibilidad
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(
      Offset(
        offsetX + (playerX * tileSize) + (tileSize / 2),
        offsetY + (playerY * tileSize) + (tileSize / 2),
      ),
      tileSize * 1.5,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant MinimapPainter oldDelegate) {
    // Repinta cuando cambie la posición del jugador
    return oldDelegate.game.player.gridPosition != game.player.gridPosition;
  }
}
