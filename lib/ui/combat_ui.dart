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
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return ValueListenableBuilder<SpriteAnimationComponent?>(
      valueListenable: game.combatManager.currentEnemyNotifier,
      builder: (context, enemy, child) {
        if (enemy == null) {
          if (game.combatManager.currentEnemies.isEmpty &&
              game.combatManager.lastDroppedItems.isNotEmpty) {
            return const SizedBox();
          }
          return const Center(
              child: Text('Error: No se encontró el enemigo.',
                  style: TextStyle(color: Colors.red)));
        }

        final enemyStats = (enemy as dynamic).stats as EnemyStats;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Enemy Info
                    ValueListenableBuilder<int>(
                      valueListenable: game.player.stats.currentHp,
                      builder: (context, playerHp, child) {
                        if (playerHp == 0) {
                          // If ReviveDialog is active, we might not want to show this,
                          // but for now let's keep it as a background state
                          return _buildDefeatScreen();
                        }

                        return ValueListenableBuilder<int>(
                          valueListenable: enemyStats.currentHp,
                          builder: (context, enemyHp, child) {
                            if (enemyHp <= 0) {
                              final isLastEnemy =
                                  game.combatManager.currentEnemies.length <= 1;
                              if (isLastEnemy) {
                                return _buildVictoryScreen(enemyStats);
                              }
                              return _buildCombatScreen(
                                  0, enemyStats, isMobile);
                            }
                            return _buildCombatScreen(
                                enemyHp, enemyStats, isMobile);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCombatScreen(int enemyHp, EnemyStats enemyStats, bool isMobile) {
    String enemyName = 'Enemigo';
    final enemy = game.combatManager.currentEnemy;
    if (enemy != null) {
      enemyName = game.combatManager.getEnemyName(enemy);
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
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 16 : 20)),
        const SizedBox(height: 8),
        Container(
          width: isMobile ? 200 : 250,
          height: isMobile ? 15 : 20,
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
        SizedBox(height: isMobile ? 20 : 40),

        // Player Stats
        ValueListenableBuilder<int>(
          valueListenable: game.player.stats.combatStats.currentHp,
          builder: (context, hp, _) => _buildStatBar(
            'HP',
            hp,
            game.player.stats.combatStats.maxHp.value,
            Colors.red,
            isMobile,
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
            isMobile,
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
            isMobile,
          ),
        ),
        // Status Effects
        ValueListenableBuilder<int>(
          valueListenable: game.player.stats.combatStats.effectsVersion,
          builder: (context, _, __) {
            final effects = game.player.stats.combatStats.activeEffects;
            if (effects.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 40, vertical: 8),
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
        SizedBox(height: isMobile ? 20 : 40),

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
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Ability Buttons
                if (isPlayerTurn) ...[
                  _buildAbilityButtons(isMobile),
                  const SizedBox(height: 15),
                  // Items Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 20 : 40, vertical: 15),
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

  Widget _buildStatBar(
      String label, int current, int max, Color color, bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
      child: Row(
        children: [
          SizedBox(
            width: isMobile ? 35 : 50,
            child: Text(
              label,
              style:
                  TextStyle(color: Colors.white, fontSize: isMobile ? 12 : 14),
            ),
          ),
          Expanded(
            child: Container(
              height: isMobile ? 14 : 18,
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
            width: isMobile ? 60 : 70,
            child: Text(
              ' $current/$max',
              style:
                  TextStyle(color: Colors.white, fontSize: isMobile ? 12 : 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbilityButtons(bool isMobile) {
    final abilities = game.player.stats.abilities;
    final playerStats = game.player.stats.combatStats;

    return ValueListenableBuilder<CombatTurn>(
      valueListenable: game.combatManager.currentTurn,
      builder: (context, currentTurn, _) {
        final isPlayerTurn = currentTurn == CombatTurn.playerTurn;

        return Wrap(
          spacing: isMobile ? 6 : 10,
          runSpacing: isMobile ? 6 : 10,
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
                    backgroundColor: (canUse && isPlayerTurn)
                        ? _getAbilityColor(ability.type)
                        : Colors.grey.shade800,
                    padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 20,
                        vertical: isMobile ? 8 : 12),
                  ),
                  onPressed: (canUse && isPlayerTurn)
                      ? () => game.combatManager.usePlayerAbility(ability)
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ability.name,
                        style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ability.getCostText(),
                        style: TextStyle(fontSize: isMobile ? 10 : 11),
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        );
      },
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
