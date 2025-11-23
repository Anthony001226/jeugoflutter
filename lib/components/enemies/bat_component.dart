// lib/components/enemies/bat_component.dart

import 'package:flame/components.dart';
import 'package:renegade_dungeon/models/combat_stats.dart';
import 'package:renegade_dungeon/models/combat_ability.dart';
import 'package:renegade_dungeon/models/ability_database.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/models/enemy_stats.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

// Enemy wrapper que implementa CombatStatsHolder
class BatStats extends EnemyStats implements CombatStatsHolder {
  @override
  final CombatStats combatStats;

  BatStats(this.combatStats)
      : super(
          maxHp: combatStats.maxHp.value,
          attack: combatStats.attack.value,
          defense: combatStats.defense.value,
          speed: combatStats.speed.value, // Use speed from combatStats
          xpValue: 30,
          lootTable: {ItemDatabase.potion: 0.15},
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

class BatComponent extends SpriteAnimationComponent {
  late final BatStats stats;
  late final List<CombatAbility> abilities;

  BatComponent() : super(size: Vector2.all(128)) {
    // Initialize stats in constructor so it's available immediately
    final combatStats = CombatStats(
      initialHp: 15,
      initialMaxHp: 15,
      initialMp: 20,
      initialMaxMp: 20,
      initialSpeed: 15, // MUY RÁPIDO
      initialAttack: 8,
      initialDefense: 2,
      initialCritChance: 0.25, // 25% crítico
    );

    stats = BatStats(combatStats);

    // Habilidades
    abilities = AbilityDatabase.getBatAbilities();
  }

  @override
  Future<void> onLoad() async {
    // Sprite temporal (usaremos el del goblin por ahora)
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

  // Loot table
  Map<InventoryItem, double> get lootTable => {
        ItemDatabase.potion: 0.15,
      };

  int get xpValue => 30;
}
