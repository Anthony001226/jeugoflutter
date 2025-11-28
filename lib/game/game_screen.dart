// lib/game/game_screen.dart

import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:renegade_dungeon/components/player.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

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
    // REMOVED: Player state is already set by loadGameData()
    // game.player.stats.currentHp.value = game.player.stats.maxHp.value;
    // game.player.stats.currentMp.value = game.player.stats.maxMp.value;
    // game.player.gridPosition = Vector2(20.0, 20.0);
    // game.player.position = game.gridToScreenPosition(game.player.gridPosition);

    // --- FASE 4: AÑADIR OBJETOS DINÁMICOS ---
    // La carga de cofres ahora se maneja en RenegadeDungeonGame._loadChests()
    // para soportar múltiples mapas y transiciones.

    // --- FASE 5: CONFIGURACIÓN FINAL DE LA UI ---
    game.camera.follow(game.player);
    game.overlays.add('PlayerHud');
  }

  @override
  void onRemove() {
    // Detiene la música
    game.stopMusic();

    // Remueve los overlays del juego
    game.overlays.remove('PlayerHud');
    game.overlays.remove('PauseMenuUI');

    super.onRemove();
  }
}
