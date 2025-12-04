
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/components/emote_component.dart';
import 'package:flutter/foundation.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/models/player_stats.dart';
import 'chest.dart';

class Player extends SpriteComponent
    with
        HasGameReference<RenegadeDungeonGame>,
        KeyboardHandler,
        CollisionCallbacks {
  Vector2 gridPosition;
  late final PlayerStats stats;
  final inventory = ValueNotifier<List<InventorySlot>>([]);
  final positionNotifier = ValueNotifier<Vector2>(Vector2.zero());

  double _moveCooldown = 0.0;
  static const double moveCooldownDuration = 0.15;
  bool isMoving = false;
  bool isDead = false;

  late Sprite spriteUp;
  late Sprite spriteDown;
  late Sprite spriteLeft;
  late Sprite spriteRight;
  String currentDirection = 's';

  Player({required this.gridPosition})
      : super(size: Vector2(64, 46), anchor: Anchor(0.5, 1)) {
    stats = PlayerStats(
      initialLevel: 1,
      initialMaxHp: 20,
      initialMaxMp: 10,
      initialAttack: 12,
      initialDefense: 5,
    );
    stats.player = this;
  }

  @override
  Future<void> onLoad() async {

    spriteUp = await game.loadSprite('characters/player_w.png');
    spriteDown = await game.loadSprite('characters/player_s.png');
    spriteLeft = await game.loadSprite('characters/player_a.png');
    spriteRight = await game.loadSprite('characters/player_d.png');

    sprite = spriteDown;

    position = game.gridToScreenPosition(gridPosition);
    positionNotifier.value = gridPosition;
    priority = 10;


    final hitboxSize = Vector2(10, 10);
    add(RectangleHitbox(
      size: hitboxSize,
      position: Vector2((size.x - hitboxSize.x) / 2, size.y - hitboxSize.y),
    ));
    return super.onLoad();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Chest) {
      if (other.isCollected) {
        return;
      }

      other.isCollected = true;

      addItem(other.item);

      if (Random().nextDouble() < 0.20) {
        final gemsFound = Random().nextInt(3) + 1;
        stats.gems.value += gemsFound;

      }

      final chestId =
          '${game.currentMapName}:${other.gridPosition.x.toInt()},${other.gridPosition.y.toInt()}';
      game.openedChests.add(chestId);

      other.removeFromParent();
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (game.state != GameState.exploring) {
      return true;
    }

    if (event is KeyDownEvent &&
        keysPressed.contains(LogicalKeyboardKey.keyE)) {
      game.checkNPCInteraction();
      return true;
    }

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.state != GameState.exploring) {
      return;
    }

    if (_moveCooldown > 0) {
      _moveCooldown -= dt;
      return;
    }

    if (isMoving) return;

    final keysPressed = HardwareKeyboard.instance.logicalKeysPressed;
    final moveDirection = Vector2.zero();

    if (keysPressed.contains(LogicalKeyboardKey.keyW)) moveDirection.y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyS)) moveDirection.y += 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyA)) moveDirection.x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyD)) moveDirection.x += 1;

    if (moveDirection.x.abs() + moveDirection.y.abs() > 1) {
      if (moveDirection.y != 0) {
        moveDirection.x = 0;
      } else {
        moveDirection.y = 0;
      }
    }

    if (!moveDirection.isZero()) {
      _updateSpriteDirection(moveDirection);
      move(moveDirection);
      _moveCooldown = moveCooldownDuration;
    }
  }

  /// Update player sprite based on movement direction
  void _updateSpriteDirection(Vector2 direction) {
    if (direction.y < 0) {
      sprite = spriteUp;
      currentDirection = 'w';
    } else if (direction.y > 0) {
      sprite = spriteDown;
      currentDirection = 's';
    } else if (direction.x < 0) {
      sprite = spriteLeft;
      currentDirection = 'a';
    } else if (direction.x > 0) {
      sprite = spriteRight;
      currentDirection = 'd';
    }
  }

  void move(Vector2 direction) async {
    _updateSpriteDirection(direction);

    final targetGridPosition = gridPosition + direction;

    if (!game.canPassBarrier(targetGridPosition)) {
      return;
    }

    if (!_hasCollision(targetGridPosition)) {
      isMoving = true;

      gridPosition = targetGridPosition;
      final targetScreenPos = game.gridToScreenPosition(gridPosition);

      final startPos = position.clone();
      final midPos = Vector2(
        (startPos.x + targetScreenPos.x) / 2,
        (startPos.y + targetScreenPos.y) / 2,
      );

      const animDuration = 0.12;
      double elapsed = 0.0;

      while (elapsed < animDuration / 2) {
        await Future.delayed(const Duration(milliseconds: 16));
        elapsed += 0.016;
        final t = (elapsed / (animDuration / 2)).clamp(0.0, 1.0);
        position = startPos + (midPos - startPos) * t;
      }

      elapsed = 0.0;
      while (elapsed < animDuration / 2) {
        await Future.delayed(const Duration(milliseconds: 16));
        elapsed += 0.016;
        final t = (elapsed / (animDuration / 2)).clamp(0.0, 1.0);
        position = midPos + (targetScreenPos - midPos) * t;
      }

      position = targetScreenPos;
      isMoving = false;

      game.stepsSinceLastBattle++;
      game.checkPortalCollision(gridPosition);
      game.checkZoneTransition(position);
      game.checkRandomEncounter();
    }
  }

  void _checkForEncounter() {
    if (!game.zoneHasEnemies) {
      return;
    }
    final randomValue = Random().nextDouble();
    double cumulativeChance = 0.0;
    for (int i = 0; i < game.zoneEnemyTypes.length; i++) {
      cumulativeChance += game.zoneEnemyChances[i];
      if (randomValue < cumulativeChance) {
        final enemyType = game.zoneEnemyTypes[i];
        game.startCombat(enemyType);
        return;
      }
    }
  }

  bool _hasCollision(Vector2 targetGridPos) {
    final mapWidth = game.mapComponent.tileMap.map.width;
    final mapHeight = game.mapComponent.tileMap.map.height;
    if (targetGridPos.x < 0 ||
        targetGridPos.x >= mapWidth ||
        targetGridPos.y < 0 ||
        targetGridPos.y >= mapHeight) {
      return true;
    }
    final tileData = game.collisionLayer.data;
    if (tileData == null) {
      return false;
    }
    final tileIndex =
        targetGridPos.y.toInt() * mapWidth + targetGridPos.x.toInt();
    if (tileIndex < 0 || tileIndex >= tileData.length) {
      return true;
    }
    return tileData[tileIndex] != 0;
  }

  void showSurpriseEmote() {
    add(EmoteComponent());
  }

  void addItem(InventoryItem itemToAdd) {
    final existingSlotIndex = inventory.value.indexWhere(
      (slot) => slot.item.id == itemToAdd.id,
    );
    if (existingSlotIndex != -1) {
      inventory.value[existingSlotIndex].quantity++;
    } else {
      inventory.value.add(InventorySlot(item: itemToAdd));
    }
    inventory.notifyListeners();
  }

  void useItem(InventorySlot slot) {
    slot.item.effect(game);
    slot.quantity--;
    if (slot.quantity <= 0) {
      inventory.value.remove(slot);
    }
    inventory.notifyListeners();
  }

  void equipItem(InventorySlot slot) {
    if (slot.item is! EquipmentItem) {
      return;
    }
    final equipmentItem = slot.item as EquipmentItem;
    stats.equipItem(equipmentItem);
    slot.quantity--;
    if (slot.quantity <= 0) {
      inventory.value.remove(slot);
    }
    inventory.notifyListeners();
  }

  void unequipItem(EquipmentSlot slot) {
    stats.unequipItem(slot);
  }
}
