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
import '../services/ad_service.dart';
import '../services/offline_storage_service.dart';
import '../services/auth_service.dart';
import '../models/player_save_data.dart';

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
  final RenegadeDungeonGame game;

  SpriteAnimationComponent? _currentEnemy;

  final ValueNotifier<SpriteAnimationComponent?> currentEnemyNotifier =
      ValueNotifier(null);

  SpriteAnimationComponent? get currentEnemy => _currentEnemy;
  set currentEnemy(SpriteAnimationComponent? value) {
    _currentEnemy = value;
    currentEnemyNotifier.value = value;
  }

  List<SpriteAnimationComponent> currentEnemies = [];
  Map<SpriteAnimationComponent, String> enemyNames = {};
  int selectedTargetIndex = 0;

  bool isProcessingAbility = false;

  List<TurnEntity> turnQueue = [];
  int currentTurnIndex = -1;

  late final ValueNotifier<CombatTurn> currentTurn;
  List<InventoryItem> lastDroppedItems = [];
  int totalXpEarned = 0;
  int totalGoldEarned = 0;

  CombatManager(this.game) {
    currentTurn = ValueNotifier(CombatTurn.playerTurn);
  }

  void selectTarget(SpriteAnimationComponent target) {
    if (!currentEnemies.contains(target)) return;

    selectedTargetIndex = currentEnemies.indexOf(target);
    currentEnemy = target;
  }

  void startNewCombat(String enemyType) {
    startNewCombatMulti([enemyType]);
  }

  String? currentBossId;

  void startBossCombat(String bossId, String enemyType) {
    startNewCombatMulti([enemyType]);
    currentBossId = bossId;
  }

  void startNewCombatMulti(List<String> enemyTypes) {
    currentEnemies.clear();
    enemyNames.clear();
    lastDroppedItems.clear();
    totalXpEarned = 0;
    totalGoldEarned = 0;
    currentEnemy = null;
    selectedTargetIndex = 0;
    turnQueue.clear();
    currentTurnIndex = -1;
    currentBossId = null;

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

    _applyGroupScaling();

    if (currentEnemies.isNotEmpty) {
      currentEnemy = currentEnemies[0];
    }
    final playerSpeed = game.player.stats.speed.value;
    final playerInit = playerSpeed + Random().nextInt(11);

    turnQueue.add(TurnEntity(isPlayer: true, initiative: playerInit));

    for (int i = 0; i < currentEnemies.length; i++) {
      final enemy = currentEnemies[i];
      final speed = (enemy as dynamic).stats.speed ?? 5;
      final enemySpeed = (speed is int) ? speed : (speed as num).toInt();
      final enemyInit = enemySpeed + Random().nextInt(11);

      turnQueue.add(
          TurnEntity(isPlayer: false, enemy: enemy, initiative: enemyInit));
    }

    turnQueue.sort((a, b) => b.initiative.compareTo(a.initiative));

    nextTurn();
  }

  void nextTurn() {
    if (turnQueue.isEmpty) return;
    currentTurnIndex = (currentTurnIndex + 1) % turnQueue.length;
    final currentEntity = turnQueue[currentTurnIndex];

    if (currentEntity.isPlayer) {
      game.player.stats.combatStats.tickEffects();
    } else if (currentEntity.enemy != null) {
      final stats = (currentEntity.enemy as dynamic).stats;
      if (stats is CombatStatsHolder) {
        stats.combatStats.tickEffects();
      }
    }

    if (currentEntity.isPlayer) {
      currentTurn.value = CombatTurn.playerTurn;
      isProcessingAbility = false;
    } else {
      currentTurn.value = CombatTurn.enemyTurn;
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (currentEntity.enemy != null) {
          final index = currentEnemies.indexOf(currentEntity.enemy!);
          if (index != -1) {
            _enemyTakeTurn(currentEntity.enemy!, index);
          } else {
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
      game.player.stats.gainXp(enemyStats.xpValue);
      lastDroppedItems.clear();
      lastDroppedItems.clear();
      final random = Random();
      enemyStats.lootTable.forEach((item, chance) {
        if (random.nextDouble() < chance) {
          game.player.addItem(item);
          lastDroppedItems.add(item);
        }
      });
      return;
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
    if (currentTurn.value != CombatTurn.playerTurn || !slot.item.isUsable) {
      return;
    }
    game.player.useItem(slot);
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

  void usePlayerAbility(CombatAbility ability) {
    if (isProcessingAbility) {
      return;
    }

    if (currentTurn.value != CombatTurn.playerTurn) {
      return;
    }

    isProcessingAbility = true; // Lock

    final isMultiEnemy = currentEnemies.isNotEmpty;
    final targetEnemy =
        isMultiEnemy ? currentEnemies[selectedTargetIndex] : currentEnemy;

    if (currentTurn.value != CombatTurn.playerTurn || targetEnemy == null) {
      return;
    }

    final playerStats = game.player.stats.combatStats;

    if (!ability.canUse(
        playerStats.currentMp.value, playerStats.ultMeter.value)) {
      return;
    }

    if (ability.effect.targetType == TargetType.allEnemies) {
      if (currentEnemies.isEmpty) {
        return;
      }

      if (ability.type == AbilityType.ultimate) {
        playerStats.spendUlt();
      } else if (ability.mpCost > 0) {
        playerStats.spendMp(ability.mpCost);
      }

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

        playerStats.gainUltCharge(ability.effect.ultGain);

        if (enemyStats.currentHp.value <= 0) {
          _handleEnemyDeath(enemy, enemyStats);
        }
      }

      Future.delayed(const Duration(seconds: 1), () {
        if (currentEnemies.isNotEmpty) nextTurn();
      });
      return;
    }

    if (isMultiEnemy) {
      final enemyName = getEnemyName(targetEnemy);
    } else {}

    // Consumir recursos
    if (ability.type == AbilityType.ultimate) {
      playerStats.spendUlt();
    } else if (ability.mpCost > 0) {
      playerStats.spendMp(ability.mpCost);
    }

    final enemyStats = (targetEnemy as dynamic).stats as EnemyStats;

    final grossDamage = DamageCalculator.calculateDamage(
      ability: ability,
      attackerAtk: playerStats.effectiveAttack,
      defenderDef: 0,
      critChance: playerStats.critChance.value,
    );

    final enemyDef = enemyStats.defense;
    final estimatedNetDamage = (grossDamage - enemyDef).clamp(1, 999);

    enemyStats.takeDamage(grossDamage);

    playerStats.gainUltCharge(ability.effect.ultGain);

    if (enemyStats.currentHp.value <= 0) {
      _handleEnemyDeath(targetEnemy, enemyStats);
      return;
    }

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

  void _handleEnemyDeath(
      SpriteAnimationComponent enemy, EnemyStats enemyStats) {
    totalXpEarned += enemyStats.xpValue;
    totalGoldEarned += enemyStats.goldDrop;

    final random = Random();
    enemyStats.lootTable.forEach((item, chance) {
      if (random.nextDouble() < chance) {
        game.player.addItem(item);
        lastDroppedItems.add(item);
      }
    });

    if (currentEnemies.isNotEmpty) {
      int index = currentEnemies.indexOf(enemy);
      if (index != -1) {
        if (currentEnemies.length == 1) {
          if (currentBossId != null) {
            game.player.stats.defeatBoss(currentBossId!);
          }
          game.player.stats.gainXp(totalXpEarned);
          game.player.stats.gold.value += totalGoldEarned;
          return;
        }

        _removeDefeatedEnemy(index);
      }
    } else {
      game.player.stats.gainXp(totalXpEarned);
      game.player.stats.gold.value += totalGoldEarned;
      return;
    }
  }

  void enemyUseAbility() {
    if (currentEnemy == null) return;

    final enemyStats = (currentEnemy as dynamic).stats;

    if (enemyStats.currentHp.value <= 0) {
      return;
    }

    final enemyCombatStats =
        (enemyStats is EnemyStats && enemyStats is CombatStatsHolder)
            ? (enemyStats as CombatStatsHolder).combatStats
            : null;

    if (enemyCombatStats == null) {
      game.player.stats.takeDamage(enemyStats.attack);
      if (game.player.stats.currentHp.value == 0) return;
      currentTurn.value = CombatTurn.playerTurn;
      return;
    }

    final enemyType = _getEnemyType();
    final abilities = AbilityDatabase.getEnemyAbilities(enemyType);

    if (abilities.isEmpty) {
      game.player.stats.takeDamage(enemyStats.attack);
      if (game.player.stats.currentHp.value == 0) return;
      currentTurn.value = CombatTurn.playerTurn;
      return;
    }

    final chosenAbility = EnemyAI.chooseAbility(
      abilities: abilities,
      stats: enemyCombatStats,
    );

    if (chosenAbility.type == AbilityType.ultimate) {
      enemyCombatStats.spendUlt();
    } else if (chosenAbility.mpCost > 0) {
      enemyCombatStats.spendMp(chosenAbility.mpCost);
    }

    final grossDamage = DamageCalculator.calculateDamage(
      ability: chosenAbility,
      attackerAtk: enemyCombatStats.effectiveAttack,
      defenderDef: 0,
      critChance: enemyCombatStats.critChance.value,
    );

    final playerDef = game.player.stats.combatStats.effectiveDefense;
    final estimatedNetDamage = (grossDamage - playerDef).clamp(1, 999);

    game.player.stats.takeDamage(grossDamage);

    if (game.player.stats.currentHp.value == 0) {
      return;
    }

    currentTurn.value = CombatTurn.playerTurn;
  }

  String _getEnemyType() {
    if (currentEnemy is GoblinComponent) return 'goblin';
    if (currentEnemy is SlimeComponent) return 'slime';
    if (currentEnemy is BatComponent) return 'bat';
    if (currentEnemy is SkeletonComponent) return 'skeleton';
    return 'slime';
  }

  String getEnemyName(SpriteAnimationComponent enemy) {
    return enemyNames[enemy] ?? 'Enemigo';
  }

  String _getEnemyTypeForComponent(SpriteAnimationComponent enemy) {
    if (enemy is GoblinComponent) return 'goblin';
    if (enemy is SlimeComponent) return 'slime';
    if (enemy is BatComponent) return 'bat';
    if (enemy is SkeletonComponent) return 'skeleton';
    return 'slime'; // fallback
  }

  void _applyGroupScaling() {
    if (currentEnemies.length <= 1) return;

    final scaleFactor = currentEnemies.length == 2 ? 0.7 : 0.6;

    for (final enemy in currentEnemies) {
      final stats = (enemy as dynamic).stats;

      if (stats is EnemyStats) {
        final originalHp = stats.maxHp;
        stats.currentHp.value = (originalHp * scaleFactor).round();
      }

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

  void _removeDefeatedEnemy(int index) {
    if (index >= 0 && index < currentEnemies.length) {
      final enemyToRemove = currentEnemies[index];
      final enemyName = getEnemyName(enemyToRemove);

      game._battleScene?.removeEnemy(index);
      currentEnemies.removeAt(index);

      final queueIndex = turnQueue.indexWhere((e) => e.enemy == enemyToRemove);
      if (queueIndex != -1) {
        turnQueue.removeAt(queueIndex);
        if (queueIndex < currentTurnIndex) {
          currentTurnIndex--;
        }
      }

      if (selectedTargetIndex >= currentEnemies.length &&
          currentEnemies.isNotEmpty) {
        selectedTargetIndex = currentEnemies.length - 1;
      } else if (currentEnemies.isEmpty) {
        selectedTargetIndex = 0;
      }

      if (currentEnemies.isNotEmpty) {
        currentEnemy = currentEnemies[selectedTargetIndex];
      } else {
        currentEnemy = null;
      }
    }
  }

  void cycleTargetNext() {
    if (currentEnemies.isEmpty) return;

    selectedTargetIndex = (selectedTargetIndex + 1) % currentEnemies.length;
    final targetName = getEnemyName(currentEnemies[selectedTargetIndex]);

    final temp = currentTurn.value;
    currentTurn.value = temp;
  }

  void cycleTargetPrevious() {
    if (currentEnemies.isEmpty) return;

    selectedTargetIndex = (selectedTargetIndex - 1 + currentEnemies.length) %
        currentEnemies.length;
    final targetName = getEnemyName(currentEnemies[selectedTargetIndex]);

    final temp = currentTurn.value;
    currentTurn.value = temp;
  }

  void _enemyTakeTurn(SpriteAnimationComponent enemy, int index) {
    final stats = (enemy as dynamic).stats;
    final enemyType = _getEnemyTypeForComponent(enemy);
    final enemyName = getEnemyName(enemy);

    final currentHp = (stats is CombatStatsHolder)
        ? stats.combatStats.currentHp.value
        : (stats is EnemyStats ? stats.currentHp.value : 0);

    if (currentHp <= 0) {
      final allDead = currentEnemies.every((e) {
        final s = (e as dynamic).stats;
        final hp = (s is CombatStatsHolder)
            ? s.combatStats.currentHp.value
            : (s is EnemyStats ? s.currentHp.value : 0);
        return hp <= 0;
      });

      if (allDead) {
        return;
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        nextTurn();
      });
      return;
    }

    final hasCombatStats = stats is CombatStatsHolder;

    if (!hasCombatStats) {
      final rawDamage = stats.attack;
      final playerDef = game.player.stats.defense.value;
      final estimatedNet = (rawDamage - playerDef).clamp(1, 999);

      game.player.stats.takeDamage(rawDamage);

      Future.delayed(const Duration(seconds: 1), () {
        nextTurn();
      });
      return;
    }
    final combatStats = (stats as CombatStatsHolder).combatStats;
    final abilities = AbilityDatabase.getEnemyAbilities(enemyType);

    if (abilities.isEmpty) {
      game.player.stats.takeDamage(combatStats.attack.value);
      return;
    }

    final chosenAbility = EnemyAI.chooseAbility(
      abilities: abilities,
      stats: combatStats,
    );

    if (chosenAbility.type == AbilityType.ultimate) {
      combatStats.spendUlt();
    } else if (chosenAbility.mpCost > 0) {
      combatStats.spendMp(chosenAbility.mpCost);
    }

    if (chosenAbility.name == 'Guardia') {
      combatStats.applyEffect(StatusEffect.defenseBuffStrong());
    } else if (chosenAbility.effect.statusEffects.isNotEmpty) {
      for (final effect in chosenAbility.effect.statusEffects) {
        if (chosenAbility.effect.targetType == TargetType.self) {
          combatStats.applyEffect(effect);
        } else {
          game.player.stats.combatStats.applyEffect(effect);
        }
      }
    }

    final isOffensive = chosenAbility.effect.targetType != TargetType.self &&
        chosenAbility.effect.baseDamage > 0;

    if (isOffensive) {
      final grossDamage = DamageCalculator.calculateDamage(
        ability: chosenAbility,
        attackerAtk: combatStats.effectiveAttack,
        defenderDef: 0,
        critChance: combatStats.critChance.value,
      );

      final playerDef = game.player.stats.combatStats.effectiveDefense;
      final estimatedNetDamage = (grossDamage - playerDef).clamp(1, 999);

      game.player.stats.takeDamage(grossDamage);
    } else {}

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

  final Map<String, PortalData> portals = {};
  String currentMapName = 'cemetery.tmx';
  static const int MIN_STEPS_BETWEEN_BATTLES = 10;
  int stepsSinceLastBattle = 0;
  final List<Rect> spawnZoneRects = [];
  final Map<int, ZoneProperties> zonePropertiesMap = {};
  ZoneProperties? currentZone;
  final Set<String> discoveredZones = {};
  final List<ConditionalBarrier> conditionalBarriers = [];
  final Set<String> openedChests = {};
  final List<BossTriggerData> bossTriggers = [];

  final Map<String, NPC> npcs = {};
  List<NPCComponent> npcComponents = [];
  String? activeDialogueNPC;

  late final IAPService iapService;
  late final AdService adService;

  final Set<math.Point<int>> exploredTiles = {};
  final ValueNotifier<String> currentZoneNameNotifier =
      ValueNotifier<String>('Unknown Zone');
  final ValueNotifier<int> currentDangerLevelNotifier = ValueNotifier<int>(1);
  static const int explorationRadius = 5;

  final videoPlayerControllerNotifier =
      ValueNotifier<VideoPlayerController?>(null);
  final currentBackgroundNotifier = ValueNotifier<String?>(null);

  int currentSlotIndex = 1;
  bool isNewGameFlag = true;
  int introNavigationCount = 0;
  final OfflineStorageService offlineStorage;
  final AuthService authService;

  RenegadeDungeonGame({
    required this.offlineStorage,
    required this.authService,
  });

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
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
          saveGame();
        }
      }
    }

    await FlameAudio.audioCache.loadAll([
      'menu_music.ogg',
      'dungeon_music.ogg',
    ]);
    iapService = IAPService(onGemsPurchased: (amount) {
      player.stats.gems.value += amount;
      saveGame();
    });

    try {
      await iapService.initialize();
    } catch (e) {}

    adService = AdService();
    try {
      await adService.initialize();
    } catch (e) {}

    combatManager = CombatManager(this);

    add(
      router = RouterComponent(
        initialRoute: 'splash-screen',
        routes: {
          'splash-screen': Route(SplashScreen.new),
          'main-menu': Route(
              () => MenuRouteComponent('MainMenu', 'menu_background.mp4')),
          'intro-screen': Route(IntroRouteComponent.new),
          'loading-screen': Route(LoadingRouteComponent.new),
          'game-screen': Route(GameScreen.new),
        },
      ),
    );

    playMenuMusic();
  }

  Future<void> playMenuMusic() async {
    try {
      if (!FlameAudio.bgm.isPlaying) {
        FlameAudio.bgm.stop();
        await FlameAudio.bgm.play('menu_music.ogg');
      }
    } catch (e) {}
  }

  Future<void> playWorldMusic() async {
    try {
      FlameAudio.bgm.stop();
      await FlameAudio.bgm.play('dungeon_music.ogg');
    } catch (e) {}
  }

  void stopMusic() {
    try {
      FlameAudio.bgm.stop();
    } catch (e) {}
  }

  Future<bool> loadGameData() async {
    _clearSessionState();

    final saveData = offlineStorage.loadLocally(currentSlotIndex);

    String mapToLoad = 'cemetery.tmx';
    if (saveData != null) {
      mapToLoad = saveData.currentMap;
    }

    try {
      try {
        if (world.contains(mapComponent)) {
          world.remove(mapComponent);
        }
      } catch (e) {
        // mapComponent not initialized yet, nothing to remove
      }

      mapComponent =
          await TiledComponent.load(mapToLoad, Vector2(tileWidth, tileHeight));
      currentMapName = mapToLoad;
    } catch (e, stack) {
      mapComponent = await TiledComponent.load(
          'dungeon.tmx', Vector2(tileWidth, tileHeight));
      currentMapName = 'dungeon.tmx';
    }

    loadZoneData();
    collisionLayer = mapComponent.tileMap.getLayer<TileLayer>('Collision')!;
    collisionLayer.visible = false;
    _loadPortals();
    _loadSpawnZones();
    _loadConditionalBarriers();
    _loadBossTriggers();
    await _loadChests();
    _loadNPCs();

    if (saveData != null) {
      player = Player(
        gridPosition: Vector2(saveData.gridX, saveData.gridY),
      );

      accumulatedPlaytime = saveData.playtimeSeconds.toDouble();
      sessionCreatedAt = saveData.createdAt;

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

      discoveredZones.addAll(saveData.discoveredMaps);
      openedChests.addAll(saveData.openedChests);
      player.stats.defeatedBosses.addAll(saveData.defeatedBosses);

      final loadedInventory = <InventorySlot>[];
      for (final slotData in saveData.inventory) {
        final item = ItemDatabase.getItemById(slotData.itemId);
        if (item != null) {
          loadedInventory
              .add(InventorySlot(item: item, quantity: slotData.quantity));
        }
      }
      player.inventory.value = loadedInventory;

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
      Vector2 startPos = Vector2(40.0, 42.0); // Fallback

      final objectLayer = mapComponent.tileMap.getLayer<ObjectGroup>('Setup');
      if (objectLayer != null) {
        final startObj = objectLayer.objects.firstWhere(
          (obj) => obj.name == 'PlayerStart',
          orElse: () => TiledObject(id: -1),
        );
        if (startObj.id != -1) {
          startPos = screenToGridPosition(Vector2(startObj.x, startObj.y));
        }
      }

      if (startPos == Vector2(40.0, 42.0)) {
        final altLayer = mapComponent.tileMap.getLayer<ObjectGroup>('Objects');
        if (altLayer != null) {
          final startObj = altLayer.objects.firstWhere(
            (obj) => obj.name == 'PlayerStart',
            orElse: () => TiledObject(id: -1),
          );
          if (startObj.id != -1) {
            startPos = screenToGridPosition(Vector2(startObj.x, startObj.y));
          }
        }
      }

      player = Player(gridPosition: startPos);

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

        overlays.add('barrier_dialog');
        _currentBarrierMessage = 'Partida Guardada';
        _currentBarrierIsBlocked = false;

        Future.delayed(const Duration(seconds: 2), () {
          if (_currentBarrierMessage == 'Partida Guardada') {
            overlays.remove('barrier_dialog');
          }
        });
      } catch (e) {}

      isPlayerReady = true;
      isPlayerReadyNotifier.value = true;

      return true;
    }
  }

  Future<void> saveGame() async {
    if (!isPlayerReady) return;

    if (currentSlotIndex < 1 || currentSlotIndex > 3) {
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
      await offlineStorage.saveLocally(currentSlotIndex, data);
    } catch (e) {}
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

    combatManager.startNewCombatMulti([enemyType]);
    _battleScene = BattleScene(enemies: combatManager.currentEnemies);
    await add(_battleScene!);
    overlays.add('CombatUI');
    await screenFade.fadeIn();
  }

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
    combatManager.startBossCombat(bossId, enemyType);

    _battleScene = BattleScene(enemies: combatManager.currentEnemies);
    await add(_battleScene!);
    overlays.add('CombatUI');
    await screenFade.fadeIn();
  }

  void endCombat({bool? playerWon}) {
    final bool didPlayerWin = playerWon ?? (player.stats.currentHp.value > 0);

    if (!didPlayerWin) {
      player.stats.currentHp.value = player.stats.maxHp.value;
      player.stats.currentMp.value = player.stats.maxMp.value;

      player.stats.combatStats.currentHp.value = player.stats.currentHp.value;
      player.stats.combatStats.currentMp.value = player.stats.currentMp.value;

      if (portals.isNotEmpty) {
        final portal = portals.values.first;
        player.gridPosition = portal.gridPosition + Vector2(5, 0);
      } else {
        player.gridPosition = Vector2(5.0, 5.0);
      }
      player.position = gridToScreenPosition(player.gridPosition);

      Future.delayed(const Duration(milliseconds: 500), () {});

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

    if (combatManager.currentBossId != null) {
      player.stats.defeatBoss(combatManager.currentBossId!);
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
      state = GameState.exploring;
      overlays.remove('PauseMenuUI');
    } else if (state == GameState.exploring) {
      state = GameState.inMenu;
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
    if (state == GameState.inCombat) {
      return KeyEventResult.handled;
    }
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (state == GameState.exploring || state == GameState.inCombat) {
      if (!overlays.isActive('PlayerHud')) {
        overlays.add('PlayerHud');
      }
    }

    if (state == GameState.exploring || state == GameState.inCombat) {
      accumulatedPlaytime += dt;
    }

    if (!isPlayerReady) return;

    if (state == GameState.exploring) {
      if (player.isMounted) {
        updateExploration(player.position);
        checkZoneTransition(player.position);
        checkRandomEncounter();
        checkBossTriggerCollision(player.gridPosition);

        if (DateTime.now().millisecondsSinceEpoch % 2000 < 20) {}
      }
    }
  }

  void _loadPortals() {
    portals.clear();
    final portalsLayer = mapComponent.tileMap.getLayer<ObjectGroup>('Portals');
    if (portalsLayer == null) {
      return;
    }

    const double scaleFactor = 2.0;
    for (final obj in portalsLayer.objects) {
      final gridX = (obj.x / 16.0).floor();
      final gridY = (obj.y / 16.0).floor();
      final zoneWidthGrid = ((obj.width * scaleFactor) / tileWidth).ceil();
      final zoneHeightGrid = ((obj.height * scaleFactor) / tileHeight).ceil();
      final zoneSize = Vector2(
        zoneWidthGrid.toDouble().clamp(1.0, 100.0),
        zoneHeightGrid.toDouble().clamp(1.0, 100.0),
      );

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

        final zoneCenterGrid = gridPos + (zoneSize / 2);
        final visualPos = gridToScreenPosition(zoneCenterGrid);

        bool visualExists = world.children
            .whereType<PortalVisual>()
            .any((v) => v.position.distanceTo(visualPos) < 1.0);

        if (!visualExists) {
          final portalVisual = PortalVisual(position: visualPos);
          world.add(portalVisual);
        }
      }
    }
  }

  void checkPortalCollision(Vector2 playerGridPos) {
    for (final portal in portals.values) {
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
    overlays.remove('PlayerHud');
    if (transitionType == 'fade') {
      final screenFade = ScreenFade();
      camera.viewport.add(screenFade);
      final fadeOutDuration = (duration / 2) / 1000;
      await screenFade.fadeOut(duration: fadeOutDuration);
      try {
        await _performMapTransition(mapName, startPos);
        await screenFade.fadeIn(duration: fadeOutDuration);
      } catch (e, stackTrace) {
        screenFade.removeFromParent();
      }
    } else if (transitionType == 'instant') {
      try {
        await _performMapTransition(mapName, startPos);
      } catch (e) {}
    } else {
      return transitionToMap(mapName, startPos,
          transitionType: 'fade', duration: duration);
    }
    overlays.add('PlayerHud');
    saveGame();
  }

  Future<void> _performMapTransition(String mapName, Vector2 startPos) async {
    try {
      if (mapComponent.parent != null) {
        mapComponent.removeFromParent();
      }

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
      _loadConditionalBarriers();
      _loadBossTriggers();
      await _loadChests();
      player.gridPosition = startPos;
      player.position = gridToScreenPosition(startPos);
      stepsSinceLastBattle = 0;
      exploredTiles.clear();
      updateExploration(player.gridPosition);
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  void _loadSpawnZones() {
    spawnZoneRects.clear();
    zonePropertiesMap.clear();
    currentZone = null;

    final zonesLayer = mapComponent.tileMap.getLayer<ObjectGroup>('SpawnZones');
    if (zonesLayer == null) {
      return;
    }
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
  }

  void _loadConditionalBarriers() {
    conditionalBarriers.clear();
    final barriersLayer =
        mapComponent.tileMap.getLayer<ObjectGroup>('ConditionalBarriers');
    if (barriersLayer == null) {
      return;
    }
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
              'No puedes pasar aún.',
          unlockedMessage: obj.properties.getValue<String>('unlockedMessage'),
        );

        conditionalBarriers.add(barrier);
      } catch (e) {}
    }
  }

  void _loadBossTriggers() {
    bossTriggers.clear();
    final objectLayers =
        mapComponent.tileMap.map.layers.whereType<ObjectGroup>();

    if (objectLayers.isEmpty) {
      return;
    }

    int triggersFound = 0;

    for (final layer in objectLayers) {
      for (final obj in layer.objects) {
        if (obj.name == 'BossTrigger') {
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
          triggersFound++;
        }
      }
    }

    if (triggersFound == 0) {
    } else {}
  }

  void checkBossTriggerCollision(Vector2 playerGridPos) {
    if (bossTriggers.isNotEmpty && currentMapName.contains('boss_area')) {}

    for (int i = 0; i < bossTriggers.length; i++) {
      final trigger = bossTriggers[i];
      if (!trigger.rect.contains(playerGridPos.toOffset())) {
        if (trigger.triggered) {
          trigger.triggered = false;
        }
        continue;
      }
      if (trigger.triggered) continue;
      if ((trigger.rect.center - playerGridPos.toOffset()).distance < 5.0) {}
      if (trigger.rect.contains(playerGridPos.toOffset())) {
        if (player.stats.defeatedBosses.contains(trigger.bossId)) {
          trigger.triggered = true;
          continue;
        }
        trigger.triggered = true;
        startBossBattle(trigger.bossId, trigger.enemyType);
        break;
      }
    }
  }

  bool canPassBarrier(Vector2 targetGridPosition) {
    final mapX = targetGridPosition.x * tileWidth;
    final mapY = targetGridPosition.y * tileWidth;

    for (final barrier in conditionalBarriers) {
      final barrierBounds = barrier.getBounds();

      if (barrierBounds.contains(Offset(mapX, mapY))) {
        if (barrier.isPermanentlyUnlocked) {
          continue;
        }

        if (barrier.requiredLevel > 0) {
          if (player.stats.level.value < barrier.requiredLevel) {
            overlays.add('barrier_dialog');
            _currentBarrierMessage = barrier.blockedMessage;
            _currentBarrierIsBlocked = true;
            return false;
          }
        }

        if (barrier.requiredBoss != 'none' &&
            !player.stats.hasBossBeenDefeated(barrier.requiredBoss)) {
          if (barrier.requiredQuest != 'none' &&
              !player.stats.hasQuestBeenCompleted(barrier.requiredQuest)) {
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
    final dx = screenPos.x - originX;
    final dy = screenPos.y - (tileHeight / 2);
    final A = dx / halfW;
    final B = dy / halfH;

    final gridX = (B + A) / 2;
    final gridY = (B - A) / 2;

    return Vector2(gridX, gridY);
  }

  ZoneProperties? _getZoneAt(Vector2 worldPos) {
    final gridPos = screenToGridPosition(worldPos);
    final mapX = gridPos.x * tileWidth;
    final mapY = gridPos.y * tileWidth;
    for (int i = 0; i < spawnZoneRects.length; i++) {
      if (spawnZoneRects[i].contains(Offset(mapX, mapY))) {
        return zonePropertiesMap[i];
      }
    }
    return null;
  }

  void checkZoneTransition(Vector2 playerWorldPos) {
    final newZone = _getZoneAt(playerWorldPos);
    if (newZone?.name != currentZone?.name) {
      currentZone = newZone;
      if (newZone != null) {
        if (!discoveredZones.contains(newZone.name)) {
          discoveredZones.add(newZone.name);
        }
        currentDangerLevelNotifier.value = newZone.dangerLevel.index;
        currentZoneNameNotifier.value = newZone.name;
        saveGame();
      } else {
        currentDangerLevelNotifier.value = 0;
        currentZoneNameNotifier.value = 'Safe Area';
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

    stepsSinceLastBattle = 0;
    final random = Random();

    // Always single enemy combat
    final enemyType =
        currentZone!.enemyTypes[random.nextInt(currentZone!.enemyTypes.length)];
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

      final chestId = '$currentMapName:$gridX,$gridY';

      if (openedChests.contains(chestId)) continue;

      InventoryItem itemForThisChest;
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
  }

  // ========== NPC SYSTEM ==========

  void _loadNPCs() {
    npcs.clear();
    for (final npc in npcComponents) {
      npc.removeFromParent();
    }
    npcComponents.clear();

    final npcsLayer = mapComponent.tileMap.getLayer<ObjectGroup>('NPCs');
    if (npcsLayer == null) {
      return;
    }

    for (final obj in npcsLayer.objects) {
      final id = obj.properties.getValue<String>('npcId') ?? 'npc_${obj.id}';
      final name = obj.properties.getValue<String>('name') ?? 'NPC';
      final typeStr = obj.properties.getValue<String>('npcType') ?? 'generic';
      final type = _parseNPCType(typeStr);
      final spriteSheet = obj.properties.getValue<String>('spriteSheet') ??
          'characters/player.png';
      final dialogue = obj.properties.getValue<String>('dialogue') ?? 'Hola.';

      final gridX = (obj.x / 16.0).floor();
      final gridY = (obj.y / 16.0).floor();
      final gridPos = Vector2(gridX.toDouble(), gridY.toDouble());
      final npc = NPC(
        id: id,
        name: name,
        type: type,
        gridPosition: gridPos,
        spriteSheet: spriteSheet,
        dialogue: dialogue,
      );

      npcs[id] = npc;
      final npcComponent = NPCComponent(npc: npc);
      npcComponents.add(npcComponent);
      world.add(npcComponent);
    }
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
        startDialogue(npcComponent.npc.id);
        return;
      }
    }
  }

  void startDialogue(String npcId) {
    final npc = npcs[npcId];
    if (npc == null) return;

    activeDialogueNPC = npcId;
    state = GameState.inMenu; // Pause game
    overlays.add('DialogueUI');
  }

  void endDialogue() {
    if (activeDialogueNPC != null) {}

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

    if (player.isMounted) updateExploration(player.gridPosition);
    player.move(direction);
  }

  String _currentBarrierMessage = '';
  bool _currentBarrierIsBlocked = true;

  String get currentBarrierMessage => _currentBarrierMessage;
  bool get currentBarrierIsBlocked => _currentBarrierIsBlocked;

  Future<void> playBackgroundVideo(String asset) async {
    try {
      currentBackgroundNotifier.value = asset;

      if (videoPlayerControllerNotifier.value?.dataSource ==
          'assets/videos/$asset') {
        return;
      }

      if (videoPlayerControllerNotifier.value != null) {
        await stopBackgroundVideo();
        currentBackgroundNotifier.value = asset;
      }

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        videoPlayerControllerNotifier.value = null;
        return;
      }

      final controller = VideoPlayerController.asset('assets/videos/$asset');
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();
      videoPlayerControllerNotifier.value = controller;
    } catch (e) {
      if (videoPlayerControllerNotifier.value != null) {
        videoPlayerControllerNotifier.value = null;
      }
    }
  }

  Future<void> stopBackgroundVideo() async {
    try {
      if (videoPlayerController != null) {
        await videoPlayerController!.dispose();
        videoPlayerController = null;
      }
      videoPlayerControllerNotifier.value = null;
      currentBackgroundNotifier.value = null; // Clear static background too
    } catch (e) {}
  }

  void clearWorld() {
    try {
      if (world.contains(mapComponent)) {
        mapComponent.removeFromParent();
      }
    } catch (e) {
      // mapComponent not initialized yet (first load), skip
    }
    try {
      if (isPlayerReady && world.contains(player)) {
        player.removeFromParent();
      }
    } catch (e) {
      // player not initialized yet (first load), skip
    }
    final chests = world.children.whereType<Chest>().toList();
    for (final chest in chests) {
      chest.removeFromParent();
    }
    for (final npc in npcComponents) {
      npc.removeFromParent();
    }
    if (npcComponents.isNotEmpty) npcComponents.clear();
    npcs.clear();
    final portals = world.children.whereType<PortalVisual>().toList();
    for (final portal in portals) {
      portal.removeFromParent();
    }
    isPlayerReadyNotifier.value = false;
    currentZone = null;
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
    bool isMobile = false;
    if (!kIsWeb) {
      try {
        isMobile = Platform.isAndroid || Platform.isIOS;
      } catch (e) {}
    }

    if (isMobile) {
      videoPlayerControllerNotifier.value = null;
      return;
    }

    try {
      if (videoPlayerController != null) {
        await videoPlayerController!.dispose();
      }

      currentBackgroundNotifier.value = asset;
      videoPlayerController =
          VideoPlayerController.asset('assets/videos/$asset');
      await videoPlayerController!.initialize();
      videoPlayerController!.setLooping(true);
      videoPlayerController!.setVolume(0.0);
      await videoPlayerController!.play();
      videoPlayerControllerNotifier.value = videoPlayerController;
    } catch (e) {
      videoPlayerControllerNotifier.value = null;
    }
  }

  void _clearSessionState() {
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
  }

  void openGemShop() {
    state = GameState.inMenu;
    overlays.add('GemShop');
  }

  void onPlayerDeath() async {
    try {
      await adService.showInterstitial();
    } catch (e) {}
    overlays.add('ReviveDialog');
  }

  Future<void> handleRevive() async {
    if (player.stats.gems.value >= 25) {
      player.stats.gems.value -= 25;
      overlays.remove('ReviveDialog');
      await Future.delayed(const Duration(milliseconds: 50));
      final maxHp = player.stats.maxHp.value;
      player.stats.currentHp.value = maxHp;
      player.stats.combatStats.currentHp.value = maxHp;
    }
  }

  void handleNormalDeath() {
    player.stats.gold.value = (player.stats.gold.value * 0.25).floor();
    player.stats.currentHp.value = player.stats.maxHp.value;
    endCombat(playerWon: false);
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
