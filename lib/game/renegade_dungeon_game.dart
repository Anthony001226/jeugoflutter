// lib/game/renegade_dungeon_game.dart

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/widgets.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:math';

import '../components/battle_scene.dart';
import '../components/player.dart';
import '../components/chest.dart';
import 'game_screen.dart';
import 'package:renegade_dungeon/game/splash_screen.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import '../models/enemy_stats.dart';
import '../models/combat_ability.dart';
import '../models/combat_stats.dart';
import '../models/combat_stats_holder.dart';
import '../utils/damage_calculator.dart';
import '../game/enemy_ai.dart';
import '../models/ability_database.dart';
import '../models/zone_config.dart';
import '../models/item_rarity.dart';
import '../components/portal_visual.dart';

import '../components/enemies/goblin_component.dart';
import '../components/enemies/slime_component.dart';
import '../components/enemies/bat_component.dart';
import '../components/enemies/skeleton_component.dart';
import 'package:flame/effects.dart';
import '../effects/screen_fade.dart';
import 'package:flame_audio/flame_audio.dart';

// ¡YA NO NECESITAMOS TANTAS IMPORTACIONES DE COMPONENTES AQUÍ!
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
  SpriteAnimationComponent? currentEnemy;

  // NEW: Multi-enemy support
  List<SpriteAnimationComponent> currentEnemies = [];
  int selectedTargetIndex = 0;

  late final ValueNotifier<CombatTurn> currentTurn;
  List<InventoryItem> lastDroppedItems = [];

  CombatManager(this.game) {
    currentTurn = ValueNotifier(CombatTurn.playerTurn);
  }

  void startNewCombat(String enemyType) {
    switch (enemyType) {
      case 'goblin':
        currentEnemy = GoblinComponent();
        break;
      case 'slime':
        currentEnemy = SlimeComponent();
        break;
      case 'bat':
        currentEnemy = BatComponent();
        break;
      case 'skeleton':
        currentEnemy = SkeletonComponent();
        break;
      default:
        currentEnemy = GoblinComponent();
    }

    // Calculate initiative to determine who goes first
    final playerSpeed = game.player.stats.speed.value;
    final enemySpeed = (currentEnemy as dynamic).stats.speed ?? 5;

    final playerInitiative = playerSpeed + Random().nextInt(11); // SPD + 0-10
    final enemyInitiative = enemySpeed + Random().nextInt(11);

    if (playerInitiative >= enemyInitiative) {
      currentTurn.value = CombatTurn.playerTurn;
      print(
          '⚡ ¡El jugador empieza primero! (Initiative: $playerInitiative vs $enemyInitiative)');
    } else {
      currentTurn.value = CombatTurn.enemyTurn;
      print(
          '⚡ ¡El enemigo empieza primero! (Initiative: $enemyInitiative vs $playerInitiative)');
      // Enemy gets first turn
      Future.delayed(const Duration(milliseconds: 1500), () {
        game.combatManager.enemyUseAbility();
      });
    }
  }

  /// Start combat against multiple enemies (1v2 or 1v3)
  void startNewCombatMulti(List<String> enemyTypes) {
    print('⚔️ Iniciando combate multi-enemigo: ${enemyTypes.length} enemigos');

    // Clear previous enemies
    currentEnemies.clear();
    currentEnemy = null;
    selectedTargetIndex = 0;

    // Create all enemies
    for (final enemyType in enemyTypes) {
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
        default:
          enemy = SlimeComponent();
      }
      currentEnemies.add(enemy);
    }

    // Apply group scaling for balance
    _applyGroupScaling();

    // Set first enemy as currentEnemy for backward compatibility
    if (currentEnemies.isNotEmpty) {
      currentEnemy = currentEnemies[0];
    }

    // Calculate initiative (use average enemy speed)
    final playerSpeed = game.player.stats.speed.value;
    int totalEnemySpeed = 0;
    for (final enemy in currentEnemies) {
      final speed = (enemy as dynamic).stats.speed ?? 5;
      totalEnemySpeed += (speed is int) ? speed : (speed as num).toInt();
    }
    final avgEnemySpeed = (totalEnemySpeed / currentEnemies.length).toInt();

    final playerInitiative = playerSpeed + Random().nextInt(11);
    final enemyInitiative = avgEnemySpeed + Random().nextInt(11);

    if (playerInitiative >= enemyInitiative) {
      currentTurn.value = CombatTurn.playerTurn;
      print(
          '⚡ ¡El jugador empieza primero! (Initiative: $playerInitiative vs $enemyInitiative)');
    } else {
      currentTurn.value = CombatTurn.enemyTurn;
      print(
          '⚡ ¡Los enemigos empiezan primero! (Initiative: $enemyInitiative vs $playerInitiative)');
      // Enemies get first turn
      Future.delayed(const Duration(milliseconds: 1500), () {
        _executeEnemyTurns();
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

      // --- ¡LÓGICA DEL DROP DE BOTÍN! ---
      // Limpiamos la lista de drops anteriores.
      lastDroppedItems.clear();
      final random = Random();

      // Recorremos la tabla de botín del enemigo.
      enemyStats.lootTable.forEach((item, chance) {
        // Lanzamos un "dado" de 0.0 a 1.0.
        if (random.nextDouble() < chance) {
          // ¡Éxito! Añadimos el objeto al jugador y a nuestra lista de drops.
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
    // Esto aplicará el efecto y consumirá una unidad del inventario.
    game.player.useItem(slot);

    // 3. ¡MUY IMPORTANTE! El turno del jugador ha terminado.
    // Le pasamos el control al enemigo.
    currentTurn.value = CombatTurn.enemyTurn;

    // 4. Programamos el contraataque del enemigo después de un segundo.
    Future.delayed(const Duration(seconds: 1), () {
      enemyAttack();
    });
  }

  // === NUEVO SISTEMA DE HABILIDADES ===

  /// Usa una habilidad del jugador contra el enemigo
  void usePlayerAbility(CombatAbility ability) {
    // Check if in multi-enemy or single-enemy mode
    final isMultiEnemy = currentEnemies.isNotEmpty;
    final targetEnemy =
        isMultiEnemy ? currentEnemies[selectedTargetIndex] : currentEnemy;

    if (currentTurn.value != CombatTurn.playerTurn || targetEnemy == null) {
      print('❌ No es turno del jugador o no hay enemigo');
      return;
    }

    final playerStats = game.player.stats.combatStats;

    // Verificar si puede usar la habilidad
    if (!ability.canUse(
        playerStats.currentMp.value, playerStats.ultMeter.value)) {
      print('❌ No se puede usar ${ability.name}: recursos insuficientes');
      return;
    }

    if (isMultiEnemy) {
      print(
          '⚔️ Jugador usa: ${ability.name} contra enemigo #${selectedTargetIndex + 1}');
    } else {
      print('⚔️ Jugador usa: ${ability.name}');
    }

    // Consumir recursos
    if (ability.type == AbilityType.ultimate) {
      playerStats.spendUlt();
    } else if (ability.mpCost > 0) {
      playerStats.spendMp(ability.mpCost);
    }

    // Calcular y aplicar daño
    final enemyStats = (targetEnemy as dynamic).stats as EnemyStats;
    final damage = DamageCalculator.calculateDamage(
      ability: ability,
      attackerAtk: playerStats.attack.value,
      defenderDef: enemyStats.defense,
      critChance: playerStats.critChance.value,
    );

    enemyStats.takeDamage(damage);
    print('💥 ${ability.name} hizo $damage de daño!');
    print('🔍 DEBUG: Enemy HP after damage: ${enemyStats.currentHp.value}');

    // Ganar carga de Ultimate
    playerStats.gainUltCharge(ability.effect.ultGain);

    // Verificar si el enemigo murió
    if (enemyStats.currentHp.value <= 0) {
      print('💀 ¡Enemigo derrotado! (HP <= 0 detected)');
      game.player.stats.gainXp(enemyStats.xpValue);

      // Loot drop
      lastDroppedItems.clear();
      final random = Random();
      enemyStats.lootTable.forEach((item, chance) {
        if (random.nextDouble() < chance) {
          game.player.addItem(item);
          lastDroppedItems.add(item);
        }
      });

      // Handle multi-enemy defeat
      if (isMultiEnemy) {
        _removeDefeatedEnemy(selectedTargetIndex);

        // Check if all enemies defeated
        if (currentEnemies.isEmpty) {
          print('🎉 ¡Todos los enemigos derrotados!');
          return; // Combat ends
        }

        // More enemies remain, continue to enemy turns
        print('⏳ Quedan ${currentEnemies.length} enemigos...');
        currentTurn.value = CombatTurn.enemyTurn;
        Future.delayed(const Duration(seconds: 1), () {
          _executeEnemyTurns();
        });
      }

      return; // No hay contraataque si solo había un enemigo
    }

    print('⏳ Scheduling enemy turn...');
    // Turno del enemigo
    currentTurn.value = CombatTurn.enemyTurn;
    Future.delayed(const Duration(seconds: 1), () {
      print('🤖 Executing scheduled enemy turn...');
      if (isMultiEnemy) {
        _executeEnemyTurns();
      } else {
        enemyUseAbility();
      }
    });
  }

  /// El enemigo usa una habilidad elegida por IA
  void enemyUseAbility() {
    if (currentEnemy == null) return;

    final enemyStats = (currentEnemy as dynamic).stats;

    // Check if enemy is already dead
    if (enemyStats.currentHp.value <= 0) {
      print('💀 ¡Enemigo derrotado! (Cancelando turno enemigo)');
      return;
    }

    final enemyCombatStats =
        (enemyStats is EnemyStats && enemyStats is CombatStatsHolder)
            ? (enemyStats as CombatStatsHolder).combatStats
            : null;

    // Si el enemigo no tiene CombatStats, usar ataque simple
    if (enemyCombatStats == null) {
      print('🤖 Enemigo usa ataque simple (sin CombatStats)');
      game.player.stats.takeDamage(enemyStats.attack);
      if (game.player.stats.currentHp.value == 0) return;
      currentTurn.value = CombatTurn.playerTurn;
      return;
    }

    // Obtener habilidades del enemigo
    final enemyType = _getEnemyType();
    final abilities = AbilityDatabase.getEnemyAbilities(enemyType);

    if (abilities.isEmpty) {
      print('🤖 Enemigo usa ataque simple (sin habilidades)');
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

    print('🤖 Enemigo usa: ${chosenAbility.name}');

    // Consumir recursos del enemigo
    if (chosenAbility.type == AbilityType.ultimate) {
      enemyCombatStats.spendUlt();
    } else if (chosenAbility.mpCost > 0) {
      enemyCombatStats.spendMp(chosenAbility.mpCost);
    }

    // Calcular daño
    final damage = DamageCalculator.calculateDamage(
      ability: chosenAbility,
      attackerAtk: enemyCombatStats.attack.value,
      defenderDef: game.player.stats.combatStats.defense.value,
      critChance: enemyCombatStats.critChance.value,
    );

    game.player.stats.takeDamage(damage);
    print('💥 El enemigo hizo $damage de daño!');

    // Ganar ULT al recibir daño (ya está en PlayerStats.takeDamage)

    if (game.player.stats.currentHp.value == 0) {
      print('💀 ¡Jugador derrotado!');
      game.endCombat(); // Call endCombat to handle respawn and UI reset
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
        '⚖️ Aplicando balance de grupo (${currentEnemies.length} enemigos): ${(scaleFactor * 100).toInt()}% stats');

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
      print('🗑️ Removiendo enemigo #${index + 1} derrotado');
      currentEnemies.removeAt(index);

      // Adjust selected target if needed
      if (selectedTargetIndex >= currentEnemies.length &&
          currentEnemies.isNotEmpty) {
        selectedTargetIndex = currentEnemies.length - 1;
      } else if (currentEnemies.isEmpty) {
        selectedTargetIndex = 0;
      }

      // Trigger visual update
      final temp = currentTurn.value;
      currentTurn.value = temp;
    }
  }

  /// Cycle to next enemy target (Tab/E)
  void cycleTargetNext() {
    if (currentEnemies.isEmpty) return;

    selectedTargetIndex = (selectedTargetIndex + 1) % currentEnemies.length;
    print('🎯 Target switched to enemy #${selectedTargetIndex + 1}');

    final temp = currentTurn.value;
    currentTurn.value = temp;
  }

  /// Cycle to previous enemy target (Q)
  void cycleTargetPrevious() {
    if (currentEnemies.isEmpty) return;

    selectedTargetIndex = (selectedTargetIndex - 1 + currentEnemies.length) %
        currentEnemies.length;
    print('🎯 Target switched to enemy #${selectedTargetIndex + 1}');

    final temp = currentTurn.value;
    currentTurn.value = temp;
  }

  /// Single enemy takes their turn
  void _enemyTakeTurn(SpriteAnimationComponent enemy, int index) {
    final stats = (enemy as dynamic).stats;
    final enemyType = _getEnemyTypeForComponent(enemy);

    // Check if enemy has CombatStats
    final hasCombatStats = stats is CombatStatsHolder;

    if (!hasCombatStats) {
      // Simple attack for enemies without CombatStats
      print('🤖 Enemigo #${index + 1} usa ataque simple');
      final damage =
          (stats.attack - game.player.stats.defense.value).clamp(1, 999);
      game.player.stats.takeDamage(damage);
      print('💥 Enemigo #${index + 1} hizo $damage de daño!');
      return;
    }

    // Get enemy abilities
    final combatStats = (stats as CombatStatsHolder).combatStats;
    final abilities = AbilityDatabase.getEnemyAbilities(enemyType);

    if (abilities.isEmpty) {
      // Fallback to simple attack
      print('🤖 Enemigo #${index + 1} usa ataque simple (sin habilidades)');
      game.player.stats.takeDamage(combatStats.attack.value);
      return;
    }

    // Use AI to choose ability
    final chosenAbility = EnemyAI.chooseAbility(
      abilities: abilities,
      stats: combatStats,
    );

    print('🤖 Enemigo #${index + 1} usa: ${chosenAbility.name}');

    // Consume resources
    if (chosenAbility.type == AbilityType.ultimate) {
      combatStats.spendUlt();
    } else if (chosenAbility.mpCost > 0) {
      combatStats.spendMp(chosenAbility.mpCost);
    }

    // Calculate and apply damage
    final damage = DamageCalculator.calculateDamage(
      ability: chosenAbility,
      attackerAtk: combatStats.attack.value,
      defenderDef: game.player.stats.combatStats.defense.value,
      critChance: combatStats.critChance.value,
    );

    game.player.stats.takeDamage(damage);
    print('💥 Enemigo #${index + 1} hizo $damage de daño!');
  }

  /// Execute turns for all alive enemies (called after player turn)
  void _executeEnemyTurns() {
    if (currentEnemies.isEmpty) return;

    print('🤖 Ejecutando turnos de ${currentEnemies.length} enemigos...');

    for (int i = 0; i < currentEnemies.length; i++) {
      _enemyTakeTurn(currentEnemies[i], i);

      // Check if player died mid-combat
      if (game.player.stats.currentHp.value <= 0) {
        print('💀 ¡Jugador derrotado durante turnos enemigos!');
        return;
      }
    }

    // All enemies attacked, back to player turn
    currentTurn.value = CombatTurn.playerTurn;
  }
}

class RenegadeDungeonGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  late final RouterComponent router;
  VideoPlayerController? videoPlayerController;
  GameState state = GameState.exploring;
  // Propiedades globales que GameScreen necesitará
  late final CombatManager combatManager;
  late TiledComponent mapComponent;
  late Player player;
  late TileLayer collisionLayer;

  final double tileWidth = 32.0;
  final double tileHeight = 16.0;

  bool zoneHasEnemies = false;
  List<String> zoneEnemyTypes = [];
  List<double> zoneEnemyChances = [];
  BattleScene? _battleScene;

  // ========== PORTAL & ZONE SYSTEM ==========
  final Map<String, PortalData> portals = {};
  String currentMapName = 'dungeon.tmx';
  static const int MIN_STEPS_BETWEEN_BATTLES = 10;
  int stepsSinceLastBattle = 0;
  final List<Rect> spawnZoneRects = [];
  final Map<int, ZoneProperties> zonePropertiesMap = {};
  ZoneProperties? currentZone;
  final Set<String> discoveredZones = {};

  // Track opened chests to prevent regeneration
  final Set<String> openedChests = {};

  final videoPlayerControllerNotifier =
      ValueNotifier<VideoPlayerController?>(null);

  @override
  Color backgroundColor() => Colors.transparent;
  // --- ¡MÉTODO onLoad CORREGIDO Y LIMPIO! ---
  @override
  Future<void> onLoad() async {
    //camera.viewport.transparent = true;
    FlameAudio.bgm.initialize();
    await FlameAudio.audioCache.loadAll([
      'menu_music.ogg',
      'dungeon_music.ogg',
    ]);
    //playMenuMusic();
    // 1. Inicializa sistemas globales.
    combatManager = CombatManager(this);

    // 2. Carga el router. Su única tarea es decidir qué pantalla mostrar.
    add(
      router = RouterComponent(
        initialRoute: 'splash-screen',
        routes: {
          'splash-screen': Route(SplashScreen.new),

          // --- ¡LÓGICA CORREGIDA AQUÍ! ---
          'main-menu': Route(() {
            // 1. Inicia el video de fondo.
            playBackgroundVideo('menu_background.mp4');

            // 2. Crea un componente que contiene el temporizador.
            //    Al devolver un Component aquí, reemplazamos el SplashScreen anterior,
            //    limpiando el escenario y dejando ver el video.
            return Component(children: [
              TimerComponent(
                period:
                    0.001, // Un retraso mínimo para asegurar que todo esté listo
                repeat: false,
                onTick: () {
                  // 3. Limpia cualquier overlay viejo y añade el del menú principal.
                  overlays.clear();
                  overlays.add('MainMenu');
                },
              ),
            ]);
          }),

          // El menú de slots ahora es más simple, no maneja el video.
          'slot-selection-menu': Route(() {
            // ¡CAMBIO! Llamamos al método general con el video de los slots.
            playBackgroundVideo('slot_background.mp4');
            return Component(children: [
              TimerComponent(
                  period: 0.001,
                  repeat: false,
                  onTick: () {
                    overlays.clear();
                    overlays.add('SlotSelectionMenu');
                  }),
            ]);
          }),

          // --- Y LÓGICA CORREGIDA AQUÍ TAMBIÉN ---
          'loading-screen': Route(() {
            // Cuando salimos de CUALQUIER menú para ir al juego, DETENEMOS EL VIDEO.
            stopBackgroundVideo();
            return Component(
              children: [
                TimerComponent(
                  period: 0.01,
                  repeat: false,
                  onTick: () async {
                    overlays.add('LoadingUI');
                    await loadGameData();
                    overlays.remove('LoadingUI');
                    router.pushReplacementNamed('game-screen');
                  },
                ),
              ],
            );
          }),
          'game-screen': Route(GameScreen.new),
        },
      ),
    );
  }

  Future<void> loadGameData() async {
    // Esto simula una carga más larga, puedes quitarlo después
    await Future.delayed(const Duration(seconds: 5));

    mapComponent = await TiledComponent.load(
        'dungeon.tmx', Vector2(tileWidth, tileHeight));
    loadZoneData();
    collisionLayer = mapComponent.tileMap.getLayer<TileLayer>('Collision')!;
    collisionLayer.visible = false;

    // Load portals and zones for initial map
    // Load portals and zones for initial map
    _loadPortals();
    _loadSpawnZones();
    await _loadChests();

    player = Player(gridPosition: Vector2(5.0, 5.0));
  }

  // --- LOS MÉTODOS DE ABAJO SON GLOBALES Y SE QUEDAN AQUÍ ---

  Future<void> playBackgroundVideo(String videoName) async {
    // Si ya estamos reproduciendo el video correcto, no hacemos nada.
    if (videoPlayerControllerNotifier.value?.dataSource ==
        'assets/videos/$videoName') {
      return;
    }

    // Si hay otro video reproduciéndose, lo detenemos primero.
    if (videoPlayerControllerNotifier.value != null) {
      await stopBackgroundVideo();
    }

    final controller = VideoPlayerController.asset('assets/videos/$videoName');
    await controller.initialize();
    await controller.setLooping(true);
    await controller.setVolume(0.0);

    videoPlayerControllerNotifier.value = controller;

    await controller.play();
  }

  // ANTES: Future<void> stopMenuVideo() async { ... }
  // AHORA: Solo un cambio de nombre por consistencia
  Future<void> stopBackgroundVideo() async {
    if (videoPlayerControllerNotifier.value == null) return;

    final controller = videoPlayerControllerNotifier.value!;
    await controller.dispose();

    videoPlayerControllerNotifier.value = null;
  }

  void playMenuMusic() {
    // Detiene cualquier música que esté sonando antes de empezar la nueva.
    FlameAudio.bgm.stop();
    // Reproduce la música del menú en un bucle infinito.
    FlameAudio.bgm.play('menu_music.ogg');
  }

  void playWorldMusic() {
    FlameAudio.bgm.stop();
    // Reproduce la música de la mazmorra en un bucle.
    FlameAudio.bgm.play('dungeon_music.ogg');
  }

  void stopMusic() {
    FlameAudio.bgm.stop();
  }

  void startCombat(String enemyType) async {
    state = GameState.inCombat;
    player.showSurpriseEmote();
    camera.viewfinder.add(
      ScaleEffect.to(
        Vector2.all(1.5),
        EffectController(duration: 0.4, curve: Curves.easeIn),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1000));
    final screenFade = ScreenFade();
    camera.viewport.add(screenFade);
    await screenFade.fadeOut();
    world.removeFromParent();
    camera.viewfinder.zoom = 1.0;

    // Support both single and multi-enemy modes
    if (combatManager.currentEnemies.isEmpty) {
      // Single enemy mode (legacy)
      combatManager.startNewCombat(enemyType);
      _battleScene = BattleScene(enemy: combatManager.currentEnemy!);
    } else {
      // Multi-enemy mode (currentEnemies already populated)
      _battleScene = BattleScene(enemies: combatManager.currentEnemies);
    }

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
        Vector2.all(1.5),
        EffectController(duration: 0.4, curve: Curves.easeIn),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1000));
    final screenFade = ScreenFade();
    camera.viewport.add(screenFade);
    await screenFade.fadeOut();
    world.removeFromParent();
    camera.viewfinder.zoom = 1.0;
    combatManager.startNewCombatMulti(enemyTypes);
    _battleScene = BattleScene(enemies: combatManager.currentEnemies);
    await add(_battleScene!);
    overlays.add('CombatUI');
    await screenFade.fadeIn();
  }

  void endCombat() {
    // --- ¡NUEVA LÓGICA AÑADIDA! ---
    // Si el jugador fue derrotado, restauramos su estado.
    if (player.stats.currentHp.value == 0) {
      player.stats.currentHp.value = player.stats.maxHp.value;
      player.stats.currentMp.value = player.stats.maxMp.value;
      player.gridPosition = Vector2(5.0, 5.0);
      player.position = gridToScreenPosition(player.gridPosition);
    }
    // -----------------------------

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
    // ¡OJO! Asegúrate de que esta línea esté presente.
    // Llama al método original para que otras teclas (como el movimiento) sigan funcionando.
    return super.onKeyEvent(event, keysPressed);
  }

  // ========== PORTAL SYSTEM ==========

  void _loadPortals() {
    portals.clear();
    final portalsLayer = mapComponent.tileMap.getLayer<ObjectGroup>('Portals');
    if (portalsLayer == null) {
      print('⚠️ No Portals layer found');
      return;
    }

    for (final obj in portalsLayer.objects) {
      final gridX = obj.properties.getValue<int>('gridX');
      final gridY = obj.properties.getValue<int>('gridY');
      final targetMap = obj.properties.getValue<String>('targetMap');
      final targetX = obj.properties.getValue<int>('targetX') ?? 10;
      final targetY = obj.properties.getValue<int>('targetY') ?? 10;

      if (gridX != null && gridY != null && targetMap != null) {
        final gridPos = Vector2(gridX.toDouble(), gridY.toDouble());
        portals[obj.name] = PortalData(
          gridPosition: gridPos,
          targetMap: targetMap,
          targetPosition: Vector2(targetX.toDouble(), targetY.toDouble()),
        );

        // Add visual indicator for portal
        final visualPos = gridToScreenPosition(gridPos);
        final portalVisual = PortalVisual(position: visualPos);
        world.add(portalVisual);
      }
    }

    print('✅ Loaded ${portals.length} portals');
  }

  void checkPortalCollision(Vector2 playerGridPos) {
    for (final portal in portals.values) {
      if (portal.gridPosition == playerGridPos) {
        transitionToMap(portal.targetMap, portal.targetPosition);
        break;
      }
    }
  }

  Future<void> transitionToMap(String mapName, Vector2 startPos) async {
    print('🚪 Transitioning to $mapName...');

    overlays.remove('PlayerHud');
    overlays.add('map_transition');
    await Future.delayed(Duration(milliseconds: 500));

    try {
      world.remove(mapComponent);

      // Remove all chests and portal visuals from the previous map
      final chests = world.children.whereType<Chest>().toList();
      for (final chest in chests) {
        chest.removeFromParent();
      }
      final portalVisuals = world.children.whereType<PortalVisual>().toList();
      for (final visual in portalVisuals) {
        visual.removeFromParent();
      }

      mapComponent =
          await TiledComponent.load(mapName, Vector2(tileWidth, tileHeight));
      collisionLayer = mapComponent.tileMap.getLayer<TileLayer>('Collision')!;
      collisionLayer.visible = false;
      await world.add(mapComponent);

      currentMapName = mapName;
      _loadPortals();
      _loadSpawnZones();
      await _loadChests();

      player.gridPosition = startPos;
      player.position = gridToScreenPosition(startPos);

      stepsSinceLastBattle = 0;

      print('✅ Loaded $mapName');
    } catch (e, stackTrace) {
      print('❌ Error loading map $mapName: $e');
      print(stackTrace);
    } finally {
      await Future.delayed(Duration(milliseconds: 300));
      overlays.remove('map_transition');
      overlays.add('PlayerHud');
    }
  }

  // ========== ZONE SYSTEM ==========

  void _loadSpawnZones() {
    spawnZoneRects.clear();
    zonePropertiesMap.clear();
    currentZone = null;

    final zonesLayer = mapComponent.tileMap.getLayer<ObjectGroup>('SpawnZones');
    if (zonesLayer == null) {
      print('⚠️ No SpawnZones layer found');
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

    print('✅ Loaded ${spawnZoneRects.length} spawn zones');
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

    // print('🔍 DEBUG: Screen=$worldPos -> Grid=$gridPos -> Map=($mapX, $mapY)');
    // TEMPORARY DEBUG: Print every check to see what's happening
    if (stepsSinceLastBattle % 10 == 0) {
      // Just print it.
      print(
          '🔍 DEBUG: Screen=$worldPos -> Grid=${gridPos.toString()} -> Map=(${mapX.toStringAsFixed(1)}, ${mapY.toStringAsFixed(1)})');
    }

    for (int i = 0; i < spawnZoneRects.length; i++) {
      if (spawnZoneRects[i].contains(Offset(mapX, mapY))) {
        return zonePropertiesMap[i];
      }
    }
    return null;
  }

  void checkZoneTransition(Vector2 playerWorldPos) {
    print('🔍 DEBUG: Player worldPos = $playerWorldPos');
    final newZone = _getZoneAt(playerWorldPos);

    if (newZone?.name != currentZone?.name) {
      currentZone = newZone;

      if (newZone != null) {
        print('📍 Entered: ${newZone.name} (${newZone.dangerLevel.name})');

        if (!discoveredZones.contains(newZone.name)) {
          discoveredZones.add(newZone.name);
        }
      } else {
        print('📍 Entered safe area (no zone)');
      }
    }
  }

  void checkRandomEncounter() {
    if (currentZone == null || currentZone!.enemyTypes.isEmpty) return;
    if (currentZone!.dangerLevel == DangerLevel.safe) return;
    if (stepsSinceLastBattle < MIN_STEPS_BETWEEN_BATTLES) return;
    if (player.stats.level.value < currentZone!.minLevel) return;
    if (Random().nextDouble() > currentZone!.encounterChance) return;

    print('⚔️ Random encounter after $stepsSinceLastBattle steps!');
    stepsSinceLastBattle = 0;

    final enemyType = currentZone!
        .enemyTypes[Random().nextInt(currentZone!.enemyTypes.length)];
    startCombat(enemyType);
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
        '✅ Loaded $chestCounter chests (${openedChests.length} already opened)');
  }
}
