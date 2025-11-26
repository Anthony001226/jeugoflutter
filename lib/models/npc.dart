// lib/models/npc.dart

import 'package:flame/components.dart';

/// Types of NPCs available in the game
enum NPCType {
  vendor, // Comerciante (compra/vende items)
  questGiver, // Da misiones
  lore, // Información del mundo
  generic, // Conversación simple
}

/// NPC (Non-Player Character) model with dialogue and interaction data
class NPC {
  /// Unique identifier for this NPC
  final String id;

  /// Display name of the NPC
  final String name;

  /// Type of NPC (determines behavior)
  final NPCType type;

  /// Grid position of the NPC on the map
  final Vector2 gridPosition;

  /// Path to the sprite sheet for this NPC
  final String spriteSheet;

  /// Initial dialogue text when interacting
  final String dialogue;

  /// Optional vendor-specific data (inventory, prices, etc.)
  final Map<String, dynamic>? vendorData;

  /// Optional quest-specific data (quest ID, requirements, etc.)
  final Map<String, dynamic>? questData;

  NPC({
    required this.id,
    required this.name,
    required this.type,
    required this.gridPosition,
    required this.spriteSheet,
    required this.dialogue,
    this.vendorData,
    this.questData,
  });

  @override
  String toString() {
    return 'NPC($name [$type] at $gridPosition)';
  }
}
