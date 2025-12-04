// lib/models/zone_config.dart

import 'package:flame/game.dart';
import 'package:renegade_dungeon/models/item_rarity.dart';

/// Nivel de peligrosidad de una zona
enum DangerLevel {
  safe, // Sin enemigos, verde
  low, // Enemigos débiles, amarillo
  medium, // Enemigos normales, naranja
  high, // Enemigos fuertes/bosses, rojo
}

/// Datos de un portal para transición de mapas
class PortalData {
  final Vector2 gridPosition;
  final Vector2 size; // Portal zone size (in grid units)
  final String targetMap;
  final Vector2 targetPosition;
  final String transitionType; // 'fade', 'instant', 'walk'
  final int transitionDuration; // milliseconds

  PortalData({
    required this.gridPosition,
    Vector2? size, // Make nullable
    required this.targetMap,
    required this.targetPosition,
    this.transitionType = 'fade',
    this.transitionDuration = 2000, // 2 seconds default
  }) : size = size ?? Vector2(1, 1); // Initialize in initializer list

  /// Check if a grid position is within this portal zone
  bool contains(Vector2 gridPos) {
    // Add a small buffer (1.0) to make detection more forgiving
    const buffer = 1.0;
    return gridPos.x >= gridPosition.x - buffer &&
        gridPos.x < gridPosition.x + size.x + buffer &&
        gridPos.y >= gridPosition.y - buffer &&
        gridPos.y < gridPosition.y + size.y + buffer;
  }

  @override
  String toString() {
    return 'Portal to $targetMap at $targetPosition (${size.x}x${size.y}) - $transitionType';
  }
}

/// Propiedades de una zona de spawn
class ZoneProperties {
  final String name;
  final List<String> enemyTypes;
  final double encounterChance;
  final int minLevel;
  final int maxLevel;
  final ItemRarity maxRarity;
  final DangerLevel dangerLevel;

  const ZoneProperties({
    required this.name,
    required this.enemyTypes,
    this.encounterChance = 0.02,
    this.minLevel = 1,
    this.maxLevel = 99,
    this.maxRarity = ItemRarity.uncommon,
    this.dangerLevel = DangerLevel.medium,
  });

  @override
  String toString() {
    return 'Zone: $name (${enemyTypes.join(", ")}) - ${dangerLevel.name}';
  }
}
