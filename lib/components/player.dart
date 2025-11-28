// lib/components/player.dart

import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/components/emote_component.dart';
import 'package:flutter/foundation.dart'; // ¡Necesario para ValueNotifier!
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/models/player_stats.dart';
import 'package:flutter/services.dart';
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

  // NEW: Movement system
  double _moveCooldown = 0.0;
  static const double moveCooldownDuration = 0.15; // 150ms entre movimientos
  bool isMoving = false;
  bool isDead = false; // Death/revive system flag

  // NEW: Directional sprites
  late Sprite spriteUp; // W
  late Sprite spriteDown; // S
  late Sprite spriteLeft; // A
  late Sprite spriteRight; // D
  String currentDirection = 's'; // Default facing down

  Player({required this.gridPosition})
      : super(
            size: Vector2(64, 46),
            anchor: Anchor(0.5, 1)); // Custom anchor: centered X, 70% down Y

  @override
  Future<void> onLoad() async {
    stats = PlayerStats(
      initialLevel: 1,
      initialMaxHp: 20,
      initialMaxMp: 10,
      initialAttack: 12,
      initialDefense: 5,
    );
    stats.player = this;
    addItem(ItemDatabase.rustySword);
    addItem(ItemDatabase.leatherTunic);

    // Load all directional sprites
    spriteUp = await game.loadSprite('characters/player_w.png');
    spriteDown = await game.loadSprite('characters/player_s.png');
    spriteLeft = await game.loadSprite('characters/player_a.png');
    spriteRight = await game.loadSprite('characters/player_d.png');

    // Set default sprite (facing down)
    sprite = spriteDown;

    position = game.gridToScreenPosition(gridPosition);
    positionNotifier.value = gridPosition;
    priority = 10; // ← Render encima de map layers

    // DEBUG: Show collision hitbox
    debugMode = true;

    final hitboxSize = Vector2(10, 10); // Scaled proportionally
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
      // --- ¡LA LÓGICA DE PROTECCIÓN! ---
      // 1. Preguntamos: "¿Este cofre ya ha sido recogido?".
      if (other.isCollected) {
        // Si la respuesta es sí, no hacemos NADA. Salimos del método.
        return;
      }

      // 2. Si llegamos aquí, significa que el cofre no ha sido recogido.
      // Lo PRIMERO que hacemos es marcarlo como recogido para que nadie más pueda hacerlo.
      other.isCollected = true;

      // 3. Ahora, y solo ahora, ejecutamos la lógica de forma segura.
      print('¡Cofre recogido en ${other.gridPosition} por colisión!');
      addItem(other.item);

      // Track this chest as opened in game state
      final chestId =
          '${game.currentMapName}:${other.gridPosition.x.toInt()},${other.gridPosition.y.toInt()}';
      game.openedChests.add(chestId);
      print('Chest $chestId marked as opened');

      // 4. Finalmente, lo mandamos a la cola de eliminación.
      other.removeFromParent();
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (game.state != GameState.exploring) {
      return true;
    }

    // NPC Interaction with E key
    if (event is KeyDownEvent &&
        keysPressed.contains(LogicalKeyboardKey.keyE)) {
      game.checkNPCInteraction();
      return true;
    }

    // Movement is now handled in update() for continuous movement
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // NEW: Block movement during combat transitions
    if (game.state != GameState.exploring) {
      return; // Don't process any movement
    }

    // Update cooldown
    if (_moveCooldown > 0) {
      _moveCooldown -= dt;
      return; // Still in cooldown, skip movement
    }

    // Don't process movement if already animating
    if (isMoving) return;

    // Get current pressed keys
    final keysPressed = HardwareKeyboard.instance.logicalKeysPressed;
    final moveDirection = Vector2.zero();

    if (keysPressed.contains(LogicalKeyboardKey.keyW)) moveDirection.y -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyS)) moveDirection.y += 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyA)) moveDirection.x -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyD)) moveDirection.x += 1;

    // Priority: vertical over horizontal
    if (moveDirection.x.abs() + moveDirection.y.abs() > 1) {
      if (moveDirection.y != 0) {
        moveDirection.x = 0;
      } else {
        moveDirection.y = 0;
      }
    }

    if (!moveDirection.isZero()) {
      // Update sprite based on movement direction
      _updateSpriteDirection(moveDirection);
      move(moveDirection);
      _moveCooldown = moveCooldownDuration; // Set cooldown
    }
  }

  /// Update player sprite based on movement direction
  void _updateSpriteDirection(Vector2 direction) {
    // Priority: vertical movement over horizontal (matches movement priority)
    if (direction.y < 0) {
      // Moving up (W)
      sprite = spriteUp;
      currentDirection = 'w';
    } else if (direction.y > 0) {
      // Moving down (S)
      sprite = spriteDown;
      currentDirection = 's';
    } else if (direction.x < 0) {
      // Moving left (A)
      sprite = spriteLeft;
      currentDirection = 'a';
    } else if (direction.x > 0) {
      // Moving right (D)
      sprite = spriteRight;
      currentDirection = 'd';
    }
  }

  void move(Vector2 direction) async {
    final targetGridPosition = gridPosition + direction;

    // NEW: Check if blocked by conditional barrier
    if (!game.canPassBarrier(targetGridPosition)) {
      return; // Movement blocked by barrier
    }

    if (!_hasCollision(targetGridPosition)) {
      isMoving = true;

      // Update grid position
      gridPosition = targetGridPosition;
      final targetScreenPos = game.gridToScreenPosition(gridPosition);

      // Smooth horizontal animation (no vertical hop to keep hitbox stable)
      final startPos = position.clone();
      final midPos = Vector2(
        (startPos.x + targetScreenPos.x) / 2,
        (startPos.y + targetScreenPos.y) / 2, // NO hop - keep hitbox stable
      );

      const animDuration = 0.12; // 120ms animation
      double elapsed = 0.0;

      // Animate to mid-point (hop up)
      while (elapsed < animDuration / 2) {
        await Future.delayed(const Duration(milliseconds: 16)); // ~60fps
        elapsed += 0.016;
        final t = (elapsed / (animDuration / 2)).clamp(0.0, 1.0);
        position = startPos + (midPos - startPos) * t;
      }

      // Animate to target (hop down)
      elapsed = 0.0;
      while (elapsed < animDuration / 2) {
        await Future.delayed(const Duration(milliseconds: 16));
        elapsed += 0.016;
        final t = (elapsed / (animDuration / 2)).clamp(0.0, 1.0);
        position = midPos + (targetScreenPos - midPos) * t;
      }

      position = targetScreenPos; // Ensure exact position
      isMoving = false;

      // Portal & Zone system
      game.stepsSinceLastBattle++;
      game.checkPortalCollision(gridPosition);
      game.checkZoneTransition(position);
      game.checkRandomEncounter();
    }
  }

  void _checkForEncounter() {
    // 1. Primero, comprueba si en esta zona puede haber enemigos
    if (!game.zoneHasEnemies) {
      return; // No hay encuentros aquí, sal del método
    }

    // 2. Genera un número aleatorio
    final randomValue = Random().nextDouble();
    double cumulativeChance = 0.0;

    // 3. Itera sobre los posibles enemigos de la zona
    for (int i = 0; i < game.zoneEnemyTypes.length; i++) {
      cumulativeChance += game.zoneEnemyChances[i];

      if (randomValue < cumulativeChance) {
        final enemyType = game.zoneEnemyTypes[i];
        print('¡Encuentro aleatorio con $enemyType!');
        game.startCombat(enemyType); // Inicia el combate con ese enemigo
        return; // Sal del bucle y del método una vez que se encuentra un enemigo
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
    // Añade el emote como un hijo del jugador.
    // Se posicionará relativo al ancla del jugador.
    add(EmoteComponent());
  }

  void addItem(InventoryItem itemToAdd) {
    // Buscamos si ya tenemos este objeto en el inventario.
    final existingSlotIndex = inventory.value.indexWhere(
      (slot) => slot.item.id == itemToAdd.id,
    );

    if (existingSlotIndex != -1) {
      // Si ya lo tenemos, simplemente aumentamos la cantidad.
      inventory.value[existingSlotIndex].quantity++;
    } else {
      // Si es un objeto nuevo, creamos un nuevo slot.
      inventory.value.add(InventorySlot(item: itemToAdd));
    }

    // ¡Muy importante! Notificamos a los 'listeners' (como nuestra UI) que el inventario ha cambiado.
    inventory.notifyListeners();
    print(
        'Añadido ${itemToAdd.name}. Inventario ahora tiene ${inventory.value.length} tipos de objetos.');
  }

  void useItem(InventorySlot slot) {
    // 1. Llama a la función 'effect' del objeto.
    slot.item.effect(game);

    // 2. Reduce la cantidad.
    slot.quantity--;

    // 3. Si la cantidad llega a 0, elimina el slot del inventario.
    if (slot.quantity <= 0) {
      inventory.value.remove(slot);
    }

    // 4. Notifica a la UI que el inventario ha cambiado.
    inventory.notifyListeners();
  }

  void equipItem(InventorySlot slot) {
    // 1. Nos aseguramos de que el objeto que intentamos equipar sea realmente un EquipmentItem.
    if (slot.item is! EquipmentItem) {
      print('Error: Intentando equipar un objeto no equipable.');
      return;
    }

    final equipmentItem = slot.item as EquipmentItem;

    // 2. Le pasamos el objeto a PlayerStats para que él maneje la lógica de estadísticas.
    stats.equipItem(equipmentItem);

    // 3. ¡Importante! Consumimos UNA unidad del objeto de nuestro inventario.
    slot.quantity--;
    if (slot.quantity <= 0) {
      inventory.value.remove(slot);
    }

    // 4. Notificamos a la UI que el inventario ha cambiado.
    inventory.notifyListeners();
  }

  void unequipItem(EquipmentSlot slot) {
    // Simplemente le pasa la orden a PlayerStats.
    stats.unequipItem(slot);
  }
}
