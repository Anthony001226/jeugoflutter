
import 'package:flutter/material.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/models/player_stats.dart';

class StatusTabView extends StatelessWidget {
  final RenegadeDungeonGame game;
  const StatusTabView({super.key, required this.game});

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PlayerStats stats = game.player.stats;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ValueListenableBuilder<int>(
          valueListenable: stats.level,
          builder: (_, level, __) => _buildStatRow('Nivel', '$level'),
        ),

        ValueListenableBuilder<int>(
          valueListenable: stats.currentHp,
          builder: (_, currentHp, __) =>
              _buildStatRow('HP', '$currentHp / ${stats.maxHp.value}'),
        ),
        ValueListenableBuilder<int>(
          valueListenable: stats.currentMp,
          builder: (_, currentMp, __) =>
              _buildStatRow('MP', '$currentMp / ${stats.maxMp.value}'),
        ),
        ValueListenableBuilder<int>(
          valueListenable: stats.currentXp,
          builder: (_, currentXp, __) =>
              _buildStatRow('XP', '$currentXp / ${stats.xpToNextLevel.value}'),
        ),

        const Divider(color: Colors.grey, height: 40),

        ValueListenableBuilder<int>(
          valueListenable: stats.attack,
          builder: (_, attack, __) => _buildStatRow('Ataque', '$attack'),
        ),
        ValueListenableBuilder<int>(
          valueListenable: stats.defense,
          builder: (_, defense, __) => _buildStatRow('Defensa', '$defense'),
        ),
        ValueListenableBuilder<int>(
          valueListenable: stats.speed,
          builder: (_, speed, __) => _buildStatRow('Velocidad', '$speed'),
        ),
      ],
    );
  }
}
