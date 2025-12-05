import 'package:flame/game.dart';
import 'package:renegade_dungeon/models/item_rarity.dart';

enum DangerLevel {
  safe,
  low,
  medium,
  high,
}

class PortalData {
  final Vector2 gridPosition;
  final Vector2 size;
  final String targetMap;
  final Vector2 targetPosition;
  final String transitionType;
  final int transitionDuration;

  PortalData({
    required this.gridPosition,
    Vector2? size,
    required this.targetMap,
    required this.targetPosition,
    this.transitionType = 'fade',
    this.transitionDuration = 2000,
  }) : size = size ?? Vector2(1, 1);

  bool contains(Vector2 gridPos) {
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
