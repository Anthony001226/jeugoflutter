
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:renegade_dungeon/models/enemy_stats.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/models/combat_stats.dart';
import 'package:renegade_dungeon/models/combat_stats_holder.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class GoblinStats extends EnemyStats implements CombatStatsHolder {
  @override
  final CombatStats combatStats;

  GoblinStats({
    required int maxHp,
    required int attack,
    required int defense,
    required int xpValue,
    required int goldDrop,
    required Map<InventoryItem, double> lootTable,
  })  : combatStats = CombatStats(
          initialHp: maxHp,
          initialMaxHp: maxHp,
          initialMp: 10,
          initialMaxMp: 10,
          initialSpeed: 5,
          initialAttack: attack,
          initialDefense: defense,
        ),
        super(
          maxHp: maxHp,
          attack: attack,
          defense: defense,
          speed: 5,
          xpValue: xpValue,
          goldDrop: goldDrop,
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

class GoblinComponent extends SpriteAnimationComponent
    with HasGameReference<RenegadeDungeonGame>, TapCallbacks {
  late final GoblinStats stats;

  GoblinComponent() : super(size: Vector2.all(128)) {
    stats = GoblinStats(
      maxHp: 30,
      attack: 8,
      defense: 2,
      xpValue: 45,
      goldDrop: 15,
      lootTable: {
        ItemDatabase.potion: 0.50,
        ItemDatabase.goblinScimitar: 0.30,
      },
    );
  }

  @override
  Future<void> onLoad() async {
    final sprite = await Sprite.load('enemies/goblin.png');
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
