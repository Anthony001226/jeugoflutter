
import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

bool get isMobile {
  if (kIsWeb) return false;
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (e) {
    return false;
  }
}

class GameScreen extends Component with HasGameReference<RenegadeDungeonGame> {
  GameScreen() {
  }

  @override
  void onMount() {
    super.onMount();
  }

  @override
  Future<void> onLoad() async {
    game.isPlayerReadyNotifier.value = false;

    try {
      game.playWorldMusic();
      game.overlays.clear();
      game.camera.viewfinder.anchor = Anchor.center;

      if (!game.world.isMounted) {
        game.add(game.world);
      }

      final mapSize = game.mapComponent.size;
      await game.world.add(
        RectangleComponent(
          size: mapSize,
          paint: BasicPalette.black.paint(),
          priority: -1,
        ),
      );

      if (!game.world.contains(game.mapComponent)) {
        await game.world.add(game.mapComponent);
      } else {
      }

      if (!game.world.contains(game.player)) {
        await game.world.add(game.player);
      } else {
      }

      game.camera.follow(game.player);

      game.camera.viewfinder.position = game.player.position.clone();

      await Future.delayed(const Duration(milliseconds: 100));

      game.isPlayerReadyNotifier.value = true;

      game.overlays.add('PlayerHud');

      if (isMobile) {
        game.overlays.add('MobileControls');
      }

      game.state = GameState.exploring;

      game.updateExploration(game.player.position);

    } catch (e, stack) {
      rethrow;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
  }

  @override
  void onRemove() {
    game.stopMusic();
    game.overlays.remove('PlayerHud');
    game.overlays.remove('PauseMenuUI');
    game.isPlayerReadyNotifier.value = false;
    super.onRemove();
  }
}
