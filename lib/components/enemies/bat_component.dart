
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:renegade_dungeon/models/combat_stats.dart';
import 'package:renegade_dungeon/models/combat_stats_holder.dart';
import 'package:renegade_dungeon/models/combat_ability.dart';
import 'package:renegade_dungeon/models/ability_database.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/models/enemy_stats.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class BatStats extends EnemyStats implements CombatStatsHolder {
  @override
  final CombatStats combatStats;

  BatStats(this.combatStats)
      : super(
          maxHp: combatStats.maxHp.value,
          attack: combatStats.attack.value,
          defense: combatStats.defense.value,
          speed: combatStats.speed.value,
          xpValue: 30,
          lootTable: {ItemDatabase.potion: 0.50},
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

class BatComponent extends SpriteAnimationComponent
    with HasGameReference<RenegadeDungeonGame>, TapCallbacks {
  late final BatStats stats;
  late final List<CombatAbility> abilities;

  BatComponent() : super(size: Vector2.all(128)) {
    final combatStats = CombatStats(
      initialHp: 15,
      initialMaxHp: 15,
      initialMp: 20,
      initialMaxMp: 20,
      initialSpeed: 15,
      initialAttack: 8,
      initialDefense: 2,
      initialCritChance: 0.25,
    );

    stats = BatStats(combatStats);

    abilities = AbilityDatabase.getBatAbilities();
  }

  @override
  Future<void> onLoad() async {
    final sprite = await Sprite.load('enemies/bat.png');
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

  Map<InventoryItem, double> get lootTable => {
        ItemDatabase.potion: 0.15,
      };

  int get xpValue => 30;
}
