import 'dart:ui';
import 'package:flame/components.dart';

class ConditionalBarrier {
  final String id;
  final Vector2 position;
  final Vector2 size;

  final int requiredLevel;
  final String requiredBoss;
  final String requiredQuest;

  final String blockedMessage;
  final String? unlockedMessage;

  bool isPermanentlyUnlocked;

  ConditionalBarrier({
    required this.id,
    required this.position,
    required this.size,
    this.requiredLevel = 0,
    this.requiredBoss = 'none',
    this.requiredQuest = 'none',
    required this.blockedMessage,
    this.unlockedMessage,
    this.isPermanentlyUnlocked = false,
  });

  factory ConditionalBarrier.fromTiledObject(Map<String, dynamic> properties) {
    return ConditionalBarrier(
      id: properties['id'] as String? ?? 'barrier_${properties.hashCode}',
      position: Vector2(
        (properties['x'] as num?)?.toDouble() ?? 0.0,
        (properties['y'] as num?)?.toDouble() ?? 0.0,
      ),
      size: Vector2(
        (properties['width'] as num?)?.toDouble() ?? 64.0,
        (properties['height'] as num?)?.toDouble() ?? 64.0,
      ),
      requiredLevel: properties['requiredLevel'] as int? ?? 0,
      requiredBoss: properties['requiredBoss'] as String? ?? 'none',
      requiredQuest: properties['requiredQuest'] as String? ?? 'none',
      blockedMessage:
          properties['blockedMessage'] as String? ?? 'No puedes pasar aún.',
      unlockedMessage: properties['unlockedMessage'] as String?,
    );
  }

  bool containsPoint(Vector2 point) {
    return point.x >= position.x &&
        point.x <= position.x + size.x &&
        point.y >= position.y &&
        point.y <= position.y + size.y;
  }

  Rect getBounds() {
    return Rect.fromLTWH(
      position.x,
      position.y,
      size.x,
      size.y,
    );
  }

  @override
  String toString() {
    return 'ConditionalBarrier(id: $id, level: $requiredLevel, boss: $requiredBoss)';
  }
}
