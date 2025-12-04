import 'package:flame/components.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class LoadingRouteComponent extends Component
    with HasGameReference<RenegadeDungeonGame> {
  @override
  void onMount() {
    super.onMount();
    print('🚦 LoadingRouteComponent mounted');
    _startLoading();
  }

  Future<void> _startLoading() async {
    print('⏱️ Starting loading sequence...');

    // 1. Force remove previous overlays
    game.overlays.remove('SlotSelectionMenu');
    game.overlays.remove('MainMenu');
    print('🧹 Overlays cleared');

    // 2. Stop video
    print('🛑 Stopping video...');
    await game.stopBackgroundVideo();

    // 3. Show Loading UI
    game.overlays.add('LoadingUI');

    // 4. Clear previous game state (CRITICAL for preventing black screen)
    print('🧹 Clearing previous game state...');
    game.clearWorld();

    // Fix: Add a small delay to ensure the engine processes the cleanup
    // This prevents "ghost" state from interfering with the new load
    await Future.delayed(const Duration(milliseconds: 100));

    // 5. Load Data
    try {
      print('📂 Calling loadGameData()...');
      final isNewGame = await game.loadGameData();
      game.overlays.remove('LoadingUI');

      // WORKAROUND: Always go through intro-screen to avoid Flame router bug
      // IntroScreen will detect if it's a loaded game and skip instantly
      print(isNewGame ? '🆕 New game detected' : '🔙 Existing game detected');

      // Set flag so IntroScreen knows whether to skip (if we go there)
      game.isNewGameFlag = isNewGame;

      if (isNewGame) {
        // Increment navigation counter to force IntroScreen recreation
        game.introNavigationCount++;
        print('📊 Intro navigation count: ${game.introNavigationCount}');
        print('🆕 New game: Navigating to intro-screen');
        game.router.pushReplacementNamed('intro-screen');
      } else {
        print('🔙 Loaded game: Navigating directly to game-screen');
        game.router.pushReplacementNamed('game-screen');
      }
    } catch (e, stack) {
      print('❌ Error loading game data: $e');
      print(stack);
      game.overlays.remove('LoadingUI');
      game.router.pushReplacementNamed('slot-selection-menu');
    }
  }
}
