// lib/models/conditional_barrier.dart

import 'dart:ui';
import 'package:flame/components.dart';

/// Represents a barrier that blocks passage until certain conditions are met
/// Configured in Tiled with properties for level and boss requirements
class ConditionalBarrier {
  /// Unique identifier for this barrier
  final String id;

  /// Position and size of the barrier collider
  final Vector2 position;
  final Vector2 size;

  /// Minimum level required to pass (0 = no level requirement)
  final int requiredLevel;

  /// Boss ID that must be defeated to pass ("none" = no boss requirement)
  final String requiredBoss;

  /// Quest ID that must be completed ("none" = no quest requirement)
  final String requiredQuest;

  /// Message shown when player doesn't meet requirements
  final String blockedMessage;

  /// Optional message shown when requirements are met (first time)
  final String? unlockedMessage;

  /// Whether this barrier has been permanently unlocked
  /// (used for one-time messages and optimization)
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

  /// Create barrier from Tiled object properties
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

  /// Check if a point is inside this barrier's bounds
  bool containsPoint(Vector2 point) {
    return point.x >= position.x &&
        point.x <= position.x + size.x &&
        point.y >= position.y &&
        point.y <= position.y + size.y;
  }

  /// Get the rectangular bounds for collision detection
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
