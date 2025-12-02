// lib/components/enemies/skeleton_component.dart

import 'package:flame/components.dart';
import 'package:flame/events.dart'; // Added for TapCallbacks
import 'package:renegade_dungeon/models/combat_stats.dart';
import 'package:renegade_dungeon/models/combat_stats_holder.dart';
import 'package:renegade_dungeon/models/enemy_stats.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

// Enemy wrapper que implementa CombatStatsHolder
class SkeletonStats extends EnemyStats implements CombatStatsHolder {
  @override
  final CombatStats combatStats;

  SkeletonStats({
    required int maxHp,
    required int attack,
    required int defense,
    required int xpValue,
    required int goldDrop, // NEW
    required Map<InventoryItem, double> lootTable,
  })  : combatStats = CombatStats(
          initialHp: maxHp,
          initialMaxHp: maxHp,
          initialMp: 0,
          initialMaxMp: 0,
          initialSpeed: 4,
          initialAttack: attack,
          initialDefense: defense,
        ),
        super(
          maxHp: maxHp,
          attack: attack,
          defense: defense,
          speed: 4,
          xpValue: xpValue,
          goldDrop: goldDrop, // NEW
          lootTable: lootTable,
        ) {
    currentHp.value = combatStats.currentHp.value;
    combatStats.currentHp.addListener(() {
      currentHp.value = combatStats.currentHp.value;
    });
  }

  @override
  void takeDamage(int damage) {
    combatStats.takeDamage(damage);
  }
}

class SkeletonComponent extends SpriteAnimationComponent
    with HasGameReference<RenegadeDungeonGame>, TapCallbacks {
  // Added mixins
  late final SkeletonStats stats;

  SkeletonComponent() : super(size: Vector2.all(128)) {
    stats = SkeletonStats(
      maxHp: 40,
      attack: 10,
      defense: 3,
      xpValue: 60,
      goldDrop: 25, // NEW
      lootTable: {
        ItemDatabase.potion: 0.40,
        ItemDatabase.rustySword: 0.20,
      },
    );
  }

  @override
  Future<void> onLoad() async {
    final sprite = await Sprite.load('enemies/skeleton.png');
    animation = SpriteAnimation.fromFrameData(
      sprite.image,
      SpriteAnimationData.sequenced(
        amount: 1,
        stepTime: 1,
        textureSize: sprite.srcSize,
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.combatManager.selectTarget(this);
    super.onTapDown(event);
  }
}
