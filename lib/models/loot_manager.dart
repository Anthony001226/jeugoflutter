// lib/models/loot_manager.dart

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
    // Si no hay pool especificado, usar todos los items
    final pool = itemPool.isEmpty ? _getAllItems() : itemPool;

    // Filtrar items por nivel y rareza maxima
    final eligibleItems = pool.where((item) {
      return item.levelRequirement <= playerLevel &&
          item.rarity.index <= maxRarity.index &&
          playerLevel >= RarityConfig.getConfig(item.rarity).minLevel;
    }).toList();

    if (eligibleItems.isEmpty) return null;

    // Calcular peso total
    double totalWeight = 0.0;
    for (final item in eligibleItems) {
      totalWeight += RarityConfig.getConfig(item.rarity).dropWeight;
    }

    // Selección ponderada
    double roll = _random.nextDouble() * totalWeight;
    double currentWeight = 0.0;

    for (final item in eligibleItems) {
      currentWeight += RarityConfig.getConfig(item.rarity).dropWeight;
      if (roll <= currentWeight) {
        return item;
      }
    }

    // Fallback (no deberia llegar aqui)
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
          ItemDatabase.monkRobes, // ← Rare regen armor
          ItemDatabase.potion,
        ];

      case 'skeleton':
        return [
          ItemDatabase.rustySword,
          ItemDatabase.steelSword,
          ItemDatabase.chainmail,
          ItemDatabase.monkRobes, // ← Rare regen armor
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
        return ItemRarity.epic; // ← Upgraded to drop archmage vestments
      case 'skeleton':
        return ItemRarity.epic; // ← Upgraded to drop archmage vestments
      default:
        return ItemRarity.uncommon;
    }
  }

  /// Obtener todos los items del juego (para uso general)
  List<InventoryItem> _getAllItems() {
    return [
      // Consumibles
      ItemDatabase.potion,
      ItemDatabase.potionMedium,
      ItemDatabase.potionLarge,

      // Common Weapons
      ItemDatabase.rustySword,
      ItemDatabase.woodenClub,
      ItemDatabase.huntingBow,

      // Uncommon Weapons
      ItemDatabase.goblinScimitar,
      ItemDatabase.steelSword,
      ItemDatabase.battleAxe,

      // Rare Weapons
      ItemDatabase.vampiricBlade,
      ItemDatabase.flameTongue,
      ItemDatabase.shadowDagger,

      // Epic Weapons
      ItemDatabase.reapersScythe,

      // Legendary Weapons
      ItemDatabase.bladeOfEternity,

      // Common Armor
      ItemDatabase.leatherTunic,
      ItemDatabase.clothRobe,

      // Uncommon Armor
      ItemDatabase.chainmail,
      ItemDatabase.studledLeather,

      // Rare Armor
      ItemDatabase.thornmail,
      ItemDatabase.dragonscale,
      ItemDatabase.monkRobes, // ← NEW

      // Epic Armor
      ItemDatabase.etherealPlate,
      ItemDatabase.archmageVestments, // ← NEW

      // Legendary Armor
      ItemDatabase.armorOfTheAncients,
    ];
  }

  /// Para bosses - garantiza al menos 1 item raro+
  InventoryItem generateBossLoot({
    required int playerLevel,
    required String bossName,
  }) {
    // Bosses siempre dropean rare o mejor
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
