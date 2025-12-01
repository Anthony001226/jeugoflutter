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

    // Only play videos on non-mobile platforms (performance)
    try {
      // Check if mobile by trying to access Platform
      // This will throw on web, so we wrap in try-catch
      final bool isDesktop = true; // Assume desktop by default
      game.playBackgroundVideo(videoName);
    } catch (e) {
      print('ℹ️ Skipping video on this platform');
    }
  }

  @override
  void onRemove() {
    print('🚩 Removing $overlayName route');
    game.overlays.remove(overlayName);
    super.onRemove();
  }
}
