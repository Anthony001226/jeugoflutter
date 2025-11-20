// lib/components/chest.dart

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';

class Chest extends SpriteComponent {
  final Vector2 gridPosition;
  bool isCollected = false;
  final InventoryItem item;

  // Actualizamos el constructor.
  Chest({
    required this.gridPosition,
    required this.item,
  });
  
  @override
  Future<void> onLoad() async {
    // ¡LA SOLUCIÓN! Añadimos el hitbox en onLoad para que 'size' ya esté definido.
    final hitboxSize = Vector2(size.x * 0.2, size.y * 0.2);
    add(RectangleHitbox(
      size: hitboxSize,
      position: Vector2(
        (size.x - hitboxSize.x) / 2, // Centrado horizontalmente
        size.y - hitboxSize.y,      // Colocado en la base del sprite
      ),
      
    )
    //..debugMode = true
    );
    return super.onLoad();
  }
}