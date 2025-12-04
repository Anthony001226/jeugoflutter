import 'package:flame/components.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class MenuRouteComponent extends Component
    with HasGameReference<RenegadeDungeonGame> {
  final String overlayName;
  final String videoName;

  MenuRouteComponent(this.overlayName, this.videoName);

  @override
  void onMount() {
    super.onMount();

    game.world.removeAll(game.world.children);

    game.overlays.clear();
    game.overlays.add(overlayName);

    try {
      final bool isDesktop = true;
      game.playBackgroundVideo(videoName);
    } catch (e) {
    }
  }

  @override
  void onRemove() {
    game.overlays.remove(overlayName);
    super.onRemove();
  }
}
