// lib/ui/player_hud.dart

import 'package:flutter/material.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/ui/minimap_widget.dart';
import 'package:renegade_dungeon/ui/zone_notification_widget.dart';

class PlayerHud extends StatelessWidget {
  final RenegadeDungeonGame game;

  const PlayerHud({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // Previene errores al inicio antes de que el jugador esté completamente cargado
    if (!game.isPlayerReady ||
        !game.player.isLoaded ||
        !game.player.isMounted) {
      return const SizedBox.shrink(); // No dibuja nada si no está listo
    }

    return Stack(
      children: [
        // Top Left: Stats Bars (HP, MP, XP)
        Positioned(
          top: 20,
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HP Bar
              ValueListenableBuilder<int>(
                valueListenable: game.player.stats.currentHp,
                builder: (context, currentHp, _) {
                  return _buildPixelBar(
                    label: 'HP',
                    current: currentHp,
                    max: game.player.stats.maxHp.value,
                    color: const Color(0xFFE74C3C), // Red
                    icon: Icons.favorite,
                  );
                },
              ),
              const SizedBox(height: 8),

              // MP Bar
              ValueListenableBuilder<int>(
                valueListenable: game.player.stats.currentMp,
                builder: (context, currentMp, _) {
                  return _buildPixelBar(
                    label: 'MP',
                    current: currentMp,
                    max: game.player.stats.maxMp.value,
                    color: const Color(0xFF3498DB), // Blue
                    icon: Icons.bolt,
                  );
                },
              ),
              const SizedBox(height: 8),

              // XP Bar
              ValueListenableBuilder<int>(
                valueListenable: game.player.stats.currentXp,
                builder: (context, currentXp, _) {
                  return _buildPixelBar(
                    label: 'XP',
                    current: currentXp,
                    max: game.player.stats.xpToNextLevel.value,
                    color: const Color(0xFFF1C40F), // Yellow/Gold
                    icon: Icons.star,
                  );
                },
              ),
              const SizedBox(height: 12),

              // Currency Row (Gold & Gems)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gold
                    const Icon(Icons.monetization_on,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    ValueListenableBuilder<int>(
                      valueListenable: game.player.stats.gold,
                      builder: (context, gold, _) {
                        return Text(
                          '$gold',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'monospace',
                            shadows: [
                              Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                  offset: Offset(1, 1))
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    // Gems
                    const Icon(Icons.diamond, color: Colors.cyan, size: 20),
                    const SizedBox(width: 6),
                    ValueListenableBuilder<int>(
                      valueListenable: game.player.stats.gems,
                      builder: (context, gems, _) {
                        return Text(
                          '$gems',
                          style: const TextStyle(
                            color: Colors.cyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'monospace',
                            shadows: [
                              Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                  offset: Offset(1, 1))
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Minimap (Top Right)
        Positioned(
          top: 20,
          right: 20,
          child: MinimapWidget(game: game),
        ),

        // Zone Notification (Centered Top)
        ZoneNotificationWidget(game: game),
      ],
    );
  }

  Widget _buildPixelBar({
    required String label,
    required int current,
    required int max,
    required Color color,
    required IconData icon,
  }) {
    const double barWidth = 180;
    const double barHeight = 20;
    final double percentage = max == 0 ? 0 : (current / max).clamp(0.0, 1.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon Container
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            border: Border.all(color: Colors.white54, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 8),

        // Bar Column
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bar Background
            Container(
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                border: Border.all(color: Colors.white54, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  // Fill
                  FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 4,
                            offset: const Offset(0, 0),
                          )
                        ],
                      ),
                    ),
                  ),
                  // Shine effect (top half)
                  FractionallySizedBox(
                    widthFactor: percentage,
                    heightFactor: 0.4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2),
                          topRight: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Text Overlay
                  Center(
                    child: Text(
                      '$current / $max',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        shadows: [
                          Shadow(
                              color: Colors.black,
                              blurRadius: 2,
                              offset: Offset(1, 1))
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
