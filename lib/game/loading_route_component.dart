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

    game.overlays.remove('SlotSelectionMenu');
    game.overlays.remove('MainMenu');

    await game.stopBackgroundVideo();

    game.overlays.add('LoadingUI');

    game.clearWorld();

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final isNewGame = await game.loadGameData();
      game.overlays.remove('LoadingUI');


      game.isNewGameFlag = isNewGame;

      if (isNewGame) {
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
