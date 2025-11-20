// lib/game/game_screen.dart

import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:renegade_dungeon/components/chest.dart';
import 'package:renegade_dungeon/components/player.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';

class GameScreen extends Component with HasGameReference<RenegadeDungeonGame> {
  @override
  Future<void> onLoad() async {
    // --- FASE 1: PREPARACIÓN GENERAL ---
    game.state = GameState.exploring;
    game.playWorldMusic();
    game.overlays.clear();
    game.camera.viewfinder.anchor = Anchor.center;

    // --- FASE 2: CONSTRUIR EL MUNDO VISUAL ---
    // Añadimos los componentes al 'world' de ESTA pantalla.

    // Primero, el fondo negro, usando el tamaño del mapa que ya fue cargado.
    await game.world.add(
      RectangleComponent(
        size: game.mapComponent.size,
        paint: BasicPalette.black.paint(),
        priority: -1,
      ),
    );

    // Segundo, el mapa.
    await game.world.add(game.mapComponent);

    // Tercero, el jugador. 'await' asegura que su propio onLoad() se complete.
    await game.world.add(game.player);

    // --- FASE 3: RESETEAR EL ESTADO DEL JUGADOR ---
    // AHORA que el jugador está en el mundo y sus 'stats' existen, es seguro resetearlo.
    game.player.stats.currentHp.value = game.player.stats.maxHp.value;
    game.player.stats.currentMp.value = game.player.stats.maxMp.value;
    game.player.gridPosition = Vector2(20.0, 20.0);
    game.player.position = game.gridToScreenPosition(game.player.gridPosition);

    // --- FASE 4: AÑADIR OBJETOS DINÁMICOS ---
    final pickupsLayer =
        game.mapComponent.tileMap.getLayer<ObjectGroup>('Pickups');
    if (pickupsLayer != null) {
      int chestCounter = 0;
      for (final tiledObject in pickupsLayer.objects) {
        if (tiledObject.gid == null || tiledObject.gid == 0) continue;
        final gridX = tiledObject.properties.getValue<int>('gridX');
        final gridY = tiledObject.properties.getValue<int>('gridY');
        if (gridX == null || gridY == null) continue;
        final gridPosition = Vector2(gridX.toDouble(), gridY.toDouble());

        InventoryItem itemForThisChest;
        if (chestCounter == 0) {
          itemForThisChest = ItemDatabase.rustySword;
        } else if (chestCounter == 1) {
          itemForThisChest = ItemDatabase.leatherTunic;
        } else {
          itemForThisChest = ItemDatabase.potion;
        }
        chestCounter++;

        final chestSprite = await game.loadSprite('iso_tile_export.png',
            srcPosition: Vector2(384, 32), srcSize: Vector2(32, 32));
        final chest = Chest(
          gridPosition: gridPosition,
          item: itemForThisChest,
        )
          ..sprite = chestSprite
          ..size = Vector2(32, 32)
          ..position = game.gridToScreenPosition(gridPosition)
          ..anchor = Anchor.bottomCenter;

        await game.world.add(chest);
      }
    }

    // --- FASE 5: CONFIGURACIÓN FINAL DE LA UI ---
    game.camera.follow(game.player);
    game.overlays.add('PlayerHud');
  }

  @override
  void onRemove() {
    game.stopMusic();
    super.onRemove();
  }
}
