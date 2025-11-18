// lib/game/game_screen.dart

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:renegade_dungeon/components/chest.dart';
import 'package:renegade_dungeon/components/player.dart';
import 'package:flame/palette.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

// Este componente representa el mundo del juego jugable.
class GameScreen extends Component with HasGameReference<RenegadeDungeonGame> {
  @override
  Future<void> onLoad() async {
    game.playWorldMusic();

    game.overlays.clear();
    game.camera.viewfinder.anchor = Anchor.center;
    game.mapComponent = await TiledComponent.load('dungeon.tmx', Vector2(game.tileWidth, game.tileHeight));
    await game.world.add(
      RectangleComponent(
        size: game.mapComponent.size, // <-- ¡ESTE ES EL CAMBIO CLAVE!
        paint: BasicPalette.black.paint(),
        priority: -1, // Lo ponemos detrás de todo lo demás en el 'world'.
      ),
    );

    await game.world.add(game.mapComponent);
    await game.world.add(game.player);
    // Al entrar en esta "pantalla", limpiamos cualquier overlay anterior (como el menú).
    game.overlays.clear();
    // -- TODA LA LÓGICA DE CARGA DEL MUNDO VA AQUÍ --
    game.camera.viewfinder.anchor = Anchor.center;

    await game.world.add(game.mapComponent);
    await game.world.add(game.player);
    
    game.mapComponent = await TiledComponent.load('dungeon.tmx', Vector2(game.tileWidth, game.tileHeight));
    await game.world.add(game.mapComponent);

    // Llamamos al método _loadZoneData que está en la clase principal
    game.loadZoneData(); 
    
    game.collisionLayer = game.mapComponent.tileMap.getLayer<TileLayer>('Collision')!;
    game.collisionLayer.visible = false;
    final pickupsLayer = game.mapComponent.tileMap.getLayer<ObjectGroup>('Pickups');
    if (pickupsLayer != null) {
      for (final tiledObject in pickupsLayer.objects) {
        if (tiledObject.gid == null || tiledObject.gid == 0) continue;
        final gridX = tiledObject.properties.getValue<int>('gridX');
        final gridY = tiledObject.properties.getValue<int>('gridY');
        if (gridX == null || gridY == null) continue;
        final gridPosition = Vector2(gridX.toDouble(), gridY.toDouble());
        final chestSprite = await game.loadSprite('iso_tile_export.png', srcPosition: Vector2(384, 32), srcSize: Vector2(32, 32));
        final chest = Chest(gridPosition: gridPosition)
          ..sprite = chestSprite
          ..size = Vector2(32, 32)
          ..position = game.gridToScreenPosition(gridPosition)
          ..anchor = Anchor.bottomCenter;
        final gid = Gid.fromInt(tiledObject.gid!);
        if (gid.flips.horizontally) chest.flipHorizontally();
        if (gid.flips.vertically) chest.flipVertically();
        await game.world.add(chest);
      }
    }

    game.player = Player(gridPosition: Vector2(20.0, 20.0));
    await game.world.add(game.player);
    
    game.camera.follow(game.player);
    game.overlays.add('PlayerHud');
  }
  @override
  void onRemove() {
    game.stopMusic();
    super.onRemove();
  }
}