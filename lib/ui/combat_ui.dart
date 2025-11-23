// lib/ui/combat_ui.dart

import 'package:flutter/material.dart';
import 'package:renegade_dungeon/components/enemies/goblin_component.dart';
import 'package:renegade_dungeon/components/enemies/slime_component.dart';
import 'package:renegade_dungeon/components/enemies/bat_component.dart';
import 'package:renegade_dungeon/components/enemies/skeleton_component.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/models/enemy_stats.dart';
import 'package:renegade_dungeon/models/combat_ability.dart';

class CombatUI extends StatelessWidget {
  final RenegadeDungeonGame game;

  const CombatUI({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final enemy = game.combatManager.currentEnemy;
    if (enemy == null) {
      return const Center(
          child: Text('Error: No se encontró el enemigo.',
              style: TextStyle(color: Colors.red)));
    }

    final enemyStats = (enemy as dynamic).stats as EnemyStats;

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow BattleScene to show through
      body: Center(
        child: Column(
          children: [
            const Spacer(),
            // Enemy Info
            ValueListenableBuilder<int>(
              valueListenable: game.player.stats.currentHp,
              builder: (context, playerHp, child) {
                if (playerHp == 0) {
                  return _buildDefeatScreen();
                }

                return ValueListenableBuilder<int>(
                  valueListenable: enemyStats.currentHp,
                  builder: (context, enemyHp, child) {
                    if (enemyHp == 0) {
                      return _buildVictoryScreen(enemyStats);
                    }
                    return _buildCombatScreen(enemyHp, enemyStats);
                  },
                );
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildCombatScreen(int enemyHp, EnemyStats enemyStats) {
    String enemyName = 'Enemigo';
    final enemy = game.combatManager.currentEnemy;
    if (enemy is GoblinComponent)
      enemyName = 'Goblin';
    else if (enemy is SlimeComponent)
      enemyName = 'Slime';
    else if (enemy is BatComponent)
      enemyName = 'Murciélago';
    else if (enemy is SkeletonComponent) enemyName = 'Esqueleto';

    return Column(
      children: [
        // Enemy HP
        Text('$enemyName HP: $enemyHp / ${enemyStats.maxHp}',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        const SizedBox(height: 8),
        Container(
          width: 250,
          height: 20,
          decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(10)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: enemyHp / enemyStats.maxHp,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Player Stats
        ValueListenableBuilder<int>(
          valueListenable: game.player.stats.combatStats.currentHp,
          builder: (context, hp, _) => _buildStatBar(
            'HP',
            hp,
            game.player.stats.combatStats.maxHp.value,
            Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<int>(
          valueListenable: game.player.stats.combatStats.currentMp,
          builder: (context, mp, _) => _buildStatBar(
            'MP',
            mp,
            game.player.stats.combatStats.maxMp.value,
            Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<int>(
          valueListenable: game.player.stats.combatStats.ultMeter,
          builder: (context, ult, _) => _buildStatBar(
            'ULT',
            ult,
            100,
            Colors.purple,
          ),
        ),
        const SizedBox(height: 40),

        // Turn Indicator
        ValueListenableBuilder<CombatTurn>(
          valueListenable: game.combatManager.currentTurn,
          builder: (context, turn, child) {
            final isPlayerTurn = turn == CombatTurn.playerTurn;
            return Column(
              children: [
                Text(
                  isPlayerTurn ? 'TU TURNO' : 'TURNO ENEMIGO',
                  style: TextStyle(
                    color: isPlayerTurn ? Colors.green : Colors.orange,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Ability Buttons
                if (isPlayerTurn) ...[
                  _buildAbilityButtons(),
                  const SizedBox(height: 15),
                  // Items Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                    ),
                    onPressed: () => game.overlays.add('CombatInventoryUI'),
                    child:
                        const Text('OBJETOS', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStatBar(String label, int current, int max, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Expanded(
            child: Container(
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(9),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (current / max).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              ' $current/$max',
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbilityButtons() {
    final abilities = game.player.stats.abilities;
    final playerStats = game.player.stats.combatStats;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: abilities.map((ability) {
        return ValueListenableBuilder<int>(
          valueListenable: ability.type == AbilityType.ultimate
              ? playerStats.ultMeter
              : playerStats.currentMp,
          builder: (context, resource, _) {
            final canUse = ability.canUse(
              playerStats.currentMp.value,
              playerStats.ultMeter.value,
            );

            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canUse
                    ? _getAbilityColor(ability.type)
                    : Colors.grey.shade800,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: canUse
                  ? () => game.combatManager.usePlayerAbility(ability)
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ability.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ability.getCostText(),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Color _getAbilityColor(AbilityType type) {
    switch (type) {
      case AbilityType.basic:
        return Colors.grey.shade700;
      case AbilityType.strong:
        return Colors.orange.shade700;
      case AbilityType.skill:
        return Colors.blue.shade700;
      case AbilityType.ultimate:
        return Colors.purple.shade700;
    }
  }

  Widget _buildVictoryScreen(EnemyStats enemyStats) {
    final drops = game.combatManager.lastDroppedItems;
    return Column(
      children: [
        Text('¡ENEMIGO DERROTADO! (+${enemyStats.xpValue} XP)',
            style: const TextStyle(fontSize: 24, color: Colors.greenAccent)),
        if (drops.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Botín Obtenido:',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          ...drops
              .map((item) => Text(item.name,
                  style: const TextStyle(color: Colors.amber, fontSize: 16)))
              .toList(),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => game.endCombat(),
          child: const Text('Volver al Mapa'),
        ),
      ],
    );
  }

  Widget _buildDefeatScreen() {
    return Column(
      children: [
        const Text('¡HAS SIDO DERROTADO!',
            style: TextStyle(fontSize: 24, color: Colors.redAccent)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => game.endCombat(),
          child: const Text('Reiniciar desde Punto de Control'),
        ),
      ],
    );
  }
}
