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

    // 4. Load Data
    try {
      print('📂 Calling loadGameData()...');
      final isNewGame = await game.loadGameData();
      game.overlays.remove('LoadingUI');

      if (isNewGame) {
        print('🆕 New game detected, going to intro-screen');
        game.router.pushReplacementNamed('intro-screen');
      } else {
        print('🔙 Existing game detected, going to game-screen');
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
