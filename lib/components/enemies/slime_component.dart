
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:renegade_dungeon/models/enemy_stats.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class SlimeComponent extends SpriteAnimationComponent
    with HasGameReference<RenegadeDungeonGame>, TapCallbacks {
  late final EnemyStats stats;

  final Map<String, SpriteAnimation> _animations = {};

  SlimeComponent() : super(size: Vector2.all(128)) {
    stats = EnemyStats(
      maxHp: 20,
      attack: 6,
      defense: 4,
      speed: 6,
      xpValue: 35,
      goldDrop: 10,
      lootTable: {
        ItemDatabase.potion: 0.30,
      },
    );
  }

  @override
  Future<void> onLoad() async {
    await _loadAnimations();
    animation = _animations['idle'];
  }

  Future<void> _loadAnimations() async {
    final jsonData = await game.assets.readJson('images/enemies/slime.json');

    final image = await game.images.load('enemies/slime-sheet.png');

    final asepriteData = AsepriteData.fromJson(jsonData);

    _animations['idle'] = await asepriteData.getAnimation('idle', image);
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.combatManager.selectTarget(this);
    super.onTapDown(event);
  }
}

class AsepriteData {
  final Map<String, dynamic> _json;
  AsepriteData.fromJson(this._json);

  Future<SpriteAnimation> getAnimation(String tag, image) async {
    final frameData = _json['frames'] as Map<String, dynamic>;
    final meta = _json['meta'];
    final frameTags = (meta['frameTags'] as List)
        .firstWhere((t) => t['name'] == tag, orElse: () => null);

    if (frameTags == null) {
      throw Exception('Tag "$tag" not found in Aseprite JSON file.');
    }

    final frameKeys = frameData.keys.toList();
    final firstFrameKey = frameKeys[frameTags['from']];
    final firstFrameInfo = frameData[firstFrameKey]['frame'];
    final firstFrameSize =
        Vector2(firstFrameInfo['w'].toDouble(), firstFrameInfo['h'].toDouble());

    final frameDurations = (frameData.values
            .toList()
            .sublist(frameTags['from'], frameTags['to'] + 1))
        .map<double>((e) => (e['duration'] as int) / 1000.0)
        .toList();

    final animationData = SpriteAnimationData.variable(
      amount: frameDurations.length,
      stepTimes: frameDurations,
      textureSize: firstFrameSize,
    );

    return SpriteAnimation.fromFrameData(image, animationData);
  }
}
