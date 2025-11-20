// lib/game/renegade_dungeon_game.dart

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Route; // ¡LA IMPORTACIÓN CORREGIDA!
import 'package:flutter/widgets.dart' hide Route; // ¡LA IMPORTACIÓN CORREGIDA!

import '../components/battle_scene.dart';
import '../components/player.dart';
import 'game_screen.dart'; // Importa la nueva pantalla de juego
import 'package:renegade_dungeon/game/splash_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'dart:math'; // ¡AÑADIDA! Para poder usar la clase Random.
import '../models/enemy_stats.dart';
import '../models/combat_ability.dart';
import '../models/combat_stats.dart';
import '../utils/damage_calculator.dart';
import '../game/enemy_ai.dart';
import '../models/ability_database.dart';

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
    currentTurn.value = CombatTurn.playerTurn;
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
    if (currentTurn.value != CombatTurn.playerTurn || currentEnemy == null) {
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

    print('⚔️ Jugador usa: ${ability.name}');

    // Consumir recursos
    if (ability.type == AbilityType.ultimate) {
      playerStats.spendUlt();
    } else if (ability.mpCost > 0) {
      playerStats.spendMp(ability.mpCost);
    }

    // Calcular y aplicar daño
    final enemyStats = (currentEnemy as dynamic).stats as EnemyStats;
    final damage = DamageCalculator.calculateDamage(
      ability: ability,
      attackerAtk: playerStats.attack.value,
      defenderDef: enemyStats.defense,
      critChance: playerStats.critChance.value,
    );

    enemyStats.takeDamage(damage);
    print('💥 ${ability.name} hizo $damage de daño!');

    // Ganar carga de Ultimate
    playerStats.gainUltCharge(ability.effect.ultGain);

    // Verificar si el enemigo murió
    if (enemyStats.currentHp.value == 0) {
      print('💀 ¡Enemigo derrotado!');
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

      return; // No hay contraataque
    }

    // Turno del enemigo
    currentTurn.value = CombatTurn.enemyTurn;
    Future.delayed(const Duration(seconds: 1), () {
      enemyUseAbility();
    });
  }

  /// El enemigo usa una habilidad elegida por IA
  void enemyUseAbility() {
    if (currentEnemy == null) return;

    final enemyStats = (currentEnemy as dynamic).stats;
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
}

// Interface para enemigos que tienen CombatStats
abstract class CombatStatsHolder {
  CombatStats get combatStats;
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
    loadZoneData(); // Ahora _loadZoneData se llama loadZoneData y es público
    collisionLayer = mapComponent.tileMap.getLayer<TileLayer>('Collision')!;
    collisionLayer.visible = false;

    // NOTA: La carga de cofres se queda en GameScreen porque son parte del mundo
    // y no son tan pesados. Si tuvieras muchos, también los podrías precargar aquí.

    player = Player(gridPosition: Vector2(20.0, 20.0));
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
    combatManager.startNewCombat(enemyType);
    _battleScene = BattleScene(enemy: combatManager.currentEnemy!);
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
      player.gridPosition = Vector2(20.0, 20.0);
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
    final mapWidthInTiles = mapComponent.tileMap.map.width;
    final originX = mapWidthInTiles * (tileWidth / 2);
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
      if (keysPressed.contains(LogicalKeyboardKey.keyM)) {
        togglePauseMenu();
        return KeyEventResult.handled;
      }
    }
    // ¡OJO! Asegúrate de que esta línea esté presente.
    // Llama al método original para que otras teclas (como el movimiento) sigan funcionando.
    return super.onKeyEvent(event, keysPressed);
  }
}
