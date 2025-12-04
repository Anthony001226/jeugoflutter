import 'package:renegade_dungeon/models/inventory_item.dart';

class PlayerSaveData {
  final int level;
  final int currentHp;
  final int maxHp;
  final int currentMp;
  final int maxMp;
  final int experience;
  final int attack;
  final int defense;

  final List<InventorySlotData> inventory;
  final Map<String, String?> equipment;

  final String currentMap;
  final double gridX;
  final double gridY;
  final int gold;
  final int gems;
  final List<String> discoveredMaps;
  final List<String> openedChests;
  final List<String> defeatedBosses;

  final List<String> activeQuests;
  final List<String> completedQuests;

  final DateTime lastSaved;
  final DateTime createdAt;
  final int playtimeSeconds;

  PlayerSaveData({
    required this.level,
    required this.currentHp,
    required this.maxHp,
    required this.currentMp,
    required this.maxMp,
    required this.experience,
    required this.attack,
    required this.defense,
    required this.inventory,
    required this.equipment,
    required this.currentMap,
    required this.gridX,
    required this.gridY,
    required this.gold,
    required this.gems,
    required this.discoveredMaps,
    required this.openedChests,
    required this.defeatedBosses,
    required this.activeQuests,
    required this.completedQuests,
    required this.lastSaved,
    required this.createdAt,
    this.playtimeSeconds = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'currentHp': currentHp,
      'maxHp': maxHp,
      'currentMp': currentMp,
      'maxMp': maxMp,
      'experience': experience,
      'attack': attack,
      'defense': defense,
      'inventory': inventory.map((slot) => slot.toJson()).toList(),
      'equipment': equipment,
      'currentMap': currentMap,
      'gridX': gridX,
      'gridY': gridY,
      'gold': gold,
      'gems': gems,
      'discoveredMaps': discoveredMaps,
      'openedChests': openedChests,
      'defeatedBosses': defeatedBosses,
      'activeQuests': activeQuests,
      'completedQuests': completedQuests,
      'lastSaved': lastSaved.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'playtimeSeconds': playtimeSeconds,
    };
  }

  factory PlayerSaveData.fromJson(Map<String, dynamic> json) {
    return PlayerSaveData(
      level: json['level'] ?? 1,
      currentHp: json['currentHp'] ?? 20,
      maxHp: json['maxHp'] ?? 20,
      currentMp: json['currentMp'] ?? 10,
      maxMp: json['maxMp'] ?? 10,
      experience: json['experience'] ?? 0,
      attack: json['attack'] ?? 12,
      defense: json['defense'] ?? 5,
      inventory: (json['inventory'] as List?)
              ?.map((e) =>
                  InventorySlotData.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      equipment: Map<String, String?>.from(json['equipment'] ?? {}),
      currentMap: json['currentMap'] ?? 'dungeon.tmx',
      gridX: (json['gridX'] as num?)?.toDouble() ?? 5.0,
      gridY: (json['gridY'] as num?)?.toDouble() ?? 5.0,
      gold: json['gold'] ?? 0,
      gems: json['gems'] ?? 0,
      discoveredMaps: List<String>.from(json['discoveredMaps'] ?? []),
      openedChests: List<String>.from(json['openedChests'] ?? []),
      defeatedBosses: List<String>.from(json['defeatedBosses'] ?? []),
      activeQuests: List<String>.from(json['activeQuests'] ?? []),
      completedQuests: List<String>.from(json['completedQuests'] ?? []),
      lastSaved:
          DateTime.parse(json['lastSaved'] ?? DateTime.now().toIso8601String()),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      playtimeSeconds: json['playtimeSeconds'] ?? 0,
    );
  }
}

class InventorySlotData {
  final String itemId;
  final int quantity;

  InventorySlotData({required this.itemId, required this.quantity});

  Map<String, dynamic> toJson() => {'itemId': itemId, 'quantity': quantity};

  factory InventorySlotData.fromJson(Map<String, dynamic> json) {
    return InventorySlotData(
      itemId: json['itemId'],
      quantity: json['quantity'],
    );
  }

  factory InventorySlotData.fromSlot(InventorySlot slot) {
    return InventorySlotData(
      itemId: slot.item.id,
      quantity: slot.quantity,
    );
  }
}
