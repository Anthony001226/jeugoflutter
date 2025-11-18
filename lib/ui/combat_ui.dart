// lib/ui/combat_ui.dart

import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:renegade_dungeon/components/enemies/goblin_component.dart'; // ¡IMPORT AÑADIDO!
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/models/enemy_stats.dart';

class CombatUI extends StatelessWidget {
  final RenegadeDungeonGame game;

  const CombatUI({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // --- ¡SOLUCIÓN! ---
    // Hacemos una comprobación de nulos al principio para satisfacer al compilador.
    final enemy = game.combatManager.currentEnemy;
    if (enemy == null) {
      // Esto no debería pasar en la práctica, pero protege la app.
      return const Center(child: Text('Error: No se encontró el enemigo.', style: TextStyle(color: Colors.red)));
    }
    
    final enemyStats = (enemy as dynamic).stats as EnemyStats;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          children: [
            const Spacer(),
            ValueListenableBuilder<int>(
              valueListenable: game.player.stats.currentHp,
              builder: (context, playerHp, child) {
                if (playerHp == 0) {
                  return Column(
                    children: [
                      const Text('¡HAS SIDO DERROTADO!', style: TextStyle(fontSize: 24, color: Colors.redAccent)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => game.endCombat(),
                        child: const Text('Reiniciar desde Punto de Control'),
                      ),
                    ],
                  );
                }
                return ValueListenableBuilder<int>(
                  valueListenable: enemyStats.currentHp,
                  builder: (context, enemyHp, child) {
                    if (enemyHp == 0) {
                      return Column(
                        children: [
                          Text(
                            '¡ENEMIGO DERROTADO! (+${enemyStats.xpValue} XP)',
                            style: const TextStyle(fontSize: 24, color: Colors.greenAccent)
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => game.endCombat(),
                            child: const Text('Volver al Mapa'),
                          ),
                        ],
                      );
                    }
                    return _buildEnemyHealthBar(enemyHp, enemyStats);
                  },
                );
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: ValueListenableBuilder<int>(
                valueListenable: enemyStats.currentHp,
                builder: (context, enemyHp, child) {
                  if (game.player.stats.currentHp.value == 0 || enemyHp == 0) {
                    return const SizedBox.shrink();
                  }
                  return ValueListenableBuilder<CombatTurn>(
                    valueListenable: game.combatManager.currentTurn,
                    builder: (context, turn, child) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
                        onPressed: turn == CombatTurn.playerTurn
                            ? () {
                                game.combatManager.playerAttack();
                              }
                            : null,
                        child: Text(
                          turn == CombatTurn.playerTurn ? 'Atacar' : 'Turno del Enemigo...',
                          style: const TextStyle(fontSize: 20),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnemyHealthBar(int hp, EnemyStats stats) {
    // --- ¡SOLUCIÓN! ---
    // Usamos la variable enemyName que habíamos creado.
    final enemyName = game.combatManager.currentEnemy is GoblinComponent ? 'Goblin' : 'Slime';
    return Column(
      children: [
        Text('$enemyName HP: $hp / ${stats.maxHp}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'monospace')),
        const SizedBox(height: 8),
        Container(
          width: 200,
          height: 15,
          decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(8)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: hp / stats.maxHp,
            child: Container(
              decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}