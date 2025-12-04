// lib/game/renegade_dungeon_game.dart

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:renegade_dungeon/game/menu_route_component.dart';
import 'package:renegade_dungeon/game/loading_route_component.dart';
import 'package:renegade_dungeon/game/intro_route_component.dart';
import 'package:flame/game.dart';

import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/widgets.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:math';
import 'dart:math' as math;
import 'dart:async';
import 'dart:io' show Platform;

import '../components/battle_scene.dart';
import '../components/player.dart';
import '../components/chest.dart';
import 'game_screen.dart';
import 'package:renegade_dungeon/game/splash_screen.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import '../models/enemy_stats.dart';
import '../models/combat_ability.dart';
import '../models/turn_entity.dart';

import '../models/combat_stats_holder.dart';
import '../utils/damage_calculator.dart';
import '../game/enemy_ai.dart';
import '../models/ability_database.dart';
import '../models/zone_config.dart';
import '../models/item_rarity.dart';
import '../components/portal_visual.dart';
import '../models/conditional_barrier.dart';

import '../components/enemies/goblin_component.dart';
import '../components/enemies/slime_component.dart';
import '../components/enemies/bat_component.dart';
import '../components/enemies/skeleton_component.dart';
import '../components/enemies/boss1_component.dart';
import 'package:flame/effects.dart';
import '../effects/screen_fade.dart';
import 'package:flame_audio/flame_audio.dart';
import '../models/npc.dart';
import '../components/npc_component.dart';
import '../services/iap_service.dart';
import '../services/offline_storage_service.dart';

import '../services/auth_service.dart';
import '../models/player_save_data.dart';

// Â¡YA NO NECESITAMOS TANTAS IMPORTACIONES DE COMPONENTES AQUÃ!
// PORQUE AHORA VIVEN EN GameScreen

enum GameState {
  exploring,
  inCombat,
  inMenu,
}

enum CombatTurn {
  playerTurn,
  enemyTurn,
}

class CombatManager {
  // ... (Esta clase no cambia en absoluto)
  final RenegadeDungeonGame game;

  // Backing field for currentEnemy
  SpriteAnimationComponent? _currentEnemy;

  // Notifier for UI updates
  final ValueNotifier<SpriteAnimationComponent?> currentEnemyNotifier =
      ValueNotifier(null);

  // Getter and Setter
  SpriteAnimationComponent? get currentEnemy => _currentEnemy;
  set currentEnemy(SpriteAnimationComponent? value) {
    _currentEnemy = value;
    currentEnemyNotifier.value = value;
  }

  // NEW: Multi-enemy support
  List<SpriteAnimationComponent> currentEnemies = [];
  Map<SpriteAnimationComponent, String> enemyNames = {}; // Permanent names
  int selectedTargetIndex = 0;

  bool isProcessingAbility = false;

  // NEW: Turn Queue System
  List<TurnEntity> turnQueue = [];
  int currentTurnIndex = -1;

  late final ValueNotifier<CombatTurn> currentTurn;
  List<InventoryItem> lastDroppedItems = [];
  int totalXpEarned = 0; // NEW: Accumulate XP to award at end
  int totalGoldEarned = 0; // NEW: Accumulate Gold to award at end

  CombatManager(this.game) {
    currentTurn = ValueNotifier(CombatTurn.playerTurn);
  }

  void selectTarget(SpriteAnimationComponent target) {
    if (!currentEnemies.contains(target)) return;

    selectedTargetIndex = currentEnemies.indexOf(target);
    // Update currentEnemy for UI compatibility
    currentEnemy = target;

    print('🎯 Target selected: ${enemyNames[target]}');
  }

  /// Start combat against a single enemy (Legacy wrapper)
  void startNewCombat(String enemyType) {
    startNewCombatMulti([enemyType]);
  }

  // NEW: Boss Combat Support
  String? currentBossId;

  void startBossCombat(String bossId, String enemyType) {
    print('⚔️ Iniciando BOSS FIGHT: $bossId ($enemyType)');
    startNewCombatMulti([enemyType]);
    currentBossId = bossId; // Set AFTER clearing state
  }

  /// Start combat against multiple enemies with Individual Initiative
  void startNewCombatMulti(List<String> enemyTypes) {
    print(
        'âš”ï¸ Iniciando combate multi-enemigo: ${enemyTypes.length} enemigos');

    // 1. Clear previous state
    currentEnemies.clear();
    enemyNames.clear();
    lastDroppedItems.clear(); // Clear loot from previous battle
    totalXpEarned = 0; // Reset XP counter
    totalGoldEarned = 0; // Reset Gold counter
    currentEnemy = null;
    selectedTargetIndex = 0;
    turnQueue.clear();
    turnQueue.clear();
    currentTurnIndex = -1;
    currentBossId = null; // Clear boss state for normal fights

    // 2. Create enemies
    for (int i = 0; i < enemyTypes.length; i++) {
      final enemyType = enemyTypes[i];
      SpriteAnimationComponent enemy;
      switch (enemyType) {
        case 'goblin':
          enemy = GoblinComponent();
          break;
        case 'slime':
          enemy = SlimeComponent();
          break;
        case 'bat':
          enemy = BatComponent();
          break;
        case 'skeleton':
          enemy = SkeletonComponent();
          break;
        case 'boss1':
          enemy = Boss1Component();
          break;
        default:
          enemy = SlimeComponent();
      }
      currentEnemies.add(enemy);
      // Assign permanent name (1-based index)
      enemyNames[enemy] = 'Enemigo #${i + 1}';
    }

    // 3. Apply scaling
    _applyGroupScaling();

    // 4. Set initial currentEnemy
    if (currentEnemies.isNotEmpty) {
      currentEnemy = currentEnemies[0];
    }

    // 5. Roll Initiatives & Build Queue
    final playerSpeed = game.player.stats.speed.value;
    final playerInit = playerSpeed + Random().nextInt(11);

    // Add Player to queue
    turnQueue.add(TurnEntity(isPlayer: true, initiative: playerInit));

    // Add Enemies to queue
    for (int i = 0; i < currentEnemies.length; i++) {
      final enemy = currentEnemies[i];
      final speed = (enemy as dynamic).stats.speed ?? 5;
      final enemySpeed = (speed is int) ? speed : (speed as num).toInt();
      final enemyInit = enemySpeed + Random().nextInt(11);

      turnQueue.add(
          TurnEntity(isPlayer: false, enemy: enemy, initiative: enemyInit));
    }

    // 6. Sort Queue (Higher initiative first)
    turnQueue.sort((a, b) => b.initiative.compareTo(a.initiative));

    print('ðŸ“œ Orden de Turnos: $turnQueue');

    // 7. Start First Turn
    nextTurn();
  }

