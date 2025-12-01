// lib/components/goblin_component.dart

import 'package:flame/components.dart';
import 'package:flame/events.dart'; // Import for TapCallbacks
import 'package:renegade_dungeon/models/enemy_stats.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/models/combat_stats.dart';
import 'package:renegade_dungeon/models/combat_stats_holder.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

// Wrapper que combina EnemyStats con CombatStats
class GoblinStats extends EnemyStats implements CombatStatsHolder {
  @override
  final CombatStats combatStats;

  GoblinStats({
    required int maxHp,
    required int attack,
    required int defense,
    required int xpValue,
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
          speed: 5, // Use speed from combatStats
          xpValue: xpValue,
          lootTable: lootTable,
        ) {
    // Sincronizar valores iniciales
    currentHp.value = combatStats.currentHp.value;

    // Escuchar cambios en combatStats y sincronizar
    combatStats.currentHp.addListener(() {
      currentHp.value = combatStats.currentHp.value;
    });
  }

  @override
  void takeDamage(int damage) {
    combatStats.takeDamage(damage);
    // currentHp se sincroniza automáticamente por el listener
  }
}

// Lo convertimos en SpriteAnimationComponent para que sea del mismo tipo que el Slime
class GoblinComponent extends SpriteAnimationComponent
    with HasGameReference<RenegadeDungeonGame>, TapCallbacks {
  late final GoblinStats stats;

  GoblinComponent() : super(size: Vector2.all(128)) {
    // Initialize stats in constructor so it's available immediately
    stats = GoblinStats(
      maxHp: 30,
      attack: 8,
      defense: 2,
      xpValue: 45,
      lootTable: {
        ItemDatabase.potion: 0.50, // 50% drop (antes 10%)
        ItemDatabase.goblinScimitar: 0.30, // 30% drop (antes 5%)
      },
    );
  }

  @override
  Future<void> onLoad() async {
    // Creamos una "animación" de un solo frame
    final sprite = await Sprite.load('enemies/goblin.png');
    animation = SpriteAnimation.fromFrameData(
      sprite.image,
      SpriteAnimationData.sequenced(
        amount: 1, // solo un frame
        stepTime: 1, // no importa el tiempo
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
