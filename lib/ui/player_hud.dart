// lib/ui/player_hud.dart

import 'package:flutter/material.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class PlayerHud extends StatelessWidget {
  final RenegadeDungeonGame game;

  const PlayerHud({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // Previene errores al inicio antes de que el jugador esté completamente cargado
    if (!game.player.isLoaded || !game.player.isMounted) {
      return const SizedBox.shrink(); // No dibuja nada si no está listo
    }

    return Positioned(
      top: 20,
      left: 20,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x99000000), // Negro con 60% opacidad
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: const Color(0x33FFFFFF)), // Blanco con 20% opacidad
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Builder para el Nivel del Jugador
              ValueListenableBuilder<int>(
                valueListenable: game.player.stats.level,
                builder: (context, level, child) {
                  return Text(
                    'Nivel $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: TextDecoration.none,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              // Builder para la Barra de HP
              ValueListenableBuilder<int>(
                valueListenable: game.player.stats.currentHp,
                builder: (context, currentHp, child) {
                  // Este builder se redibuja solo cuando currentHp cambia.
                  // maxHp se lee directamente, pero se actualizará visualmente
                  // cuando el jugador suba de nivel porque este builder se reconstruirá.
                  return _buildStatBar(
                    label: 'HP',
                    currentValue: currentHp,
                    maxValue: game.player.stats.maxHp.value,
                    barColor: const Color(0xFFC73E3E), // Rojo
                  );
                },
              ),
              const SizedBox(height: 8),

              // Builder para la Barra de MP
              ValueListenableBuilder<int>(
                valueListenable: game.player.stats.currentMp,
                builder: (context, currentMp, child) {
                  return _buildStatBar(
                    label: 'MP',
                    currentValue: currentMp,
                    maxValue: game.player.stats.maxMp.value,
                    barColor: const Color(0xFF3E76C7), // Azul
                  );
                },
              ),
              const SizedBox(height: 8),

              // Builder para la Barra de XP
              ValueListenableBuilder<int>(
                valueListenable: game.player.stats.currentXp,
                builder: (context, currentXp, child) {
                  return _buildStatBar(
                    label: 'XP',
                    currentValue: currentXp,
                    maxValue: game.player.stats.xpToNextLevel.value,
                    barColor: const Color(0xFFC7C13E), // Amarillo/Dorado
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper para construir las barras y no repetir código
  Widget _buildStatBar({
    required String label,
    required int currentValue,
    required int maxValue,
    required Color barColor,
  }) {
    const double barWidth = 150;
    // Evita la división por cero si el valor máximo es 0
    final double factor = maxValue == 0 ? 0 : currentValue / maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: $currentValue / $maxValue',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: barWidth,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF333333), // Fondo oscuro de la barra
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: factor,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
