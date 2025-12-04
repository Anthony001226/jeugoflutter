import 'package:flame/components.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class IntroRouteComponent extends Component
    with HasGameReference<RenegadeDungeonGame> {
  @override
  void onMount() {
    super.onMount();

    game.overlays.clear();

    game.overlays.add('IntroScreen');
  }

  @override
  void onRemove() {
    game.overlays.remove('IntroScreen');
    super.onRemove();
  }
}
