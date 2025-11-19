// lib/components/goblin_component.dart

import 'package:flame/components.dart';
import 'package:renegade_dungeon/models/enemy_stats.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';

// Lo convertimos en SpriteAnimationComponent para que sea del mismo tipo que el Slime
class GoblinComponent extends SpriteAnimationComponent {
  late final EnemyStats stats;

  GoblinComponent() : super(size: Vector2.all(128));

  @override
  Future<void> onLoad() async {
    stats = EnemyStats(
      maxHp: 30,
      attack: 8,
      defense: 2,
      xpValue: 45,
      lootTable: {
        // 10% de probabilidad de soltar una poción. ¡Un drop raro!
        ItemDatabase.potion: 0.05, 
      },
    );
    
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
}