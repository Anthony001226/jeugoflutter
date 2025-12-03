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
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    return ValueListenableBuilder<SpriteAnimationComponent?>(
      valueListenable: game.combatManager.currentEnemyNotifier,
      builder: (context, enemy, child) {
        // Handle Victory/Defeat logic via HP listeners
        // We wrap the main UI in these listeners to trigger screen changes
        return ValueListenableBuilder<int>(
          valueListenable: game.player.stats.currentHp,
          builder: (context, playerHp, child) {
            if (playerHp == 0) {
              return _buildDefeatScreen();
            }

            // If no enemy is selected but we are in combat, it might be a transition or error
            // But usually currentEnemy is set.
            // If enemy is null, check if we won
            if (enemy == null) {
              if (game.combatManager.currentEnemies.isEmpty &&
                  game.combatManager.lastDroppedItems.isNotEmpty) {
                // We don't have the last enemy stats here easily if 'enemy' is null
                // But usually the last enemy is still in 'enemy' when it dies?
                // Ah, currentEnemy might be null if cleared.
                // Let's rely on the HP listener of the *current* enemy if it exists.
                return const SizedBox();
              }
              return const SizedBox();
            }

            final enemyStats = (enemy as dynamic).stats as EnemyStats;

            return ValueListenableBuilder<int>(
              valueListenable: enemyStats.currentHp,
              builder: (context, enemyHp, child) {
                if (enemyHp <= 0) {
                  final isLastEnemy =
                      game.combatManager.currentEnemies.length <= 1;
                  if (isLastEnemy) {
                    return _buildVictoryScreen(enemyStats);
                  }
                  // If not last enemy, just show normal UI (enemy will be removed/swapped soon)
                }

                return Scaffold(
                  backgroundColor: Colors.transparent,
                  body: SafeArea(
                    child: Stack(
                      children: [
                        // 1. Top Center: Target Info
                        Positioned(
                          top: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _buildTargetPanel(
                                enemy, enemyStats, enemyHp, isMobile),
                          ),
                        ),

                        // 2. Center: Turn Indicator
                        Positioned(
                          top: size.height * 0.15,
                          left: 0,
                          right: 0,
                          child: Center(child: _buildTurnIndicator(isMobile)),
                        ),

                        // 3. Bottom Left: Player Stats
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: _buildPlayerPanel(isMobile),
                        ),

                        // 4. Bottom Right: Command Panel
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: _buildCommandPanel(isMobile),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- PANELS ---

  Widget _buildTargetPanel(SpriteAnimationComponent enemy, EnemyStats stats,
      int currentHp, bool isMobile) {
    String enemyName = game.combatManager.getEnemyName(enemy);
    // Simple name mapping
    if (enemy is GoblinComponent)
      enemyName = enemyName.replaceFirst('Enemigo', 'Goblin');
    else if (enemy is SlimeComponent)
      enemyName = enemyName.replaceFirst('Enemigo', 'Slime');
    else if (enemy is BatComponent)
      enemyName = enemyName.replaceFirst('Enemigo', 'Murciélago');
    else if (enemy is SkeletonComponent)
      enemyName = enemyName.replaceFirst('Enemigo', 'Esqueleto');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            enemyName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 16 : 20,
              shadows: const [
                Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))
              ],
            ),
          ),
          const SizedBox(height: 5),
          _buildBar(
            current: currentHp,
            max: stats.maxHp,
            width: isMobile ? 200 : 300,
            height: isMobile ? 12 : 16,
            color: Colors.red,
            label: '$currentHp / ${stats.maxHp}',
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerPanel(bool isMobile) {
    return Container(
      width: isMobile ? 180 : 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'JUGADOR',
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
            ),
          ),
          const Divider(color: Colors.white30, height: 10),

          // HP
          ValueListenableBuilder<int>(
            valueListenable: game.player.stats.combatStats.currentHp,
            builder: (context, hp, _) => _buildStatRow(
                'HP',
                hp,
                game.player.stats.combatStats.maxHp.value,
                Colors.red,
                isMobile),
          ),
          const SizedBox(height: 5),

          // MP
          ValueListenableBuilder<int>(
            valueListenable: game.player.stats.combatStats.currentMp,
            builder: (context, mp, _) => _buildStatRow(
                'MP',
                mp,
                game.player.stats.combatStats.maxMp.value,
                Colors.blue,
                isMobile),
          ),
          const SizedBox(height: 5),

          // ULT
          ValueListenableBuilder<int>(
            valueListenable: game.player.stats.combatStats.ultMeter,
            builder: (context, ult, _) =>
                _buildStatRow('ULT', ult, 100, Colors.purple, isMobile),
          ),

          const SizedBox(height: 8),
          // Status Effects
          ValueListenableBuilder<int>(
            valueListenable: game.player.stats.combatStats.effectsVersion,
            builder: (context, _, __) => _buildStatusEffects(isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandPanel(bool isMobile) {
    return ValueListenableBuilder<CombatTurn>(
      valueListenable: game.combatManager.currentTurn,
      builder: (context, turn, _) {
        if (turn != CombatTurn.playerTurn) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: Colors.greenAccent.withOpacity(0.5), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'COMANDOS',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
              const Divider(color: Colors.white30, height: 10),
              _buildAbilityButtons(isMobile),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade800,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 20, vertical: 10),
                ),
                onPressed: () => game.overlays.add('CombatInventoryUI'),
                icon: const Icon(Icons.backpack, size: 18),
                label: const Text('OBJETOS'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTurnIndicator(bool isMobile) {
    return ValueListenableBuilder<CombatTurn>(
      valueListenable: game.combatManager.currentTurn,
      builder: (context, turn, _) {
        final isPlayer = turn == CombatTurn.playerTurn;
        return AnimatedOpacity(
          opacity: 1.0, // Could animate this
          duration: const Duration(milliseconds: 500),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPlayer
                    ? [
                        Colors.transparent,
                        Colors.green.withOpacity(0.6),
                        Colors.transparent
                      ]
                    : [
                        Colors.transparent,
                        Colors.red.withOpacity(0.6),
                        Colors.transparent
                      ],
              ),
            ),
            child: Text(
              isPlayer ? 'TU TURNO' : 'TURNO ENEMIGO',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                      color: Colors.black, blurRadius: 4, offset: Offset(2, 2))
                ],
                letterSpacing: 2.0,
              ),
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildStatRow(
      String label, int current, int max, Color color, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            Text('$current/$max',
                style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 2),
        _buildBar(
            current: current,
            max: max,
            width: double.infinity,
            height: 6,
            color: color),
      ],
    );
  }

  Widget _buildBar(
      {required int current,
      required int max,
      required double width,
      required double height,
      required Color color,
      String? label}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (current / max).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.6), blurRadius: 4)
                ],
              ),
            ),
          ),
        ),
        if (label != null)
          Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
          ),
      ],
    );
  }

  Widget _buildStatusEffects(bool isMobile) {
    final effects = game.player.stats.combatStats.activeEffects;
    if (effects.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: effects.map((effect) {
        final isBuff = effect.type.toString().contains('Buff');
        final color = isBuff ? Colors.green : Colors.red;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${effect.name} (${effect.remainingTurns})',
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAbilityButtons(bool isMobile) {
    final abilities = game.player.stats.abilities;
    final playerStats = game.player.stats.combatStats;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
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

            return Tooltip(
              message: '${ability.description}\nCost: ${ability.getCostText()}',
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canUse
                      ? _getAbilityColor(ability.type)
                      : Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: canUse ? 4 : 0,
                ),
                onPressed: canUse
                    ? () => game.combatManager.usePlayerAbility(ability)
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ability.name,
                      style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      ability.getCostText(),
                      style: TextStyle(
                          fontSize: isMobile ? 9 : 10, color: Colors.white70),
                    ),
                  ],
                ),
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
        return Colors.blueGrey.shade600;
      case AbilityType.strong:
        return Colors.deepOrange.shade700;
      case AbilityType.skill:
        return Colors.indigo.shade600;
      case AbilityType.ultimate:
        return Colors.deepPurple.shade700;
    }
  }

  Widget _buildVictoryScreen(EnemyStats enemyStats) {
    final drops = game.combatManager.lastDroppedItems;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent, width: 3),
          boxShadow: [
            const BoxShadow(color: Colors.greenAccent, blurRadius: 20)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¡VICTORIA!',
                style: TextStyle(
                    fontSize: 32,
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3)),
            const SizedBox(height: 20),
            Text('+${enemyStats.xpValue} XP',
                style: const TextStyle(fontSize: 20, color: Colors.white)),
            if (drops.isNotEmpty) ...[
              const SizedBox(height: 15),
              const Text('Botín:',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              ...drops.map((item) => Text(item.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 16))),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () => game.endCombat(),
              child: const Text('CONTINUAR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefeatScreen() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent, width: 3),
          boxShadow: [const BoxShadow(color: Colors.redAccent, blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('DERROTADO',
                style: TextStyle(
                    fontSize: 32,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3)),
            const SizedBox(height: 20),
            const Text('Has caído en combate...',
                style: TextStyle(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () => game.endCombat(),
              child: const Text('RENACER',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
