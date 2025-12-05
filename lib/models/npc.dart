import 'package:flame/components.dart';

enum NPCType {
  vendor,
  questGiver,
  lore,
  generic,
}

class NPC {
  final String id;
  final String name;
  final NPCType type;
  final Vector2 gridPosition;
  final String spriteSheet;
  final String dialogue;
  final Map<String, dynamic>? vendorData;
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
