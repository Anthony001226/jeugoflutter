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
    // Responsive layout calculations
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 800;
    final double barWidth = isSmallScreen ? 120 : 180;
    final double barHeight = isSmallScreen ? 14 : 20;
    final double iconSize = isSmallScreen ? 24 : 32;
    final double iconInnerSize = isSmallScreen ? 16 : 20;
    final double fontSize = isSmallScreen ? 10 : 12;
    final double padding = isSmallScreen ? 10 : 20;

    // Listen to isPlayerReadyNotifier to rebuild when player is ready
    return ValueListenableBuilder<bool>(
      valueListenable: game.isPlayerReadyNotifier,
      builder: (context, isReady, _) {
        // Also check if player is loaded and mounted
        if (!isReady || !game.player.isLoaded || !game.player.isMounted) {
          return const SizedBox.shrink();
        }

        return SizedBox.expand(
          child: Stack(
            children: [
              // Top Left: Stats Bars (HP, MP, XP)
              Positioned(
                top: padding,
                left: padding,
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
                          barWidth: barWidth,
                          barHeight: barHeight,
                          iconSize: iconSize,
                          iconInnerSize: iconInnerSize,
                          fontSize: fontSize,
                        );
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 8),

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
                          barWidth: barWidth,
                          barHeight: barHeight,
                          iconSize: iconSize,
                          iconInnerSize: iconInnerSize,
                          fontSize: fontSize,
                        );
                      },
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 8),

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
                          barWidth: barWidth,
                          barHeight: barHeight,
                          iconSize: iconSize,
                          iconInnerSize: iconInnerSize,
                          fontSize: fontSize,
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Currency Row (Gold & Gems)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Gold
                          Icon(Icons.monetization_on,
                              color: Colors.amber, size: iconInnerSize),
                          const SizedBox(width: 6),
                          ValueListenableBuilder<int>(
                            valueListenable: game.player.stats.gold,
                            builder: (context, gold, _) {
                              return Text(
                                '$gold',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontFamily: 'monospace',
                                  shadows: const [
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
                          Icon(Icons.diamond,
                              color: Colors.cyan, size: iconInnerSize),
                          const SizedBox(width: 6),
                          ValueListenableBuilder<int>(
                            valueListenable: game.player.stats.gems,
                            builder: (context, gems, _) {
                              return Text(
                                '$gems',
                                style: TextStyle(
                                  color: Colors.cyan,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontFamily: 'monospace',
                                  shadows: const [
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
                top: padding,
                right: padding,
                child: MinimapWidget(game: game),
              ),

              // Zone Notification (Centered Top)
              Positioned(
                top: isSmallScreen ? 60 : 100,
                left: 0,
                right: 0,
                child: ZoneNotificationWidget(game: game),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPixelBar({
    required String label,
    required int current,
    required int max,
    required Color color,
    required IconData icon,
    required double barWidth,
    required double barHeight,
    required double iconSize,
    required double iconInnerSize,
    required double fontSize,
  }) {
    final double percentage = max == 0 ? 0 : (current / max).clamp(0.0, 1.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon Container
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            border: Border.all(color: Colors.white54, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: color, size: iconInnerSize),
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        shadows: const [
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