  /// Proceed to the next turn in the queue
  void nextTurn() {
    if (turnQueue.isEmpty) return;

    // Increment index (looping)
    currentTurnIndex = (currentTurnIndex + 1) % turnQueue.length;
    final currentEntity = turnQueue[currentTurnIndex];

    print('ðŸ‘‰ Turno de: $currentEntity');

    // NEW: Process status effects at the start of this entity's turn
    if (currentEntity.isPlayer) {
      game.player.stats.combatStats.tickEffects();
    } else if (currentEntity.enemy != null) {
      final stats = (currentEntity.enemy as dynamic).stats;
      if (stats is CombatStatsHolder) {
        stats.combatStats.tickEffects();
      }
    }

    if (currentEntity.isPlayer) {
      // Player's Turn
      currentTurn.value = CombatTurn.playerTurn;
      isProcessingAbility = false;
      print('ðŸŽ® Tu turno!');
    } else {
      // Enemy's Turn
      currentTurn.value = CombatTurn.enemyTurn;

      // Highlight the acting enemy (optional but helpful)
      // We could update target to this enemy, but might be confusing if player was targeting someone else.
      // For now, just execute logic.

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (currentEntity.enemy != null) {
          // Find index of this enemy to pass to _enemyTakeTurn
          final index = currentEnemies.indexOf(currentEntity.enemy!);
          if (index != -1) {
            _enemyTakeTurn(currentEntity.enemy!, index);
          } else {
            // Enemy might have died? Skip.
            nextTurn();
          }
        } else {
          nextTurn();
        }
      });
    }
  }

  void playerAttack() {
    if (currentTurn.value != CombatTurn.playerTurn || currentEnemy == null)
      return;
    final playerAttackPower = game.player.stats.attack.value;
    final enemyStats = (currentEnemy as dynamic).stats as EnemyStats;
    enemyStats.takeDamage(playerAttackPower);
    if (enemyStats.currentHp.value == 0) {
      // El enemigo ha sido derrotado.
      game.player.stats.gainXp(enemyStats.xpValue);

      // --- Â¡LÃ“GICA DEL DROP DE BOTÃN! ---
      // Limpiamos la lista de drops anteriores.
      lastDroppedItems.clear();
      final random = Random();

      // Recorremos la tabla de botÃ­n del enemigo.
      enemyStats.lootTable.forEach((item, chance) {
        // Lanzamos un "dado" de 0.0 a 1.0.
        if (random.nextDouble() < chance) {
          // Â¡Ã‰xito! AÃ±adimos el objeto al jugador y a nuestra lista de drops.
          game.player.addItem(item);
          lastDroppedItems.add(item);
        }
      });
      // ---------------------------------

      return; // Termina el turno, no hay contraataque.
    }

    currentTurn.value = CombatTurn.enemyTurn;
    Future.delayed(const Duration(seconds: 1), () {
      enemyAttack();
    });
  }

  void enemyAttack() {
    if (currentEnemy == null) return;
    final enemyStats = (currentEnemy as dynamic).stats;
    game.player.stats.takeDamage(enemyStats.attack);
    if (game.player.stats.currentHp.value == 0) {
      game.onPlayerDeath();
      return;
    }
    currentTurn.value = CombatTurn.playerTurn;
  }

  void playerUseItem(InventorySlot slot) {
    // 1. Nos aseguramos de que sea el turno del jugador y de que el objeto sea usable.
    if (currentTurn.value != CombatTurn.playerTurn || !slot.item.isUsable) {
      return; // No hacemos nada si no se cumplen las condiciones.
    }

    // 2. Le decimos al jugador que use el objeto.
    // Esto aplicarÃ¡ el efecto y consumirÃ¡ una unidad del inventario.
    game.player.useItem(slot);

    // 3. Â¡MUY IMPORTANTE! El turno del jugador ha terminado.
    // Le pasamos el control al siguiente turno.
    // currentTurn.value = CombatTurn.enemyTurn; // REMOVED: Managed by nextTurn

    // 4. Programamos el siguiente turno.
    final isMultiEnemy = currentEnemies.isNotEmpty;
    Future.delayed(const Duration(seconds: 1), () {
      if (isMultiEnemy) {
        nextTurn();
      } else {
        currentTurn.value = CombatTurn.enemyTurn;
        Future.delayed(const Duration(seconds: 1), () {
          enemyUseAbility();
        });
      }
    });
  }

  // === NUEVO SISTEMA DE HABILIDADES ===

  /// Usa una habilidad del jugador contra el enemigo
  void usePlayerAbility(CombatAbility ability) {
    // Prevent double execution
    if (isProcessingAbility) {
      print('âš ï¸ Ya procesando habilidad, ignorando clic...');
      return;
    }

    if (currentTurn.value != CombatTurn.playerTurn) {
      print('âš ï¸ No es tu turno!');
      return;
    }

    isProcessingAbility = true; // Lock

    // Check if in multi-enemy or single-enemy mode
    final isMultiEnemy = currentEnemies.isNotEmpty;
    final targetEnemy =
        isMultiEnemy ? currentEnemies[selectedTargetIndex] : currentEnemy;

    if (currentTurn.value != CombatTurn.playerTurn || targetEnemy == null) {
      print('âŒ No es turno del jugador o no hay enemigo');
      return;
    }

    final playerStats = game.player.stats.combatStats;

    // Verificar si puede usar la habilidad
    if (!ability.canUse(
        playerStats.currentMp.value, playerStats.ultMeter.value)) {
      print('âŒ No se puede usar ${ability.name}: recursos insuficientes');
      return;
    }

    // Handle All Enemies Targeting
    if (ability.effect.targetType == TargetType.allEnemies) {
      if (currentEnemies.isEmpty) {
        print('❌ No hay enemigos para atacar');
        return;
      }

      print('⚔️ Jugador usa: ${ability.name} contra TODOS los enemigos');

      // Consumir recursos una sola vez
      if (ability.type == AbilityType.ultimate) {
        playerStats.spendUlt();
      } else if (ability.mpCost > 0) {
        playerStats.spendMp(ability.mpCost);
      }

      // Apply damage to ALL enemies
      final enemiesToHit = List<SpriteAnimationComponent>.from(currentEnemies);

      for (final enemy in enemiesToHit) {
        final enemyStats = (enemy as dynamic).stats as EnemyStats;

        final grossDamage = DamageCalculator.calculateDamage(
          ability: ability,
          attackerAtk: playerStats.effectiveAttack,
          defenderDef: 0,
          critChance: playerStats.critChance.value,
        );

        final enemyDef = enemyStats.defense;
        final estimatedNetDamage = (grossDamage - enemyDef).clamp(1, 999);

        enemyStats.takeDamage(grossDamage);
        print(
            '💥 ${ability.name} golpeó a un enemigo por $estimatedNetDamage de daño!');

        playerStats.gainUltCharge(ability.effect.ultGain);

        if (enemyStats.currentHp.value <= 0) {
          _handleEnemyDeath(enemy, enemyStats);
        }
      }

      print('⏳ Fin del turno del jugador (AoE). Siguiente turno...');
      Future.delayed(const Duration(seconds: 1), () {
        if (currentEnemies.isNotEmpty) nextTurn();
      });
      return;
    }

    if (isMultiEnemy) {
      final enemyName = getEnemyName(targetEnemy);
      print('âš”ï¸ Jugador usa: ${ability.name} contra $enemyName');
    } else {
      print('âš”ï¸ Jugador usa: ${ability.name}');
    }

    // Consumir recursos
    if (ability.type == AbilityType.ultimate) {
      playerStats.spendUlt();
    } else if (ability.mpCost > 0) {
      playerStats.spendMp(ability.mpCost);
    }

    // Calcular y aplicar daÃ±o
    final enemyStats = (targetEnemy as dynamic).stats as EnemyStats;

    // NOTA: Pasamos 0 como defensa aquÃ­ para obtener el daÃ±o BRUTO.
    // La defensa se restarÃ¡ dentro de takeDamage().
    // Use effectiveAttack to include buffs
    final grossDamage = DamageCalculator.calculateDamage(
      ability: ability,
      attackerAtk:
          playerStats.effectiveAttack, // Changed to use effective stats
      defenderDef: 0, // 0 aquÃ­ porque takeDamage restarÃ¡ la defensa
      critChance: playerStats.critChance.value,
    );

    final enemyDef = enemyStats.defense;
    final estimatedNetDamage = (grossDamage - enemyDef).clamp(1, 999);

    enemyStats.takeDamage(grossDamage);
    print(
        'ðŸ’¥ ${ability.name} hizo $estimatedNetDamage de daÃ±o! (Bruto: $grossDamage - Def: $enemyDef)');
    print('ðŸ” DEBUG: Enemy HP after damage: ${enemyStats.currentHp.value}');

    // Ganar carga de Ultimate
    playerStats.gainUltCharge(ability.effect.ultGain);

    // Verificar si el enemigo murió
    if (enemyStats.currentHp.value <= 0) {
      _handleEnemyDeath(targetEnemy, enemyStats);
      return;
    }

    print('â³ Fin del turno del jugador. Siguiente turno...');
    // End player turn, proceed to next in queue
    Future.delayed(const Duration(seconds: 1), () {
      if (isMultiEnemy) {
        nextTurn();
      } else {
        // Legacy single enemy support
        currentTurn.value = CombatTurn.enemyTurn;
        Future.delayed(const Duration(seconds: 1), () {
          enemyUseAbility();
        });
      }
    });
  }

  void _handleEnemyDeath(
      SpriteAnimationComponent enemy, EnemyStats enemyStats) {
    print('💀 ¡Enemigo derrotado! (HP <= 0 detected)');

    // NEW: Accumulate XP instead of giving immediately
    totalXpEarned += enemyStats.xpValue;
    totalGoldEarned += enemyStats.goldDrop;
    print(
        '📊 XP acumulado: +${enemyStats.xpValue} (Total: $totalXpEarned) | 💰 Gold: +${enemyStats.goldDrop} (Total: $totalGoldEarned)');

    // Loot drop - ACCUMULATE items (don't clear the list)
    final random = Random();
    enemyStats.lootTable.forEach((item, chance) {
      if (random.nextDouble() < chance) {
        game.player.addItem(item);
        lastDroppedItems.add(item);
      }
    });

    // Handle multi-enemy defeat
    if (currentEnemies.isNotEmpty) {
      // Find index of this enemy
      int index = currentEnemies.indexOf(enemy);
      if (index != -1) {
        // Check if this is the LAST enemy
        if (currentEnemies.length == 1) {
          print('🎉 ¡Último enemigo derrotado!');

          // NEW: Boss Persistence
          if (currentBossId != null) {
            game.player.stats.defeatBoss(currentBossId!);
            print('🏆 Boss Persistence: Saved kill for $currentBossId');
          }

          // NEW: Award all XP and Gold at END of battle
          game.player.stats.gainXp(totalXpEarned);
          game.player.stats.gold.value += totalGoldEarned;
          print(
              '⭐ XP TOTAL GANADO: $totalXpEarned | 💰 GOLD TOTAL: $totalGoldEarned');
          print('🌟 XP TOTAL GANADO: $totalXpEarned');
          return;
        }

        _removeDefeatedEnemy(index);
      }
    } else {
      // Single enemy legacy mode
      game.player.stats.gainXp(totalXpEarned);
      game.player.stats.gold.value += totalGoldEarned;
      return;
    }
  }

  /// El enemigo usa una habilidad elegida por IA
  void enemyUseAbility() {
    if (currentEnemy == null) return;

    final enemyStats = (currentEnemy as dynamic).stats;

    // Check if enemy is already dead
    if (enemyStats.currentHp.value <= 0) {
      print('ðŸ’€ Â¡Enemigo derrotado! (Cancelando turno enemigo)');
      return;
    }

    final enemyCombatStats =
        (enemyStats is EnemyStats && enemyStats is CombatStatsHolder)
            ? (enemyStats as CombatStatsHolder).combatStats
            : null;

    // Si el enemigo no tiene CombatStats, usar ataque simple
    if (enemyCombatStats == null) {
      print('ðŸ¤– Enemigo usa ataque simple (sin CombatStats)');
      game.player.stats.takeDamage(enemyStats.attack);
      if (game.player.stats.currentHp.value == 0) return;
      currentTurn.value = CombatTurn.playerTurn;
      return;
    }

    // Obtener habilidades del enemigo
    final enemyType = _getEnemyType();
    final abilities = AbilityDatabase.getEnemyAbilities(enemyType);

    if (abilities.isEmpty) {
      print('ðŸ¤– Enemigo usa ataque simple (sin habilidades)');
      game.player.stats.takeDamage(enemyStats.attack);
      if (game.player.stats.currentHp.value == 0) return;
      currentTurn.value = CombatTurn.playerTurn;
      return;
    }

    // Usar IA para elegir habilidad
    final chosenAbility = EnemyAI.chooseAbility(
      abilities: abilities,
      stats: enemyCombatStats,
    );

    print('ðŸ¤– Enemigo usa: ${chosenAbility.name}');

    // Consumir recursos del enemigo
    if (chosenAbility.type == AbilityType.ultimate) {
      enemyCombatStats.spendUlt();
    } else if (chosenAbility.mpCost > 0) {
      enemyCombatStats.spendMp(chosenAbility.mpCost);
    }

    // Calcular daÃ±o
    // NOTA: Pasamos 0 como defensa aquÃ­ para obtener el daÃ±o BRUTO (Gross Damage).
    // La defensa se restarÃ¡ dentro de takeDamage().
    // Use effectiveAttack to include enemy buffs
    final grossDamage = DamageCalculator.calculateDamage(
      ability: chosenAbility,
      attackerAtk: enemyCombatStats.effectiveAttack, // Uses buffed attack
      defenderDef: 0, // 0 aquÃ­ porque takeDamage restarÃ¡ la defensa
      critChance: enemyCombatStats.critChance.value,
    );

    // Para el log, calculamos cuÃ¡nto serÃ¡ el daÃ±o NETO aproximado
    final playerDef = game.player.stats.combatStats.effectiveDefense;
    final estimatedNetDamage = (grossDamage - playerDef).clamp(1, 999);

    game.player.stats.takeDamage(grossDamage);
    print(
        'ðŸ’¥ El enemigo hizo $estimatedNetDamage de daÃ±o! (Bruto: $grossDamage - Def: $playerDef)');

    // Ganar ULT al recibir daÃ±o (ya estÃ¡ en PlayerStats.takeDamage)

    if (game.player.stats.currentHp.value == 0) {
      print('ðŸ’€ Â¡Jugador derrotado!');
      // game.endCombat(); // REMOVED: Let UI handle defeat screen
      return;
    }

    currentTurn.value = CombatTurn.playerTurn;
  }

  /// Helper para obtener el tipo de enemigo actual
  String _getEnemyType() {
    if (currentEnemy is GoblinComponent) return 'goblin';
    if (currentEnemy is SlimeComponent) return 'slime';
    if (currentEnemy is BatComponent) return 'bat';
    if (currentEnemy is SkeletonComponent) return 'skeleton';
    return 'slime'; // fallback
  }

  /// Get permanent name for an enemy
  String getEnemyName(SpriteAnimationComponent enemy) {
    return enemyNames[enemy] ?? 'Enemigo';
  }

  /// Get enemy type for a specific enemy component
  String _getEnemyTypeForComponent(SpriteAnimationComponent enemy) {
    if (enemy is GoblinComponent) return 'goblin';
    if (enemy is SlimeComponent) return 'slime';
    if (enemy is BatComponent) return 'bat';
    if (enemy is SkeletonComponent) return 'skeleton';
    return 'slime'; // fallback
  }

  /// Apply stat scaling for group encounters (2 enemies = 70%, 3 enemies = 60%)
  void _applyGroupScaling() {
    if (currentEnemies.length <= 1) return;

    final scaleFactor = currentEnemies.length == 2 ? 0.7 : 0.6;
    print(
        'âš–ï¸ Aplicando balance de grupo (${currentEnemies.length} enemigos): ${(scaleFactor * 100).toInt()}% stats');

    for (final enemy in currentEnemies) {
      final stats = (enemy as dynamic).stats;

      // Handle different stat types
      if (stats is EnemyStats) {
        // EnemyStats: modify currentHp directly (no mutable maxHp/attack)
        final originalHp = stats.maxHp;
        stats.currentHp.value = (originalHp * scaleFactor).round();
      }

      // Handle CombatStatsHolder (Goblin, Bat, Skeleton)
      if (stats is CombatStatsHolder) {
        final combatStats = stats.combatStats;
        combatStats.maxHp.value =
            (combatStats.maxHp.value * scaleFactor).round();
        combatStats.currentHp.value = combatStats.maxHp.value;
        combatStats.attack.value =
            (combatStats.attack.value * scaleFactor).round();
      }
    }
  }

  /// Remove defeated enemy from the battle
  void _removeDefeatedEnemy(int index) {
    if (index >= 0 && index < currentEnemies.length) {
      final enemyToRemove = currentEnemies[index];
      final enemyName = getEnemyName(enemyToRemove);
      print('ðŸ—‘ï¸ Removiendo $enemyName derrotado');

      // Remove visual component first
      game._battleScene?.removeEnemy(index);

      // Then remove from data list
      currentEnemies.removeAt(index);

      // (Note: enemyNames entry persists, which is fine)

      // NEW: Remove from Turn Queue
      final queueIndex = turnQueue.indexWhere((e) => e.enemy == enemyToRemove);
      if (queueIndex != -1) {
        turnQueue.removeAt(queueIndex);
        // If we removed an entity before the current index, decrement index
        // to stay in sync.
        if (queueIndex < currentTurnIndex) {
          currentTurnIndex--;
        }
      }

      // Adjust selected target if needed
      if (selectedTargetIndex >= currentEnemies.length &&
          currentEnemies.isNotEmpty) {
        selectedTargetIndex = currentEnemies.length - 1;
      } else if (currentEnemies.isEmpty) {
        selectedTargetIndex = 0;
      }

      // Update currentEnemy for UI compatibility
      if (currentEnemies.isNotEmpty) {
        currentEnemy = currentEnemies[selectedTargetIndex];
      } else {
        currentEnemy = null;
      }
    }
  }

  /// Cycle to next enemy target (Tab/E)
  void cycleTargetNext() {
    if (currentEnemies.isEmpty) return;

    selectedTargetIndex = (selectedTargetIndex + 1) % currentEnemies.length;
    final targetName = getEnemyName(currentEnemies[selectedTargetIndex]);
    print('ðŸŽ¯ Target switched to $targetName');

    final temp = currentTurn.value;
    currentTurn.value = temp;
  }

  /// Cycle to previous enemy target (Q)
  void cycleTargetPrevious() {
    if (currentEnemies.isEmpty) return;

    selectedTargetIndex = (selectedTargetIndex - 1 + currentEnemies.length) %
        currentEnemies.length;
    final targetName = getEnemyName(currentEnemies[selectedTargetIndex]);
    print('ðŸŽ¯ Target switched to $targetName');

    final temp = currentTurn.value;
    currentTurn.value = temp;
  }

  /// Single enemy takes their turn
  void _enemyTakeTurn(SpriteAnimationComponent enemy, int index) {
    final stats = (enemy as dynamic).stats;
    final enemyType = _getEnemyTypeForComponent(enemy);
    final enemyName = getEnemyName(enemy);

    // Check if enemy is already dead
    final currentHp = (stats is CombatStatsHolder)
        ? stats.combatStats.currentHp.value
        : (stats is EnemyStats ? stats.currentHp.value : 0);

    if (currentHp <= 0) {
      print('💀 Enemy $enemyName is dead, skipping turn.');

      // Check if ALL enemies are dead
      final allDead = currentEnemies.every((e) {
        final s = (e as dynamic).stats;
        final hp = (s is CombatStatsHolder)
            ? s.combatStats.currentHp.value
            : (s is EnemyStats ? s.currentHp.value : 0);
        return hp <= 0;
      });

      if (allDead) {
        print('🎉 All enemies dead (detected in turn loop). Ending combat.');
        return;
      }

      // Skip to next turn
      Future.delayed(const Duration(milliseconds: 500), () {
        nextTurn();
      });
      return;
    }

    // Check if enemy has CombatStats
    final hasCombatStats = stats is CombatStatsHolder;

    if (!hasCombatStats) {
      // Simple attack for enemies without CombatStats
      print('🤖 $enemyName usa ataque simple');
      final rawDamage = stats.attack;
      final playerDef = game.player.stats.defense.value;
      final estimatedNet = (rawDamage - playerDef).clamp(1, 999);

      game.player.stats.takeDamage(rawDamage);
      print(
          '💥 $enemyName hizo $estimatedNet de daño! (Bruto: $rawDamage - Def: $playerDef)');

      // Proceed to next turn
      Future.delayed(const Duration(seconds: 1), () {
        nextTurn();
      });
      return;
    }
    final combatStats = (stats as CombatStatsHolder).combatStats;
    final abilities = AbilityDatabase.getEnemyAbilities(enemyType);

    if (abilities.isEmpty) {
      // Fallback to simple attack
      print('ðŸ¤– $enemyName usa ataque simple (sin habilidades)');
      game.player.stats.takeDamage(combatStats.attack.value);
      return;
    }

    // Use AI to choose ability
    final chosenAbility = EnemyAI.chooseAbility(
      abilities: abilities,
      stats: combatStats,
    );

    print('ðŸ¤– $enemyName usa: ${chosenAbility.name}');

    // Consume resources
    if (chosenAbility.type == AbilityType.ultimate) {
      combatStats.spendUlt();
    } else if (chosenAbility.mpCost > 0) {
      combatStats.spendMp(chosenAbility.mpCost);
    }

    // NEW: Apply status effects from ability
    // Special handling for Guard ability (const limitations workaround)
    if (chosenAbility.name == 'Guardia') {
      combatStats.applyEffect(StatusEffect.defenseBuffStrong());
      print('ðŸ›¡ï¸ $enemyName aplicÃ³ Guardia (+50% DEF por 3 turnos)');
    } else if (chosenAbility.effect.statusEffects.isNotEmpty) {
      for (final effect in chosenAbility.effect.statusEffects) {
        if (chosenAbility.effect.targetType == TargetType.self) {
          // Apply to self
          combatStats.applyEffect(effect);
          print('âœ¨ $enemyName aplicÃ³ ${effect.name} a sÃ­ mismo');
        } else {
          // Apply to player (debuffs)
          game.player.stats.combatStats.applyEffect(effect);
          print('âš ï¸ $enemyName aplicÃ³ ${effect.name} al jugador');
        }
      }
    }

    // Check if ability is offensive (attacks player) or defensive (buffs self)
    final isOffensive = chosenAbility.effect.targetType != TargetType.self &&
        chosenAbility.effect.baseDamage > 0;

    if (isOffensive) {
      // Calculate and apply damage
      // NOTA: Pasamos 0 como defensa aquÃ­ para obtener el daÃ±o BRUTO.
      // La defensa se restarÃ¡ dentro de takeDamage().
      // Use effectiveAttack to include enemy buffs
      final grossDamage = DamageCalculator.calculateDamage(
        ability: chosenAbility,
        attackerAtk: combatStats.effectiveAttack, // Uses buffed attack
        defenderDef: 0, // 0 aquÃ­ porque takeDamage restarÃ¡ la defensa
        critChance: combatStats.critChance.value,
      );

      final playerDef = game.player.stats.combatStats.effectiveDefense;
      final estimatedNetDamage = (grossDamage - playerDef).clamp(1, 999);

      game.player.stats.takeDamage(grossDamage);
      print(
          'ðŸ’¥ $enemyName hizo $estimatedNetDamage de daÃ±o! (Bruto: $grossDamage - Def: $playerDef)');
    } else {
      // Defensive/buff ability
      print('ðŸ›¡ï¸ $enemyName usa una habilidad defensiva (sin daÃ±o)');
      // TODO: Apply defense buff when status effect system is implemented
    }

    // Proceed to next turn after delay
    Future.delayed(const Duration(seconds: 1), () {
      nextTurn();
    });
  }
}

