// lib/components/enemies/skeleton_component.dart

import 'package:flame/components.dart';
import 'package:renegade_dungeon/models/combat_stats.dart';
import 'package:renegade_dungeon/models/combat_ability.dart';
import 'package:renegade_dungeon/models/ability_database.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';

class SkeletonComponent extends SpriteAnimationComponent {
  late final CombatStats stats;
  late final List<CombatAbility> abilities;

  SkeletonComponent() : super(size: Vector2.all(128));

  @override
  Future<void> onLoad() async {
    // Estadísticas: Defensivo y resistente
    stats = CombatStats(
      initialHp: 35,
      initialMaxHp: 35,
      initialMp: 30,
      initialMaxMp: 30,
      initialSpeed: 8, // LENTO
      initialAttack: 12,
      initialDefense: 8, // ALTA DEFENSA
      initialCritChance: 0.05,
    );

    // Habilidades
    abilities = AbilityDatabase.getSkeletonAbilities();

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
        ItemDatabase.potion: 0.20,
        // TODO: Añadir "Bone" o item especial de skeleton
      };

  int get xpValue => 50;
}
