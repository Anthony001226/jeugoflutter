// lib/components/chest.dart

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Chest extends SpriteComponent {
  final Vector2 gridPosition;
  bool isCollected = false;
  Chest({required this.gridPosition});
  
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