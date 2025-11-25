// lib/ui/combat_ui.dart

import 'package:flutter/material.dart';
import 'package:flame/components.dart';
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
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SpriteAnimationComponent?>(
      valueListenable: game.combatManager.currentEnemyNotifier,
      builder: (context, enemy, child) {
        if (enemy == null) {
          // If no enemy is selected, check if we won (all enemies dead)
          if (game.combatManager.currentEnemies.isEmpty &&
              game.combatManager.lastDroppedItems.isNotEmpty) {
            // We can't easily get stats here if enemy is null, but we can show a generic victory or use the last known stats if we stored them.
            // For now, let's assume if enemy is null and we are in combat, it might be an error OR victory transition.
            // But usually _removeDefeatedEnemy sets currentEnemy to null ONLY if all are dead.
            return const SizedBox(); // Wait for state change or show nothing
          }
          return const Center(
              child: Text('Error: No se encontró el enemigo.',
                  style: TextStyle(color: Colors.red)));
        }

        final enemyStats = (enemy as dynamic).stats as EnemyStats;

        return Scaffold(
          backgroundColor: Colors.transparent,
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
                        // Only show victory if HP is 0 AND it's the last enemy
                        if (enemyHp <= 0) {
                          final isLastEnemy =
                              game.combatManager.currentEnemies.length <= 1;
                          if (isLastEnemy) {
                            return _buildVictoryScreen(enemyStats);
                          }
                          // If not last enemy, just show combat screen (it will switch soon)
                          return _buildCombatScreen(0, enemyStats);
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
      },
    );
  }

  Widget _buildCombatScreen(int enemyHp, EnemyStats enemyStats) {
    String enemyName = 'Enemigo';
    final enemy = game.combatManager.currentEnemy;
    if (enemy != null) {
      enemyName = game.combatManager.getEnemyName(enemy);

      // Append type if needed, or just use the name which already has #ID
      // e.g. "Enemigo #2"
      // If we want "Goblin #2", we need to store that in the map or construct it.
      // Currently getEnemyName returns "Enemigo #X".
      // Let's improve getEnemyName to include type if possible, or just use what we have.

      // Actually, let's check if we can make it more descriptive in CombatManager later.
      // For now, "Enemigo #X" is consistent with logs.

      // If we want to show type:
      if (enemy is GoblinComponent)
        enemyName = enemyName.replaceFirst('Enemigo', 'Goblin');
      else if (enemy is SlimeComponent)
        enemyName = enemyName.replaceFirst('Enemigo', 'Slime');
      else if (enemy is BatComponent)
        enemyName = enemyName.replaceFirst('Enemigo', 'Murciélago');
      else if (enemy is SkeletonComponent)
        enemyName = enemyName.replaceFirst('Enemigo', 'Esqueleto');
    }

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
        // NEW: Status Effects Display
        ValueListenableBuilder<int>(
          valueListenable: game.player.stats.combatStats.effectsVersion,
          builder: (context, _, __) {
            final effects = game.player.stats.combatStats.activeEffects;
            if (effects.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: effects.map((effect) {
                  final isBuff = effect.type.toString().contains('Buff');
                  final color = isBuff ? Colors.green : Colors.red;

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      border: Border.all(color: color, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          effect.name,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${effect.remainingTurns})',
                          style: TextStyle(
                              color: color.withOpacity(0.8), fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
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
