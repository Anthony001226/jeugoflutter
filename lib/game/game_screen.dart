// lib/game/game_screen.dart

import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// Platform detection
bool get isMobile {
  if (kIsWeb) return false;
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (e) {
    return false;
  }
}

class GameScreen extends Component with HasGameReference<RenegadeDungeonGame> {
  @override
  Future<void> onLoad() async {
    print('🎮 GameScreen.onLoad() started');

    try {
      // Play world music
      game.playWorldMusic();
      game.overlays.clear();
      game.camera.viewfinder.anchor = Anchor.center;

      // Ensure world is mounted
      if (!game.world.isMounted) {
        game.add(game.world);
        print('🌍 World re-mounted');
      }

      // Add background
      print('📐 Adding background...');
      final mapSize = game.mapComponent.size;
      await game.world.add(
        RectangleComponent(
          size: mapSize,
          paint: BasicPalette.black.paint(),
          priority: -1,
        ),
      );

      // Add map if not already added
      if (!game.world.contains(game.mapComponent)) {
        print('🗺️ Adding mapComponent to world');
        await game.world.add(game.mapComponent);
      } else {
        print('⚠️ mapComponent already in world');
      }

      // Add player if not already added
      if (!game.world.contains(game.player)) {
        print('🧍 Adding player to world');
        await game.world.add(game.player);
      } else {
        print('⚠️ player already in world');
      }

      // Setup camera and UI
      print('📷 Setting up camera and UI');
      game.camera.follow(game.player);

      // Force camera to snap to player position immediately
      print('📷 Snapping camera to player at ${game.player.position}');
      game.camera.viewfinder.position = game.player.position.clone();

      // Small delay to ensure camera updates
      await Future.delayed(const Duration(milliseconds: 100));

      // Set player ready FIRST (so HUD builder knows player is ready)
      game.isPlayerReadyNotifier.value = true;

      // THEN add HUD overlay
      game.overlays.add('PlayerHud');

      // Add mobile controls if on mobile
      if (isMobile) {
        game.overlays.add('MobileControls');
        print('📱 Mobile controls added');
      }

      // Set game state
      game.state = GameState.exploring;

      print('✅ GameScreen.onLoad() completed successfully');
    } catch (e, stack) {
      print('❌ ERROR in GameScreen.onLoad(): $e');
      print('Stack trace: $stack');
      rethrow;
    }
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
