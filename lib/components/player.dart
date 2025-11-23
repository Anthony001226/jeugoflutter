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
import 'chest.dart';

class Player extends SpriteComponent
    with
        HasGameReference<RenegadeDungeonGame>,
        KeyboardHandler,
        CollisionCallbacks {
  Vector2 gridPosition;
  late final PlayerStats stats;
  final inventory = ValueNotifier<List<InventorySlot>>([]);

  Player({required this.gridPosition})
      : super(size: Vector2(32, 48), anchor: Anchor.bottomCenter);

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
    sprite = await game.loadSprite('characters/player.png');
    position = game.gridToScreenPosition(gridPosition);
    priority = 10; // ← Render encima de map layers
    final hitboxSize = Vector2(24, 12);
    add(RectangleHitbox(
      size: hitboxSize,
      position: Vector2((size.x - hitboxSize.x) / 2, size.y - hitboxSize.y),
    )..debugMode = true);
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
    if (event is! KeyDownEvent) {
      return super.onKeyEvent(event, keysPressed);
    }
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
      _move(moveDirection);
    }
    return true;
  }

  void _move(Vector2 direction) {
    final targetGridPosition = gridPosition + direction;
    if (!_hasCollision(targetGridPosition)) {
      gridPosition = targetGridPosition;
      position = game.gridToScreenPosition(gridPosition);

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