class RenegadeDungeonGame extends FlameGame
    with
        HasKeyboardHandlerComponents,
        HasCollisionDetection,
        WidgetsBindingObserver {
  late final RouterComponent router;
  VideoPlayerController? videoPlayerController;
  GameState state = GameState.exploring;
  // Propiedades globales que GameScreen necesitarÃ¡
  late final CombatManager combatManager;
  late TiledComponent mapComponent;
  late Player player;
  bool isPlayerReady = false;
  final ValueNotifier<bool> isPlayerReadyNotifier = ValueNotifier<bool>(false);
  double accumulatedPlaytime = 0;
  DateTime? sessionCreatedAt;
  late TileLayer collisionLayer;

  final double tileWidth = 32.0;
  final double tileHeight = 16.0;
  final double cameraZoom = 2.0;

  bool zoneHasEnemies = false;
  List<String> zoneEnemyTypes = [];
  List<double> zoneEnemyChances = [];
  BattleScene? _battleScene;

  // ========== PORTAL & ZONE SYSTEM ==========
  final Map<String, PortalData> portals = {};
  String currentMapName = 'cemetery.tmx';
  static const int MIN_STEPS_BETWEEN_BATTLES = 10;
  int stepsSinceLastBattle = 0;
  final List<Rect> spawnZoneRects = [];
  final Map<int, ZoneProperties> zonePropertiesMap = {};
  ZoneProperties? currentZone;
  final Set<String> discoveredZones = {};
  // NEW: Conditional Barriers System
  final List<ConditionalBarrier> conditionalBarriers = [];
  // Track opened chests to prevent regeneration
  final Set<String> openedChests = {};
  final List<BossTriggerData> bossTriggers = [];

  // ========== NPC SYSTEM ==========
  final Map<String, NPC> npcs = {};
  List<NPCComponent> npcComponents = [];
  String? activeDialogueNPC;

  late final IAPService iapService;

  // Fog of War System
  final Set<math.Point<int>> exploredTiles = {};
  // HUD Notifiers
  final ValueNotifier<String> currentZoneNameNotifier =
      ValueNotifier<String>('Unknown Zone');
  final ValueNotifier<int> currentDangerLevelNotifier = ValueNotifier<int>(1);
  static const int explorationRadius = 5;

  final videoPlayerControllerNotifier =
      ValueNotifier<VideoPlayerController?>(null);
  final currentBackgroundNotifier =
      ValueNotifier<String?>(null); // NEW: For static fallback

  // Save System
  int currentSlotIndex = 1;
  bool isNewGameFlag = true; // Track if current game is new or loaded
  int introNavigationCount = 0; // Force IntroScreen recreation
  final OfflineStorageService offlineStorage;
  final AuthService authService;

  RenegadeDungeonGame({
    required this.offlineStorage,
    required this.authService,
  });

  @override
  Color backgroundColor() => const Color(0x00000000); // Transparent

  @override
  Future<void> onLoad() async {
    // Allow game to run in background (experimental, OS may still throttle)
    pauseWhenBackgrounded = false;

    super.onLoad();
    WidgetsBinding.instance.addObserver(this);

    @override
    void onRemove() {
      WidgetsBinding.instance.removeObserver(this);
      stopMusic();
      super.onRemove();
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.detached ||
          state == AppLifecycleState.inactive) {
        if (isPlayerReady) {
          print('📱 App going to background/inactive. Auto-saving...');
          saveGame();
        }
      }
    }

    await FlameAudio.audioCache.loadAll([
      'menu_music.ogg',
      'dungeon_music.ogg',
    ]);
    //playMenuMusic();
    // 1. Inicializa sistemas globales.
    iapService = IAPService(onGemsPurchased: (amount) {
      player.stats.gems.value += amount;
      print('💎 Added $amount gems. Total: ${player.stats.gems.value}');
      // Save game after purchase
      saveGame();
    });

    try {
      await iapService.initialize();
    } catch (e) {
      print('⚠️ Failed to initialize IAP (continuing anyway): $e');
    }

    combatManager = CombatManager(this);

    // 2. Carga el router. Su única tarea es decidir qué pantalla mostrar.
    add(
      router = RouterComponent(
        initialRoute: 'splash-screen',
        routes: {
          'splash-screen': Route(SplashScreen.new),
          'main-menu': Route(
              () => MenuRouteComponent('MainMenu', 'menu_background.mp4')),
          // 'slot-selection-menu': Route(() =>
          //     MenuRouteComponent('SlotSelectionMenu', 'slot_background.mp4')),
          'intro-screen': Route(IntroRouteComponent.new),
          'loading-screen': Route(LoadingRouteComponent.new),
          'game-screen': Route(GameScreen.new),
        },
      ),
    );

    // Reproduce la música del menú
    playMenuMusic();
  }

  Future<void> playMenuMusic() async {
    try {
      if (!FlameAudio.bgm.isPlaying) {
        FlameAudio.bgm.stop();
        await FlameAudio.bgm.play('menu_music.ogg');
      }
    } catch (e) {
      print('⚠️ Error playing menu music: $e');
    }
  }

  Future<void> playWorldMusic() async {
    try {
      FlameAudio.bgm.stop();
      await FlameAudio.bgm.play('dungeon_music.ogg');
    } catch (e) {
      print('⚠️ Error playing world music: $e');
    }
  }

  void stopMusic() {
    try {
      FlameAudio.bgm.stop();
    } catch (e) {
      print('⚠️ Error stopping music: $e');
    }
  }

  Future<bool> loadGameData() async {
    // 0. Clear previous session state to prevent leakage
    _clearSessionState();

    // 1. Check for save data FIRST to know which map to load
    final saveData = offlineStorage.loadLocally(currentSlotIndex);

    String mapToLoad = 'cemetery.tmx'; // Default for new game
    if (saveData != null) {
      mapToLoad = saveData.currentMap;
    }

    // 2. Load the determined map
    try {
      // Remove existing map if any
      try {
        if (world.contains(mapComponent)) {
          world.remove(mapComponent);
        }
      } catch (e) {
        // mapComponent not initialized yet, nothing to remove
      }

      print('🗺️ Attempting to load map: $mapToLoad');
      mapComponent =
          await TiledComponent.load(mapToLoad, Vector2(tileWidth, tileHeight));
      currentMapName = mapToLoad;

      print('✅ Map loaded: $mapToLoad');
      print(
          '   Layers found: ${mapComponent.tileMap.renderableLayers.map((l) => l.layer.name).join(', ')}');
    } catch (e, stack) {
      print('⚠️ Could not load $mapToLoad, falling back to dungeon.tmx');
      print('Error details: $e');
      print('Stack trace: $stack');
      mapComponent = await TiledComponent.load(
          'dungeon.tmx', Vector2(tileWidth, tileHeight));
      currentMapName = 'dungeon.tmx';
    }

    loadZoneData();
    collisionLayer = mapComponent.tileMap.getLayer<TileLayer>('Collision')!;
    collisionLayer.visible = false;

    // Load static map elements
    _loadPortals();
    _loadSpawnZones();
    _loadConditionalBarriers();
    _loadBossTriggers();
    await _loadChests();
    _loadNPCs();

    if (saveData != null) {
      print('💾 Loading save from Slot $currentSlotIndex...');
      player = Player(
        gridPosition: Vector2(saveData.gridX, saveData.gridY),
      );

      accumulatedPlaytime = saveData.playtimeSeconds.toDouble();
      sessionCreatedAt = saveData.createdAt;

      // Restore Stats
      player.stats.level.value = saveData.level;
      player.stats.currentXp.value = saveData.experience;
      player.stats.currentHp.value = saveData.currentHp;
      player.stats.maxHp.value = saveData.maxHp;
      player.stats.currentMp.value = saveData.currentMp;
      player.stats.maxMp.value = saveData.maxMp;
      player.stats.attack.value = saveData.attack;
      player.stats.defense.value = saveData.defense;
      player.stats.gold.value = saveData.gold;
      player.stats.gems.value = saveData.gems;

      // Restore progression
      discoveredZones.addAll(saveData.discoveredMaps);
      openedChests.addAll(saveData.openedChests);
      player.stats.defeatedBosses.addAll(saveData.defeatedBosses);

      // Restore Inventory
      final loadedInventory = <InventorySlot>[];
      for (final slotData in saveData.inventory) {
        final item = ItemDatabase.getItemById(slotData.itemId);
        if (item != null) {
          loadedInventory
              .add(InventorySlot(item: item, quantity: slotData.quantity));
        }
      }
      player.inventory.value = loadedInventory;

      // Restore Equipment
      final loadedEquipment = <EquipmentSlot, EquipmentItem>{};
      saveData.equipment.forEach((slotName, itemId) {
        if (itemId != null) {
          final item = ItemDatabase.getItemById(itemId);
          if (item is EquipmentItem) {
            final slot = EquipmentSlot.values
                .firstWhere((e) => e.name == slotName, orElse: () => item.slot);
            loadedEquipment[slot] = item;
          }
        }
      });
      player.stats.loadEquipment(loadedEquipment);

      isPlayerReady = true;
      isPlayerReadyNotifier.value = true;
      checkZoneTransition(player.position);
      return false; // Not a new game
    } else {
      print(
          '🆕 No save found for Slot $currentSlotIndex. Starting new game in Cemetery.');

      // Find PlayerStart object
      Vector2 startPos = Vector2(40.0, 42.0); // Fallback

      // Try 'Setup' layer first
      final objectLayer = mapComponent.tileMap.getLayer<ObjectGroup>('Setup');
      if (objectLayer != null) {
        final startObj = objectLayer.objects.firstWhere(
          (obj) => obj.name == 'PlayerStart',
          orElse: () => TiledObject(id: -1),
        );

        if (startObj.id != -1) {
          // Use screenToGridPosition for correct isometric conversion
          startPos = screenToGridPosition(Vector2(startObj.x, startObj.y));
          print(
              '📍 Found PlayerStart at $startPos (converted from ${startObj.x}, ${startObj.y})');
        }
      }

      // Try 'Objects' layer as fallback if not found in Setup
      if (startPos == Vector2(40.0, 42.0)) {
        // Check against fallback
        final altLayer = mapComponent.tileMap.getLayer<ObjectGroup>('Objects');
        if (altLayer != null) {
          final startObj = altLayer.objects.firstWhere(
            (obj) => obj.name == 'PlayerStart',
            orElse: () => TiledObject(id: -1),
          );
          if (startObj.id != -1) {
            startPos = screenToGridPosition(Vector2(startObj.x, startObj.y));
            print('📍 Found PlayerStart at $startPos (in Objects layer)');
          }
        }
      }

      print(
          '🚀 Spawning player at Grid: $startPos (Pixels: ${startPos.x * tileWidth}, ${startPos.y * tileHeight})');
      player = Player(gridPosition: startPos);
      print(
          '🆕 New Player created. Level: ${player.stats.level.value}, XP: ${player.stats.currentXp.value}');

      // Add default items for new game ONLY
      player.addItem(ItemDatabase.rustySword);
      player.addItem(ItemDatabase.leatherTunic);

      final data = PlayerSaveData(
        level: player.stats.level.value,
        currentHp: player.stats.currentHp.value,
        maxHp: player.stats.maxHp.value,
        currentMp: player.stats.currentMp.value,
        maxMp: player.stats.maxMp.value,
        experience: player.stats.currentXp.value,
        attack: player.stats.attack.value,
        defense: player.stats.defense.value,
        inventory: player.inventory.value
            .map((slot) => InventorySlotData.fromSlot(slot))
            .toList(),
        equipment: player.stats.equippedItems.value.map(
          (slot, item) => MapEntry(slot.name, item.id),
        ),
        currentMap: currentMapName,
        gridX: player.gridPosition.x,
        gridY: player.gridPosition.y,
        gold: player.stats.gold.value,
        gems: player.stats.gems.value,
        discoveredMaps: discoveredZones.toList(),
        openedChests: openedChests.toList(),
        defeatedBosses: player.stats.defeatedBosses.toList(),
        activeQuests: [],
        completedQuests: [],
        lastSaved: DateTime.now(),
        createdAt: sessionCreatedAt ?? DateTime.now(),
        playtimeSeconds: accumulatedPlaytime.toInt(),
      );

      try {
        await offlineStorage.saveLocally(currentSlotIndex, data);
        print('💾 Game saved to Slot $currentSlotIndex');

        // Show visual feedback
        overlays.add('barrier_dialog');
        _currentBarrierMessage = 'Partida Guardada';
        _currentBarrierIsBlocked = false; // Green text

        // Hide feedback after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (_currentBarrierMessage == 'Partida Guardada') {
            overlays.remove('barrier_dialog');
          }
        });
      } catch (e) {
        print('❌ Error saving game: $e');
      }

      // Fix: Ensure player is marked as ready for new game
      isPlayerReady = true;
      isPlayerReadyNotifier.value = true;

      return true;
    }
  }

  Future<void> saveGame() async {
    if (!isPlayerReady) return;

    print('💾 Attempting to save game...');
    print('   Current Slot Index: $currentSlotIndex');
    print('   Player Level: ${player.stats.level.value}');
    print('   Player XP: ${player.stats.currentXp.value}');

    if (currentSlotIndex < 1 || currentSlotIndex > 3) {
      print('❌ ERROR: Invalid slot index $currentSlotIndex! Aborting save.');
      return;
    }

    final data = PlayerSaveData(
      level: player.stats.level.value,
      currentHp: player.stats.currentHp.value,
      maxHp: player.stats.maxHp.value,
      currentMp: player.stats.currentMp.value,
      maxMp: player.stats.maxMp.value,
      experience: player.stats.currentXp.value,
      attack: player.stats.attack.value,
      defense: player.stats.defense.value,
      inventory: player.inventory.value
          .map((slot) => InventorySlotData.fromSlot(slot))
          .toList(),
      equipment: player.stats.equippedItems.value.map(
        (slot, item) => MapEntry(slot.name, item.id),
      ),
      currentMap: currentMapName,
      gridX: player.gridPosition.x,
      gridY: player.gridPosition.y,
      gold: player.stats.gold.value,
      gems: player.stats.gems.value,
      discoveredMaps: discoveredZones.toList(),
      openedChests: openedChests.toList(),
      defeatedBosses: player.stats.defeatedBosses.toList(),
      activeQuests: [],
      completedQuests: [],
      lastSaved: DateTime.now(),
      createdAt: sessionCreatedAt ?? DateTime.now(),
      playtimeSeconds: accumulatedPlaytime.toInt(),
    );

    try {
      print('💾 Calling offlineStorage.saveLocally($currentSlotIndex)...');
      await offlineStorage.saveLocally(currentSlotIndex, data);
      print('💾 Game saved to Slot $currentSlotIndex');
    } catch (e) {
      print('❌ Error saving game: $e');
    }
  }

  void startCombat(String enemyType) async {
    state = GameState.inCombat;
    player.showSurpriseEmote();
    camera.viewfinder.add(
      ScaleEffect.to(
        Vector2.all(2),
        EffectController(duration: 0.4, curve: Curves.easeIn),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1000));
    final screenFade = ScreenFade();
    camera.viewport.add(screenFade);
    await screenFade.fadeOut();
    world.removeFromParent();
    camera.viewfinder.zoom = 1.5;

    // ALWAYS use multi-enemy system (single enemy = list of 1)
    combatManager.startNewCombatMulti([enemyType]);

    // Create BattleScene with the enemies
    _battleScene = BattleScene(enemies: combatManager.currentEnemies);

    await add(_battleScene!);
    overlays.add('CombatUI');
    await screenFade.fadeIn();
  }

  /// Start multi-enemy combat (for testing or zone spawning)
  void startCombatMulti(List<String> enemyTypes) async {
    state = GameState.inCombat;
    player.showSurpriseEmote();
    camera.viewfinder.add(
      ScaleEffect.to(
        Vector2.all(2),
        EffectController(duration: 0.4, curve: Curves.easeIn),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1000));
    final screenFade = ScreenFade();
    camera.viewport.add(screenFade);
    await screenFade.fadeOut();
    world.removeFromParent();
    camera.viewfinder.zoom = 1.5;
    combatManager.startNewCombatMulti(enemyTypes);
    _battleScene = BattleScene(enemies: combatManager.currentEnemies);
    await add(_battleScene!);
    overlays.add('CombatUI');
    await screenFade.fadeIn();
  }

  /// Start boss combat with specific boss ID
  void startBossBattle(String bossId, String enemyType) async {
    state = GameState.inCombat;
    player.showSurpriseEmote();
    camera.viewfinder.add(
      ScaleEffect.to(
        Vector2.all(2),
        EffectController(duration: 0.4, curve: Curves.easeIn),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1000));
    final screenFade = ScreenFade();
    camera.viewport.add(screenFade);
    await screenFade.fadeOut();
    world.removeFromParent();
    camera.viewfinder.zoom = 1.5;

    // Use startBossCombat to initialize manager AND set boss ID
    combatManager.startBossCombat(bossId, enemyType);

    _battleScene = BattleScene(enemies: combatManager.currentEnemies);
    await add(_battleScene!);
    overlays.add('CombatUI');
    await screenFade.fadeIn();
  }

  void endCombat() {
    final playerDied = player.stats.currentHp.value <= 0;

    if (playerDied) {
      print('💀 ¡Has muerto! Reapareciendo en punto seguro...');
      player.stats.currentHp.value = player.stats.maxHp.value;
      player.stats.currentMp.value = player.stats.maxMp.value;

      // CRÍTICO: Sincronizar con combatStats para que la UI lo vea
      player.stats.combatStats.currentHp.value = player.stats.currentHp.value;
      player.stats.combatStats.currentMp.value = player.stats.currentMp.value;

      // Respawn near a portal if possible (e.g. entrance), otherwise default
      if (portals.isNotEmpty) {
        // Try to find a portal that is NOT the one leading to the next area (if any)
        // For now, just pick the first one, which is usually the entrance in simple maps
        final portal = portals.values.first;
        // Spawn slightly offset from portal to avoid instant transition
        player.gridPosition = portal.gridPosition + Vector2(5, 0);
        print('📍 Respawning near portal: ${portal.gridPosition}');
      } else {
        player.gridPosition = Vector2(5.0, 5.0);
      }
      player.position = gridToScreenPosition(player.gridPosition);

      // Show respawn message briefly
      Future.delayed(const Duration(milliseconds: 500), () {
        print('✨ Has reaparecido con salud completa');
      });

      // Cleanup and return EARLY so we don't mark boss as defeated
      if (combatManager.currentEnemy != null) {
        combatManager.currentEnemy = null;
      }
      overlays.remove('CombatUI');
      if (_battleScene != null) {
        remove(_battleScene!);
        _battleScene = null;
      }
      add(world);
      state = GameState.exploring;
      return;
    }

    // If we are here, player WON
    if (combatManager.currentBossId != null) {
      player.stats.defeatBoss(combatManager.currentBossId!);
      print('✅ Boss ${combatManager.currentBossId} defeated and marked!');
      saveGame();
    }
    if (combatManager.currentEnemy != null) {
      combatManager.currentEnemy = null;
    }
    overlays.remove('CombatUI');
    if (_battleScene != null) {
      remove(_battleScene!);
      _battleScene = null;
    }
    add(world);
    state = GameState.exploring;
  }

  Vector2 gridToScreenPosition(Vector2 gridPos) {
    final mapHeightInTiles = mapComponent.tileMap.map.height;
    final originX = mapHeightInTiles * (tileWidth / 2);
    final screenX = (gridPos.x - gridPos.y) * (tileWidth / 2);
    final screenY = (gridPos.x + gridPos.y) * (tileHeight / 2);
    return Vector2(
      screenX + originX,
      screenY + (tileHeight / 2),
    );
  }

  void loadZoneData() {
    final mapProperties = mapComponent.tileMap.map.properties;
    zoneHasEnemies = mapProperties.getValue<bool>('hasEnemies') ?? false;
    if (zoneHasEnemies) {
      final typesString = mapProperties.getValue<String>('enemyTypes') ?? '';
      final chancesString =
          mapProperties.getValue<String>('enemyChances') ?? '';
      zoneEnemyTypes = typesString.split(',');
      zoneEnemyChances = chancesString
          .split(',')
          .map((e) => double.tryParse(e) ?? 0.0)
          .toList();
    }
  }

  void togglePauseMenu() {
    if (state == GameState.inMenu) {
      // Sin 'this.'
      state = GameState.exploring; // Sin 'this.'
      overlays.remove('PauseMenuUI');
    } else if (state == GameState.exploring) {
      // Sin 'this.'
      state = GameState.inMenu; // Sin 'this.'
      overlays.add('PauseMenuUI');
    }
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      // Pause menu toggle
      if (keysPressed.contains(LogicalKeyboardKey.keyM)) {
        togglePauseMenu();
        return KeyEventResult.handled;
      }

      // Target cycling in combat (only in multi-enemy mode)
      if (state == GameState.inCombat &&
          combatManager.currentEnemies.length > 1) {
        if (keysPressed.contains(LogicalKeyboardKey.tab) ||
            keysPressed.contains(LogicalKeyboardKey.keyE)) {
          combatManager.cycleTargetNext();
          return KeyEventResult.handled;
        }

        if (keysPressed.contains(LogicalKeyboardKey.keyQ)) {
          combatManager.cycleTargetPrevious();
          return KeyEventResult.handled;
        }
      }
    }

    // Block movement and other inputs during combat
    if (state == GameState.inCombat) {
      return KeyEventResult.handled;
    }

    // Â¡OJO! AsegÃºrate de que esta lÃ­nea estÃ© presente.
    // Llama al mÃ©todo original para que otras teclas (como el movimiento) sigan funcionando.
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Ensure PlayerHud is always on top if game is running
    if (state == GameState.exploring || state == GameState.inCombat) {
      if (!overlays.isActive('PlayerHud')) {
        overlays.add('PlayerHud');
      }
    }

    // Track playtime
    if (state == GameState.exploring || state == GameState.inCombat) {
      accumulatedPlaytime += dt;
    }

    if (!isPlayerReady) return;

    if (state == GameState.exploring) {
      // Update Fog of War
      if (player.isMounted) {
        updateExploration(player.position);
        checkZoneTransition(player.position);
        checkRandomEncounter();
        checkBossTriggerCollision(player.gridPosition);

        // DEBUG: Print status every ~1 second
        if (DateTime.now().millisecondsSinceEpoch % 2000 < 20) {
          print(
              '🔍 DEBUG: Map=$currentMapName, BossTriggers=${bossTriggers.length}, Player=${player.gridPosition}');
        }
      }
    }
  }

  // ========== PORTAL SYSTEM ==========

  void _loadPortals() {
    portals.clear();
    final portalsLayer = mapComponent.tileMap.getLayer<ObjectGroup>('Portals');
    if (portalsLayer == null) {
      print('âš ï¸ No Portals layer found');
      return;
    }

    // Same scale factor as conditional barriers and spawn zones
    const double scaleFactor = 2.0;

    for (final obj in portalsLayer.objects) {
      // Tiled object positions - convert directly to grid without scaleFactor
      final gridX = (obj.x / 16.0).floor(); // Tiled uses 16x16 base tiles
      final gridY = (obj.y / 16.0).floor();

      print(
          'ℹ️ Portal ${obj.name}: Raw(${obj.x}, ${obj.y}) -> Grid($gridX, $gridY)');

      // Extract zone size from Tiled object dimensions (convert pixels -> grid units)
      final zoneWidthGrid = ((obj.width * scaleFactor) / tileWidth).ceil();
      final zoneHeightGrid = ((obj.height * scaleFactor) / tileHeight).ceil();
      final zoneSize = Vector2(
        zoneWidthGrid.toDouble().clamp(1.0, 100.0),
        zoneHeightGrid.toDouble().clamp(1.0, 100.0),
      );

      // Read transition properties (with defaults)
      final transitionType =
          obj.properties.getValue<String>('transitionType') ?? 'fade';
      final transitionDuration =
          obj.properties.getValue<int>('transitionDuration') ?? 2000;

      final targetMap = obj.properties.getValue<String>('targetMap');
      final targetX = obj.properties.getValue<int>('targetX') ?? 10;
      final targetY = obj.properties.getValue<int>('targetY') ?? 10;

      if (targetMap != null) {
        final gridPos = Vector2(gridX.toDouble(), gridY.toDouble());
        portals[obj.name] = PortalData(
          gridPosition: gridPos,
          size: zoneSize,
          targetMap: targetMap,
          targetPosition: Vector2(targetX.toDouble(), targetY.toDouble()),
          transitionType: transitionType,
          transitionDuration: transitionDuration,
        );

        // Add visual indicator for portal (centered on zone)
        final zoneCenterGrid = gridPos + (zoneSize / 2);
        final visualPos = gridToScreenPosition(zoneCenterGrid);

        // Check if visual already exists to avoid duplicates
        bool visualExists = world.children
            .whereType<PortalVisual>()
            .any((v) => v.position.distanceTo(visualPos) < 1.0);

        if (!visualExists) {
          final portalVisual = PortalVisual(position: visualPos);
          world.add(portalVisual);
        }

        print(
            'âœ… Loaded portal ${obj.name} at $gridPos (${zoneSize.x.toInt()}x${zoneSize.y.toInt()}) -> $targetMap ($targetX, $targetY) [$transitionType, ${transitionDuration}ms]');
      } else {
        print('âš ï¸ Portal ${obj.name} missing "targetMap" property');
      }
    }

    print('âœ… Loaded ${portals.length} portals');
  }

  void checkPortalCollision(Vector2 playerGridPos) {
    print(
        '🔍 Checking portal collision at $playerGridPos'); // Uncomment for verbose debug
    for (final portal in portals.values) {
      print(
          '  - Checking against portal at ${portal.gridPosition} size ${portal.size}');

      // Use zone-based detection instead of exact point match

      if (portal.contains(playerGridPos)) {
        transitionToMap(
          portal.targetMap,
          portal.targetPosition,
          transitionType: portal.transitionType,
          duration: portal.transitionDuration,
        );
        break;
      }
    }
  }

  Future<void> transitionToMap(
    String mapName,
    Vector2 startPos, {
    String transitionType = 'fade',
    int duration = 2000,
  }) async {
    print(
        'ðŸšª Transitioning to $mapName using [$transitionType] transition...');

    // Remove HUD during transition
    overlays.remove('PlayerHud');

    // Handle different transition types
    if (transitionType == 'fade') {
      // Create and add fade effect
      final screenFade = ScreenFade();
      camera.viewport.add(screenFade);

      // Fade out (duration in seconds)
      final fadeOutDuration = (duration / 2) / 1000;
      await screenFade.fadeOut(duration: fadeOutDuration);

      try {
        // Perform map transition while screen is black
        await _performMapTransition(mapName, startPos);

        // Fade in
        await screenFade.fadeIn(duration: fadeOutDuration);
      } catch (e, stackTrace) {
        print('â Œ Error during fade transition: $e');
        print(stackTrace);
        // Remove fade on error
        screenFade.removeFromParent();
      }
    } else if (transitionType == 'instant') {
      // Instant transition (no visual effect)
      try {
        await _performMapTransition(mapName, startPos);
      } catch (e) {
        print('❌ Error during instant transition: $e');
      }
    } else {
      // Default to fade for unknown types
      print('âš ï¸  Unknown transition type "$transitionType", using fade');
      return transitionToMap(mapName, startPos,
          transitionType: 'fade', duration: duration);
    }

    // Restore HUD after transition
    overlays.add('PlayerHud');

    // Auto-save after successful transition
    saveGame();
    print('💾 Game saved after portal transition');
  }

  /// Internal method to perform the actual map loading
  Future<void> _performMapTransition(String mapName, Vector2 startPos) async {
    try {
      // CRITICAL: Remove old map components FIRST before loading new map
      if (mapComponent.parent != null) {
        mapComponent.removeFromParent();
      }

      // Remove all chests and portal visuals from the previous map
      final chests = world.children.whereType<Chest>().toList();
      for (final chest in chests) {
        chest.removeFromParent();
      }
      final portalVisuals = world.children.whereType<PortalVisual>().toList();
      for (final visual in portalVisuals) {
        visual.removeFromParent();
      }

      // Load new map
      mapComponent =
          await TiledComponent.load(mapName, Vector2(tileWidth, tileHeight));
      collisionLayer = mapComponent.tileMap.getLayer<TileLayer>('Collision')!;
      collisionLayer.visible = false;
      await world.add(mapComponent);

      currentMapName = mapName;
      _loadPortals();
      _loadSpawnZones();
      _loadConditionalBarriers();
      _loadBossTriggers();
      await _loadChests();

      player.gridPosition = startPos;
      player.position = gridToScreenPosition(startPos);

      stepsSinceLastBattle = 0;

      // Clear Fog of War for new map
      exploredTiles.clear();
      // Re-explore around player
      updateExploration(player.gridPosition);

      print('✅ Loaded $mapName');
    } catch (e, stackTrace) {
      print('❌ Error loading map $mapName: $e');
      print(stackTrace);
      rethrow; // Propagate error to caller
    }
  }

  // ========== ZONE SYSTEM ==========

  void _loadSpawnZones() {
    spawnZoneRects.clear();
    zonePropertiesMap.clear();
    currentZone = null;

    final zonesLayer = mapComponent.tileMap.getLayer<ObjectGroup>('SpawnZones');
    if (zonesLayer == null) {
      print('âš ï¸ No SpawnZones layer found');
      return;
    }

    // Scale factor for isometric projection (Tiled vs Game)
    // Tiled seems to export isometric object coordinates based on tileHeight (16)
    // while our game logic uses tileWidth (32) for grid conversion.
    // Empirical evidence suggests a 2.0 scale factor is needed.
    const double scaleFactor = 2.0;

    for (int i = 0; i < zonesLayer.objects.length; i++) {
      final obj = zonesLayer.objects[i];

      // Scale the rect to match game coordinates
      final rect = Rect.fromLTWH(
        obj.x * scaleFactor,
        obj.y * scaleFactor,
        obj.width * scaleFactor,
        obj.height * scaleFactor,
      );
      spawnZoneRects.add(rect);

      final enemyTypesStr = obj.properties.getValue<String>('enemyTypes') ?? '';
      final enemyTypes = enemyTypesStr.isEmpty
          ? <String>[]
          : enemyTypesStr.split(',').map((e) => e.trim()).toList();

      final props = ZoneProperties(
        name: obj.properties.getValue<String>('name') ?? 'Unknown Zone',
        enemyTypes: enemyTypes,
        encounterChance:
            obj.properties.getValue<double>('encounterChance') ?? 0.02,
        minLevel: obj.properties.getValue<int>('minLevel') ?? 1,
        maxLevel: obj.properties.getValue<int>('maxLevel') ?? 99,
        maxRarity: _parseRarity(obj.properties.getValue<String>('maxRarity')),
        dangerLevel:
            _parseDangerLevel(obj.properties.getValue<String>('dangerLevel')),
      );

      zonePropertiesMap[i] = props;
    }

    print('âœ… Loaded ${spawnZoneRects.length} spawn zones');
  }

  /// Load conditional barriers from Tiled map
  void _loadConditionalBarriers() {
    conditionalBarriers.clear();

    final barriersLayer =
        mapComponent.tileMap.getLayer<ObjectGroup>('ConditionalBarriers');
    if (barriersLayer == null) {
      print('â„¹ï¸ No ConditionalBarriers layer found (this is optional)');
      return;
    }

    // Same scale factor as spawn zones
    const double scaleFactor = 2.0;

    for (final obj in barriersLayer.objects) {
      try {
        final barrier = ConditionalBarrier(
          id: obj.properties.getValue<String>('id') ?? 'barrier_${obj.id}',
          position: Vector2(obj.x * scaleFactor, obj.y * scaleFactor),
          size: Vector2(obj.width * scaleFactor, obj.height * scaleFactor),
          requiredLevel: obj.properties.getValue<int>('requiredLevel') ?? 0,
          requiredBoss:
              obj.properties.getValue<String>('requiredBoss') ?? 'none',
          requiredQuest:
              obj.properties.getValue<String>('requiredQuest') ?? 'none',
          blockedMessage: obj.properties.getValue<String>('blockedMessage') ??
              'No puedes pasar aÃºn.',
          unlockedMessage: obj.properties.getValue<String>('unlockedMessage'),
        );

        conditionalBarriers.add(barrier);
        print(
            'âœ… Loaded barrier: ${barrier.id} (Level: ${barrier.requiredLevel}, Boss: ${barrier.requiredBoss})');
      } catch (e) {
        print('âš ï¸ Error loading barrier from object ${obj.id}: $e');
      }
    }

    print('âœ… Loaded ${conditionalBarriers.length} conditional barriers');
  }

  void _loadBossTriggers() {
    bossTriggers.clear();

    // Search ALL object layers for BossTrigger objects
    // This is more robust than looking for a specific "Objects" layer
    // NOTE: Use map.layers instead of renderableLayers because ObjectGroups might not be renderable
    final objectLayers =
        mapComponent.tileMap.map.layers.whereType<ObjectGroup>();

    if (objectLayers.isEmpty) {
      print('ℹ️ No ObjectGroup layers found for boss triggers');
      return;
    }

    int triggersFound = 0;

    for (final layer in objectLayers) {
      for (final obj in layer.objects) {
        if (obj.name == 'BossTrigger') {
          // Convert Tiled coordinates (pixels) to Grid coordinates
          // Tiled uses 16x16 base tiles, so we divide by 16
          final rect = Rect.fromLTWH(
            obj.x / 16.0,
            obj.y / 16.0,
            obj.width / 16.0,
            obj.height / 16.0,
          );
          final bossId = obj.properties.getValue<String>('bossId') ?? 'unknown';
          final enemyType =
              obj.properties.getValue<String>('enemyType') ?? 'boss1';
          bossTriggers.add(BossTriggerData(
            rect: rect,
            bossId: bossId,
            enemyType: enemyType,
            triggered: false,
          ));
          print(
              '✅ Loaded boss trigger: $bossId ($enemyType) from layer ${layer.name}');
          triggersFound++;
        }
      }
    }

    if (triggersFound == 0) {
      print('ℹ️ No BossTrigger objects found in any layer');
    } else {
      print('✅ Loaded $triggersFound boss triggers');
    }
  }

  void checkBossTriggerCollision(Vector2 playerGridPos) {
    // Check directly against grid coordinates (more robust)
    if (bossTriggers.isNotEmpty && currentMapName.contains('boss_area')) {
      // Throttle logs or just print for now since it's debugging
      // print('🔍 Checking Boss Trigger: Player $playerGridPos vs ${bossTriggers.length} triggers');
    }

    for (int i = 0; i < bossTriggers.length; i++) {
      final trigger = bossTriggers[i];

      // Reset trigger if player leaves area (allows retry on death/flee)
      if (!trigger.rect.contains(playerGridPos.toOffset())) {
        if (trigger.triggered) {
          trigger.triggered = false;
          print('🔄 Reset trigger ${trigger.bossId} (player left area)');
        }
        continue;
      }

      // If we are here, player IS in rect
      // Skip if already triggered this session
      if (trigger.triggered) continue;

      // Debug print for proximity (if within 5 tiles)
      if ((trigger.rect.center - playerGridPos.toOffset()).distance < 5.0) {
        print(
            '⚠️ Proximity Check: Player $playerGridPos vs Trigger ${trigger.rect}');
      }

      // Check if player is in trigger area (using grid coordinates)
      if (trigger.rect.contains(playerGridPos.toOffset())) {
        print('🎯 HIT! Player inside trigger rect!');
        // Check if boss is already defeated
        if (player.stats.defeatedBosses.contains(trigger.bossId)) {
          print('ℹ️ Boss ${trigger.bossId} already defeated, skipping trigger');
          trigger.triggered = true;
          continue;
        }
        print('⚔️ Boss trigger activated: ${trigger.bossId}');
        trigger.triggered = true;

        // Start boss combat
        // Start boss combat
        // NOTE: startBossBattle handles UI and state transition
        startBossBattle(trigger.bossId, trigger.enemyType);
        break;
      }
    }
  }

  /// Check if player can move to target position (barrier check)
  /// Returns true if movement is allowed, false if blocked by barrier
  bool canPassBarrier(Vector2 targetGridPosition) {
    final mapX = targetGridPosition.x * tileWidth;
    final mapY = targetGridPosition.y * tileWidth;

    for (final barrier in conditionalBarriers) {
      final barrierBounds = barrier.getBounds();

      if (barrierBounds.contains(Offset(mapX, mapY))) {
        if (barrier.isPermanentlyUnlocked) {
          continue;
        }

        if (barrier.requiredLevel > 0 &&
            player.stats.level.value < barrier.requiredLevel) {
          print('ðŸš« Nivel ${barrier.requiredLevel} requerido');
          overlays.add('barrier_dialog');
          _currentBarrierMessage = barrier.blockedMessage;
          _currentBarrierIsBlocked = true;
          return false;
        }

        if (barrier.requiredBoss != 'none' &&
            !player.stats.hasBossBeenDefeated(barrier.requiredBoss)) {
          print('🚫 Boss ${barrier.requiredBoss} requerido');
          overlays.add('barrier_dialog');
          _currentBarrierMessage = barrier.blockedMessage;
          _currentBarrierIsBlocked = true;
          return false;
        }

        if (barrier.requiredQuest != 'none' &&
            !player.stats.hasQuestBeenCompleted(barrier.requiredQuest)) {
          print('🚫 Quest ${barrier.requiredQuest} requerida');
          overlays.add('barrier_dialog');
          _currentBarrierMessage = barrier.blockedMessage;
          _currentBarrierIsBlocked = true;
          return false;
        }

        barrier.isPermanentlyUnlocked = true;
        if (barrier.unlockedMessage != null) {
          overlays.add('barrier_dialog');
          _currentBarrierMessage = barrier.unlockedMessage!;
          _currentBarrierIsBlocked = false;
        }
      }
    }
    return true;
  }

  DangerLevel _parseDangerLevel(String? str) {
    if (str == null) return DangerLevel.medium;
    switch (str.toLowerCase()) {
      case 'safe':
        return DangerLevel.safe;
      case 'low':
        return DangerLevel.low;
      case 'medium':
        return DangerLevel.medium;
      case 'high':
        return DangerLevel.high;
      default:
        return DangerLevel.medium;
    }
  }

  ItemRarity _parseRarity(String? str) {
    if (str == null) return ItemRarity.uncommon;
    switch (str.toLowerCase()) {
      case 'common':
        return ItemRarity.common;
      case 'uncommon':
        return ItemRarity.uncommon;
      case 'rare':
        return ItemRarity.rare;
      case 'epic':
        return ItemRarity.epic;
      case 'legendary':
        return ItemRarity.legendary;
      default:
        return ItemRarity.uncommon;
    }
  }

  Vector2 screenToGridPosition(Vector2 screenPos) {
    final mapHeightInTiles = mapComponent.tileMap.map.height;
    final originX = mapHeightInTiles * (tileWidth / 2);

    final halfW = tileWidth / 2;
    final halfH = tileHeight / 2;

    // Adjust screen pos relative to origin
    final dx = screenPos.x - originX;
    final dy = screenPos.y -
        (tileHeight / 2); // Adjust for vertical center/offset if needed

    // Inverse isometric formula
    // screenX = (gridX - gridY) * halfW
    // screenY = (gridX + gridY) * halfH
    // => dx / halfW = gridX - gridY
    // => dy / halfH = gridX + gridY

    final A = dx / halfW;
    final B = dy / halfH;

    final gridX = (B + A) / 2;
    final gridY = (B - A) / 2;

    return Vector2(gridX, gridY);
  }

  ZoneProperties? _getZoneAt(Vector2 worldPos) {
    // Convert screen/world position to grid position
    final gridPos = screenToGridPosition(worldPos);

    // Tiled objects in isometric maps are typically defined in "projection" pixels.
    // Assuming Tiled uses tileWidth (32) as the base unit for object coordinates on the orthogonal plane.
    // We need to verify if it's 32 or something else.
    // Based on zone_test.tmx, zones are 300-400 wide.
    // If 1 tile = 32 units, then 300 units ~= 9.3 tiles.

    final mapX = gridPos.x * tileWidth; // Using tileWidth (32) as scale
    final mapY = gridPos.y *
        tileWidth; // Using tileWidth (32) as scale (assuming square grid basis)
    // Check all spawn zones
    for (int i = 0; i < spawnZoneRects.length; i++) {
      if (spawnZoneRects[i].contains(Offset(mapX, mapY))) {
        return zonePropertiesMap[i];
      }
    }
    return null;
  }

  void checkZoneTransition(Vector2 playerWorldPos) {
    // print('🔍 DEBUG: Player worldPos = $playerWorldPos');
    final newZone = _getZoneAt(playerWorldPos);

    if (newZone?.name != currentZone?.name) {
      currentZone = newZone;

      if (newZone != null) {
        print('📍 Entered: ${newZone.name} (${newZone.dangerLevel.name})');

        if (!discoveredZones.contains(newZone.name)) {
          discoveredZones.add(newZone.name);
        }

        // Update HUD Notifiers
        // CRITICAL: Update Danger Level FIRST, then Zone Name.
        currentDangerLevelNotifier.value = newZone.dangerLevel.index;
        currentZoneNameNotifier.value = newZone.name;

        // Auto-save on zone entry
        saveGame();
      } else {
        print('📍 Entered safe area (no zone)');
        // Update HUD Notifiers
        currentDangerLevelNotifier.value = 0; // DangerLevel.safe.index
        currentZoneNameNotifier.value = 'Safe Area';

        // Auto-save on safe area entry
        saveGame();
      }
    }
  }

  void checkRandomEncounter() {
    if (currentZone == null || currentZone!.enemyTypes.isEmpty) return;
    if (currentZone!.dangerLevel == DangerLevel.safe) return;
    if (stepsSinceLastBattle < MIN_STEPS_BETWEEN_BATTLES) return;
    if (player.stats.level.value < currentZone!.minLevel) return;
    if (Random().nextDouble() > currentZone!.encounterChance) return;

    print('âš”ï¸ Random encounter after $stepsSinceLastBattle steps!');
    stepsSinceLastBattle = 0;

    final random = Random();

    // 30% chance for multi-enemy if zone has multiple types
    final canMultiEnemy = currentZone!.enemyTypes.length > 1;
    final useMultiEnemy = canMultiEnemy && random.nextDouble() < 0.3;

    if (useMultiEnemy) {
      // Generate 2-3 enemy group
      final enemyCount = random.nextBool() ? 2 : 3;
      final enemyGroup = <String>[];

      for (int i = 0; i < enemyCount; i++) {
        final enemyType = currentZone!
            .enemyTypes[random.nextInt(currentZone!.enemyTypes.length)];
        enemyGroup.add(enemyType);
      }

      print('ðŸŽ² Multi-enemy encounter: $enemyGroup');
      startCombatMulti(enemyGroup);
    } else {
      // Single enemy (classic)
      final enemyType = currentZone!
          .enemyTypes[random.nextInt(currentZone!.enemyTypes.length)];
      startCombat(enemyType);
    }
  }

  Future<void> _loadChests() async {
    final pickupsLayer = mapComponent.tileMap.getLayer<ObjectGroup>('Pickups');
    if (pickupsLayer == null) return;

    final chestSprite = await loadSprite('iso_tile_export.png',
        srcPosition: Vector2(384, 32), srcSize: Vector2(32, 32));

    int chestCounter = 0;
    for (final tiledObject in pickupsLayer.objects) {
      if (tiledObject.gid == null || tiledObject.gid == 0) continue;
      final gridX = tiledObject.properties.getValue<int>('gridX');
      final gridY = tiledObject.properties.getValue<int>('gridY');
      if (gridX == null || gridY == null) continue;
      final gridPosition = Vector2(gridX.toDouble(), gridY.toDouble());

      // Create unique chest ID based on map name and position
      final chestId = '$currentMapName:$gridX,$gridY';

      // Skip if chest was already opened
      if (openedChests.contains(chestId)) {
        continue;
      }

      InventoryItem itemForThisChest;
      // Simple hardcoded logic for now, can be improved later
      if (chestCounter == 0) {
        itemForThisChest = ItemDatabase.rustySword;
      } else if (chestCounter == 1) {
        itemForThisChest = ItemDatabase.leatherTunic;
      } else {
        itemForThisChest = ItemDatabase.potion;
      }
      chestCounter++;

      final chest = Chest(
        gridPosition: gridPosition,
        item: itemForThisChest,
      )
        ..sprite = chestSprite
        ..size = Vector2(32, 32)
        ..position = gridToScreenPosition(gridPosition)
        ..anchor = Anchor.bottomCenter
        ..priority = 10;

      await world.add(chest);
    }
    print(
        'âœ… Loaded $chestCounter chests (${openedChests.length} already opened)');
  }

  // ========== NPC SYSTEM ==========

  void _loadNPCs() {
    npcs.clear();
    // Remove old NPC components
    for (final npc in npcComponents) {
      npc.removeFromParent();
    }
    npcComponents.clear();

    final npcsLayer = mapComponent.tileMap.getLayer<ObjectGroup>('NPCs');
    if (npcsLayer == null) {
      print('â„¹ï¸ No NPCs layer found (this is optional)');
      return;
    }

    for (final obj in npcsLayer.objects) {
      // Extract properties from Tiled
      final id = obj.properties.getValue<String>('npcId') ?? 'npc_${obj.id}';
      final name = obj.properties.getValue<String>('name') ?? 'NPC';
      final typeStr = obj.properties.getValue<String>('npcType') ?? 'generic';
      final type = _parseNPCType(typeStr);
      final spriteSheet = obj.properties.getValue<String>('spriteSheet') ??
          'characters/player.png';
      final dialogue = obj.properties.getValue<String>('dialogue') ?? 'Hola.';

      // Calculate grid position (same as portals - no scaleFactor on x/y)
      final gridX = (obj.x / 16.0).floor();
      final gridY = (obj.y / 16.0).floor();
      final gridPos = Vector2(gridX.toDouble(), gridY.toDouble());

      // Create NPC model
      final npc = NPC(
        id: id,
        name: name,
        type: type,
        gridPosition: gridPos,
        spriteSheet: spriteSheet,
        dialogue: dialogue,
      );

      npcs[id] = npc;

      // Create visual component
      final npcComponent = NPCComponent(npc: npc);
      npcComponents.add(npcComponent);
      world.add(npcComponent);

      print('âœ… Loaded NPC: $name ($type) at $gridPos');
    }

    print('âœ… Loaded ${npcs.length} NPCs');
  }

  NPCType _parseNPCType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'vendor':
        return NPCType.vendor;
      case 'quest_giver':
      case 'questgiver':
        return NPCType.questGiver;
      case 'lore':
        return NPCType.lore;
      default:
        return NPCType.generic;
    }
  }

  void checkNPCInteraction() {
    if (state != GameState.exploring) return;

    for (final npcComponent in npcComponents) {
      if (npcComponent.canInteract()) {
        // NPC is in range and ready to interact
        startDialogue(npcComponent.npc.id);
        return; // Only interact with one NPC at a time
      }
    }
  }

  void startDialogue(String npcId) {
    final npc = npcs[npcId];
    if (npc == null) return;

    activeDialogueNPC = npcId;
    state = GameState.inMenu; // Pause game
    overlays.add('DialogueUI');

    print('ðŸ’¬ Started dialogue with ${npc.name}');
  }

  void endDialogue() {
    if (activeDialogueNPC != null) {
      print('💬 Ended dialogue with ${npcs[activeDialogueNPC]?.name}');
    }

    activeDialogueNPC = null;
    state = GameState.exploring;
    overlays.remove('DialogueUI');
  }

  void updateExploration(Vector2 playerPos) {
    final centerX = playerPos.x.round();
    final centerY = playerPos.y.round();

    for (int x = centerX - explorationRadius;
        x <= centerX + explorationRadius;
        x++) {
      for (int y = centerY - explorationRadius;
          y <= centerY + explorationRadius;
          y++) {
        // Check distance to create circular reveal
        if (pow(x - centerX, 2) + pow(y - centerY, 2) <=
            pow(explorationRadius, 2)) {
          exploredTiles.add(math.Point(x, y));
        }
      }
    }
  }

  // ===== MOBILE CONTROLS =====

  void handleMobileInput(int gridX, int gridY) {
    if (!isPlayerReady) return;
    if (state != GameState.exploring) return;
    if (!player.isMounted) return;
    if (player.isMoving) return;

    final direction = Vector2(gridX.toDouble(), gridY.toDouble());

    // Update Fog of War
    if (player.isMounted) {
      updateExploration(player.gridPosition);
    }
    player.move(direction);
  }

  String _currentBarrierMessage = '';
  bool _currentBarrierIsBlocked = true;

  // Public getters for overlay access
  String get currentBarrierMessage => _currentBarrierMessage;
  bool get currentBarrierIsBlocked => _currentBarrierIsBlocked;

  Future<void> playBackgroundVideo(String asset) async {
    try {
      // Always set the background asset name (for static fallback)
      currentBackgroundNotifier.value = asset;

      if (videoPlayerControllerNotifier.value?.dataSource ==
          'assets/videos/$asset') {
        return;
      }

      if (videoPlayerControllerNotifier.value != null) {
        await stopBackgroundVideo();
        // Restore the asset name because stopBackgroundVideo clears it
        currentBackgroundNotifier.value = asset;
      }

      // Skip video on mobile (Android/iOS) to avoid codec/source errors
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        print(
            '📱 Mobile detected: Skipping video playback (using static image: $asset)');
        videoPlayerControllerNotifier.value = null;
        return;
      }

      final controller = VideoPlayerController.asset('assets/videos/$asset');
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);

      // Await play() to catch Autoplay errors (NotAllowedError)
      await controller.play();

      videoPlayerControllerNotifier.value = controller;
    } catch (e) {
      print('⚠️ Video player error (harmless on web if autoplay blocked): $e');
      // Ensure we don't leave a broken controller
      if (videoPlayerControllerNotifier.value != null) {
        videoPlayerControllerNotifier.value = null;
      }
    }
  }

  Future<void> stopBackgroundVideo() async {
    print('🛑 Stopping background video...');
    try {
      if (videoPlayerController != null) {
        await videoPlayerController!.dispose();
        videoPlayerController = null;
      }
      videoPlayerControllerNotifier.value = null;
      currentBackgroundNotifier.value = null; // Clear static background too
      print('✅ Background video stopped and disposed');
    } catch (e) {
      print('⚠️ Error stopping video: $e');
    }
  }

  /// Clear all game components from the world (for clean save loading)
  /// Unlike reset(), this doesn't play menu music or clear overlays
  void clearWorld() {
    print('🧹 Clearing world components...');

    // Remove map component if exists (handle late initialization)
    try {
      if (world.contains(mapComponent)) {
        mapComponent.removeFromParent();
        print('  - Removed mapComponent');
      }
    } catch (e) {
      // mapComponent not initialized yet (first load), skip
      print('  - mapComponent not initialized, skipping');
    }

    // Remove player if exists and mounted (handle late initialization)
    try {
      if (isPlayerReady && world.contains(player)) {
        player.removeFromParent();
        print('  - Removed player');
      }
    } catch (e) {
      // player not initialized yet (first load), skip
      print('  - player not initialized, skipping');
    }

    // Remove all chests
    final chests = world.children.whereType<Chest>().toList();
    for (final chest in chests) {
      chest.removeFromParent();
    }
    if (chests.isNotEmpty) print('  - Removed ${chests.length} chests');

    // Remove all NPCs
    for (final npc in npcComponents) {
      npc.removeFromParent();
    }
    if (npcComponents.isNotEmpty)
      print('  - Removed ${npcComponents.length} NPCs');
    npcComponents.clear();
    npcs.clear();

    // Remove all portal visuals
    final portals = world.children.whereType<PortalVisual>().toList();
    for (final portal in portals) {
      portal.removeFromParent();
    }
    if (portals.isNotEmpty)
      print('  - Removed ${portals.length} portal visuals');

    // Reset player ready state
    isPlayerReady = false;
    isPlayerReadyNotifier.value = false;

    // Reset zone state
    currentZone = null;

    print('✅ World cleared successfully');
  }

  void reset() {
    stopMusic();
    world.removeAll(world.children);
    isPlayerReady = false;
    isPlayerReadyNotifier.value = false;
    overlays.clear();
    currentZone = null;
    playMenuMusic();
  }

  Future<void> preloadBackgroundVideo(String asset) async {
    // Skip video on mobile (Android/iOS) to avoid codec/source errors
    // The UI will fall back to the static splash image
    bool isMobile = false;
    if (!kIsWeb) {
      try {
        isMobile = Platform.isAndroid || Platform.isIOS;
      } catch (e) {
        // Ignore platform errors
      }
    }

    print('🔍 Checking platform: Web=$kIsWeb, Mobile=$isMobile');

    if (isMobile) {
      print('📱 Mobile detected: Skipping video preload (using static image)');
      videoPlayerControllerNotifier.value = null;
      return;
    }

    print('🎥 Preloading video: $asset');
    try {
      // Dispose previous controller if exists
      if (videoPlayerController != null) {
        await videoPlayerController!.dispose();
      }

      // Initialize new controller
      // FIX: Use correct path 'assets/videos/' and set notifier for fallback
      currentBackgroundNotifier.value = asset;
      videoPlayerController =
          VideoPlayerController.asset('assets/videos/$asset');
      await videoPlayerController!.initialize();
      videoPlayerController!.setLooping(true);
      videoPlayerController!.setVolume(0.0); // Mute by default
      await videoPlayerController!.play();

      // Update notifier to trigger UI rebuild
      videoPlayerControllerNotifier.value = videoPlayerController;
      print('✅ Video preloaded and playing: $asset');
    } catch (e) {
      print('❌ Error preloading video: $e');
      // Ensure notifier is null so UI knows to use fallback
      videoPlayerControllerNotifier.value = null;
    }
  }

  void _clearSessionState() {
    print('🧹 Clearing session state...');
    print('   - Previous Opened Chests: ${openedChests.length}');
    print('   - Previous Discovered Zones: ${discoveredZones.length}');

    discoveredZones.clear();
    openedChests.clear();
    exploredTiles.clear();
    spawnZoneRects.clear();
    zonePropertiesMap.clear();
    conditionalBarriers.clear();
    bossTriggers.clear();
    npcs.clear();
    npcComponents.clear();
    activeDialogueNPC = null;
    stepsSinceLastBattle = 0;
    accumulatedPlaytime = 0;
    sessionCreatedAt = null;
    // Note: player is recreated in loadGameData, so no need to clear it here
    print(
        '✅ Session state cleared. Chests: ${openedChests.length}, Zones: ${discoveredZones.length}');
  }

  void openGemShop() {
    // Allow opening shop even if already in menu (e.g. from ReviveDialog)
    state = GameState.inMenu;
    overlays.add('GemShop');
  }

  void onPlayerDeath() {
    print('💀 Player died! Showing ReviveDialog...');
    overlays.add('ReviveDialog');
  }

  void handleRevive() {
    if (player.stats.gems.value >= 25) {
      player.stats.gems.value -= 25;
      player.stats.currentHp.value = player.stats.maxHp.value; // Full heal
      overlays.remove('ReviveDialog');
      print('✨ Player revived with gems!');
    }
  }

  void handleNormalDeath() {
    // Lose 75% of gold (retain 25%)
    player.stats.gold.value = (player.stats.gold.value * 0.25).floor();
    player.stats.currentHp.value =
        player.stats.maxHp.value; // Full heal for respawn
    endCombat();
    print(
        '⚰️ Player accepted normal death. Gold reduced to ${player.stats.gold.value}.');
  }
}

class BossTriggerData {
  final Rect rect;
  final String bossId;
  final String enemyType;
  bool triggered;
  BossTriggerData({
    required this.rect,
    required this.bossId,
    required this.enemyType,
    this.triggered = false,
  });
}
