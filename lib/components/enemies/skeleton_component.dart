// lib/components/enemies/skeleton_component.dart

import 'package:flame/components.dart';
import 'package:renegade_dungeon/models/combat_stats.dart';
import 'package:renegade_dungeon/models/combat_stats_holder.dart';
import 'package:renegade_dungeon/models/combat_ability.dart';
import 'package:renegade_dungeon/models/ability_database.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/models/enemy_stats.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

// Enemy wrapper que implementa CombatStatsHolder
class SkeletonStats extends EnemyStats implements CombatStatsHolder {
  @override
  final CombatStats combatStats;

  SkeletonStats(this.combatStats)
      : super(
          maxHp: combatStats.maxHp.value,
          attack: combatStats.attack.value,
          defense: combatStats.defense.value,
          speed: combatStats.speed.value, // Use speed from combatStats
          xpValue: 50,
          lootTable: {
            ItemDatabase.potion: 0.60, // 60% drop (was 10%)
            ItemDatabase.rustySword: 0.30, // 30% drop (was 5%)
          },
        ) {
    // Sincronizar valores iniciales
    currentHp.value = combatStats.currentHp.value;

    // Escuchar cambios en combatStats y sincronizar
    combatStats.currentHp.addListener(() {
      currentHp.value = combatStats.currentHp.value;
    });
  }

  @override
  void takeDamage(int amount) {
    combatStats.takeDamage(amount);
  }
}

class SkeletonComponent extends SpriteAnimationComponent {
  late final SkeletonStats stats;
  late final List<CombatAbility> abilities;

  SkeletonComponent() : super(size: Vector2.all(128)) {
    // Initialize stats in constructor so it's available immediately
    final combatStats = CombatStats(
      initialHp: 35,
      initialMaxHp: 35,
      initialMp: 25,
      initialMaxMp: 25,
      initialSpeed: 8, // LENTO
      initialAttack: 12,
      initialDefense: 8, // ALTA DEFENSA
      initialCritChance: 0.05, // 5% crítico
    );

    stats = SkeletonStats(combatStats);

    // Habilidades
    abilities = AbilityDatabase.getSkeletonAbilities();
  }

  @override
  Future<void> onLoad() async {
    // Load skeleton sprite
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
}
