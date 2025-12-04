
import 'dart:math';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/models/item_rarity.dart';

/// Maneja la generación de loot con sistema de raridades
class LootManager {
  final Random _random = Random();

  /// Genera un item basado en el nivel del jugador y rareza máxima permitida
  InventoryItem? generateLoot({
    required int playerLevel,
    ItemRarity maxRarity = ItemRarity.rare,
    List<InventoryItem> itemPool = const [],
  }) {
    final pool = itemPool.isEmpty ? _getAllItems() : itemPool;

    final eligibleItems = pool.where((item) {
      return item.levelRequirement <= playerLevel &&
          item.rarity.index <= maxRarity.index &&
          playerLevel >= RarityConfig.getConfig(item.rarity).minLevel;
    }).toList();

    if (eligibleItems.isEmpty) return null;

    double totalWeight = 0.0;
    for (final item in eligibleItems) {
      totalWeight += RarityConfig.getConfig(item.rarity).dropWeight;
    }

    double roll = _random.nextDouble() * totalWeight;
    double currentWeight = 0.0;

    for (final item in eligibleItems) {
      currentWeight += RarityConfig.getConfig(item.rarity).dropWeight;
      if (roll <= currentWeight) {
        return item;
      }
    }

    return eligibleItems.first;
  }

  /// Genera múltiples items (para cofres o boss kills)
  List<InventoryItem> generateMultipleLoot({
    required int playerLevel,
    required int quantity,
    ItemRarity maxRarity = ItemRarity.rare,
    List<InventoryItem> itemPool = const [],
  }) {
    final items = <InventoryItem>[];
    for (int i = 0; i < quantity; i++) {
      final item = generateLoot(
        playerLevel: playerLevel,
        maxRarity: maxRarity,
        itemPool: itemPool,
      );
      if (item != null) {
        items.add(item);
      }
    }
    return items;
  }

  /// Genera loot específico de enemigo con garantía de al menos 1 item
  InventoryItem? generateEnemyLoot({
    required String enemyType,
    required int playerLevel,
  }) {
    final pool = _getEnemyLootPool(enemyType);
    return generateLoot(
      playerLevel: playerLevel,
      maxRarity: _getEnemyMaxRarity(enemyType),
      itemPool: pool,
    );
  }

  /// Pool de loot específico por tipo de enemigo
  List<InventoryItem> _getEnemyLootPool(String enemyType) {
    switch (enemyType.toLowerCase()) {
      case 'slime':
        return [
          ItemDatabase.slimeResidue,
          ItemDatabase.potion,
          ItemDatabase.clothRobe,
        ];

      case 'goblin':
        return [
          ItemDatabase.goblinScimitar,
          ItemDatabase.rustySword,
          ItemDatabase.woodenClub,
          ItemDatabase.leatherTunic,
          ItemDatabase.potion,
          ItemDatabase.potionMedium,
        ];

      case 'bat':
        return [
          ItemDatabase.huntingBow,
          ItemDatabase.shadowDagger,
          ItemDatabase.clothRobe,
          ItemDatabase.monkRobes,
          ItemDatabase.potion,
        ];

      case 'skeleton':
        return [
          ItemDatabase.rustySword,
          ItemDatabase.steelSword,
          ItemDatabase.chainmail,
          ItemDatabase.monkRobes,
          ItemDatabase.potionMedium,
        ];

      default:
        return _getAllItems();
    }
  }

  /// Rareza maxima que puede dropear cada tipo de enemigo
  ItemRarity _getEnemyMaxRarity(String enemyType) {
    switch (enemyType.toLowerCase()) {
      case 'slime':
        return ItemRarity.common;
      case 'goblin':
        return ItemRarity.uncommon;
      case 'bat':
        return ItemRarity.epic;
      case 'skeleton':
        return ItemRarity.epic;
      default:
        return ItemRarity.uncommon;
    }
  }

  /// Obtener todos los items del juego (para uso general)
  List<InventoryItem> _getAllItems() {
    return [
      ItemDatabase.potion,
      ItemDatabase.potionMedium,
      ItemDatabase.potionLarge,

      ItemDatabase.rustySword,
      ItemDatabase.woodenClub,
      ItemDatabase.huntingBow,

      ItemDatabase.goblinScimitar,
      ItemDatabase.steelSword,
      ItemDatabase.battleAxe,

      ItemDatabase.vampiricBlade,
      ItemDatabase.flameTongue,
      ItemDatabase.shadowDagger,

      ItemDatabase.reapersScythe,

      ItemDatabase.bladeOfEternity,

      ItemDatabase.leatherTunic,
      ItemDatabase.clothRobe,

      ItemDatabase.chainmail,
      ItemDatabase.studledLeather,

      ItemDatabase.thornmail,
      ItemDatabase.dragonscale,
      ItemDatabase.monkRobes,

      ItemDatabase.etherealPlate,
      ItemDatabase.archmageVestments,

      ItemDatabase.armorOfTheAncients,
    ];
  }

  /// Para bosses - garantiza al menos 1 item raro+
  InventoryItem generateBossLoot({
    required int playerLevel,
    required String bossName,
  }) {
    final pool = _getAllItems().where((item) {
      return item.rarity.index >= ItemRarity.rare.index;
    }).toList();

    return generateLoot(
      playerLevel: playerLevel,
      maxRarity: ItemRarity.legendary,
      itemPool: pool,
    )!;
  }
}
