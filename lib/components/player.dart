// lib/components/player.dart

import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/components/emote_component.dart';
import 'package:renegade_dungeon/models/player_stats.dart';
import 'chest.dart';

class Player extends SpriteComponent
    with HasGameReference<RenegadeDungeonGame>, KeyboardHandler, CollisionCallbacks {
  Vector2 gridPosition;
  late final PlayerStats stats;

  Player({required this.gridPosition})
      : super(size: Vector2(32, 48), anchor: Anchor.bottomCenter);
      
  @override
  Future<void> onLoad() async {
    stats = PlayerStats(
      initialLevel: 1,
      initialMaxHp: 100,
      initialMaxMp: 50,
      initialAttack: 12,
      initialDefense: 5,
    );
    sprite = await game.loadSprite('characters/player.png');
    position = game.gridToScreenPosition(gridPosition);
    final hitboxSize = Vector2(24, 12);
    add(RectangleHitbox(
      size: hitboxSize,
      position: Vector2((size.x - hitboxSize.x) / 2, size.y - hitboxSize.y),
    ));
    return super.onLoad();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Chest) {
      print('¡Cofre recogido en ${other.gridPosition} por colisión!');
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
      _checkForEncounter();
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
    final tileIndex = targetGridPos.y.toInt() * mapWidth + targetGridPos.x.toInt();
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
}