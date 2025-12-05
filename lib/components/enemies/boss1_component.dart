import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:renegade_dungeon/models/combat_stats.dart';
import 'package:renegade_dungeon/models/combat_stats_holder.dart';
import 'package:renegade_dungeon/models/combat_ability.dart';
import 'package:renegade_dungeon/models/ability_database.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/models/enemy_stats.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class Boss1Stats extends EnemyStats implements CombatStatsHolder {
  @override
  final CombatStats combatStats;

  Boss1Stats(this.combatStats)
      : super(
          maxHp: combatStats.maxHp.value,
          attack: combatStats.attack.value,
          defense: combatStats.defense.value,
          speed: combatStats.speed.value,
          xpValue: 500,
          lootTable: {
            ItemDatabase.potion: 1.0,
            ItemDatabase.rustySword: 0.80,
          },
        ) {
    currentHp.value = combatStats.currentHp.value;

    combatStats.currentHp.addListener(() {
      currentHp.value = combatStats.currentHp.value;
    });
  }

  @override
  void takeDamage(int amount) {
    combatStats.takeDamage(amount);
  }
}

class Boss1Component extends SpriteAnimationComponent
    with HasGameReference<RenegadeDungeonGame>, TapCallbacks {
  late final Boss1Stats stats;
  late final List<CombatAbility> abilities;

  final Map<String, SpriteAnimation> _animations = {};
  String _currentAnimationKey = 'idle1';

  Boss1Component() : super(size: Vector2(160, 117)) {
    final combatStats = CombatStats(
      initialHp: 150,
      initialMaxHp: 150,
      initialMp: 50,
      initialMaxMp: 50,
      initialSpeed: 12,
      initialAttack: 25,
      initialDefense: 15,
      initialCritChance: 0.15,
    );

    stats = Boss1Stats(combatStats);

    abilities = AbilityDatabase.getBoss1Abilities();
  }

  @override
  Future<void> onLoad() async {
    await _loadAnimations();
    animation = _animations['idle1'];
  }

  Future<void> _loadAnimations() async {
    final jsonData = await game.assets.readJson('images/enemies/boss1.json');
    final image = await game.images.load('enemies/boss1.png');

    final asepriteData = AsepriteData.fromJson(jsonData);

    _animations['idle1'] = await asepriteData.getAllFramesAnimation(image);
  }

  void playAnimation(String animationKey) {
    if (_animations.containsKey(animationKey)) {
      _currentAnimationKey = animationKey;
      animation = _animations[animationKey];
    }
  }

  String get currentAnimation => _currentAnimationKey;

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

  Future<SpriteAnimation> getAllFramesAnimation(image) async {
    final frameData = _json['frames'] as Map<String, dynamic>;
    final frameKeys = frameData.keys.toList();

    if (frameKeys.isEmpty) {
      throw Exception('No frames found in Aseprite JSON file.');
    }

    final firstFrameInfo = frameData[frameKeys[0]]['frame'];
    final frameSize =
        Vector2(firstFrameInfo['w'].toDouble(), firstFrameInfo['h'].toDouble());

    final frameDurations = frameData.values
        .map<double>((e) => (e['duration'] as int) / 1000.0)
        .toList();

    final animationData = SpriteAnimationData.variable(
      amount: frameDurations.length,
      stepTimes: frameDurations,
      textureSize: frameSize,
    );

    return SpriteAnimation.fromFrameData(image, animationData);
  }
}
