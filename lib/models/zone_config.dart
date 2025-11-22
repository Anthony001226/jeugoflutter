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
  final String targetMap;
  final Vector2 targetPosition;

  const PortalData({
    required this.gridPosition,
    required this.targetMap,
    required this.targetPosition,
  });

  @override
  String toString() {
    return 'Portal to $targetMap at ${targetPosition}';
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
