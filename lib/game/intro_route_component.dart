import 'package:flame/components.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class IntroRouteComponent extends Component
    with HasGameReference<RenegadeDungeonGame> {
  @override
  void onMount() {
    super.onMount();
    print('🎬 IntroRouteComponent mounted');

    // Ensure clean state
    game.overlays.clear();

    // Add IntroScreen overlay
    game.overlays.add('IntroScreen');
  }

  @override
  void onRemove() {
    print('🎬 IntroRouteComponent removed');
    game.overlays.remove('IntroScreen');
    super.onRemove();
  }
}
