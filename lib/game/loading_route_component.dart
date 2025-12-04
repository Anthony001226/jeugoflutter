import 'package:flame/components.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class LoadingRouteComponent extends Component
    with HasGameReference<RenegadeDungeonGame> {
  @override
  void onMount() {
    super.onMount();
    _startLoading();
  }

  Future<void> _startLoading() async {

    // 1. Force remove previous overlays
    game.overlays.remove('SlotSelectionMenu');
    game.overlays.remove('MainMenu');

    // 2. Stop video
    await game.stopBackgroundVideo();

    // 3. Show Loading UI
    game.overlays.add('LoadingUI');

    // 4. Clear previous game state (CRITICAL for preventing black screen)
    game.clearWorld();

    // Fix: Add a small delay to ensure the engine processes the cleanup
    // This prevents "ghost" state from interfering with the new load
    await Future.delayed(const Duration(milliseconds: 100));

    // 5. Load Data
    try {
      final isNewGame = await game.loadGameData();
      game.overlays.remove('LoadingUI');

      // WORKAROUND: Always go through intro-screen to avoid Flame router bug
      // IntroScreen will detect if it's a loaded game and skip instantly

      // Set flag so IntroScreen knows whether to skip (if we go there)
      game.isNewGameFlag = isNewGame;

      if (isNewGame) {
        // Increment navigation counter to force IntroScreen recreation
        game.introNavigationCount++;
        game.router.pushReplacementNamed('intro-screen');
      } else {
        game.router.pushReplacementNamed('game-screen');
      }
    } catch (e, stack) {
      game.overlays.remove('LoadingUI');
      game.router.pushReplacementNamed('slot-selection-menu');
    }
  }
}
