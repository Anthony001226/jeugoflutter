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
    print('🚩 Mounting $overlayName route');

    // Clear the game world (map, player, etc.) to prevent visual glitches
    game.world.removeAll(game.world.children);

    game.overlays.clear();
    game.overlays.add(overlayName);
    game.playBackgroundVideo(videoName);
  }
}
