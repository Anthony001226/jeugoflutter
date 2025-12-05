import 'package:flutter/foundation.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/components/player.dart';
import 'package:renegade_dungeon/models/combat_stats.dart';
import 'package:renegade_dungeon/models/combat_ability.dart';
import 'package:renegade_dungeon/models/ability_database.dart';
import 'package:renegade_dungeon/models/item_rarity.dart';
import 'dart:math';

class PlayerStats {
  late final Player player;

  late final CombatStats combatStats;
  late final List<CombatAbility> abilities;

  final ValueNotifier<int> baseAttack;
  final ValueNotifier<int> baseDefense;
  final ValueNotifier<int> baseSpeed;

  final ValueNotifier<int> level;
  final ValueNotifier<int> maxHp;
  final ValueNotifier<int> maxMp;

  final equippedItems = ValueNotifier<Map<EquipmentSlot, EquipmentItem>>({});

  ValueNotifier<int> get attack => ValueNotifier(baseAttack.value +
      (equippedItems.value[EquipmentSlot.weapon]?.attackBonus ?? 0));
  ValueNotifier<int> get defense => ValueNotifier(baseDefense.value +
      (equippedItems.value[EquipmentSlot.armor]?.defenseBonus ?? 0));

  ValueNotifier<int> get speed {
    int speedBonus = 0;
    for (var item in equippedItems.value.values) {
      speedBonus += item.speedBonus;
    }
    return ValueNotifier(baseSpeed.value + speedBonus);
  }

  late final ValueNotifier<int> currentHp;
  late final ValueNotifier<int> currentMp;
  late final ValueNotifier<int> currentXp;
  late final ValueNotifier<int> xpToNextLevel;

  final Set<String> defeatedBosses = {};
  final Set<String> completedQuests = {};

  final ValueNotifier<int> gold = ValueNotifier(0);
  final ValueNotifier<int> gems = ValueNotifier(0);

  PlayerStats({
    required int initialLevel,
    required int initialMaxHp,
    required int initialMaxMp,
    required int initialAttack,
    required int initialDefense,
    int initialSpeed = 10,
  })  : level = ValueNotifier(initialLevel),
        maxHp = ValueNotifier(initialMaxHp),
        maxMp = ValueNotifier(initialMaxMp),
        baseAttack = ValueNotifier(initialAttack),
        baseDefense = ValueNotifier(initialDefense),
        baseSpeed = ValueNotifier(initialSpeed) {
    currentHp = ValueNotifier(maxHp.value);
    currentMp = ValueNotifier(maxMp.value);
    currentXp = ValueNotifier(0);
    xpToNextLevel = ValueNotifier(_calculateXpForLevel(initialLevel));

    combatStats = CombatStats(
      initialHp: maxHp.value,
      initialMaxHp: maxHp.value,
      initialMp: maxMp.value,
      initialMaxMp: maxMp.value,
      initialSpeed: 10,
      initialAttack: initialAttack,
      initialDefense: initialDefense,
      initialCritChance: 0.1,
    );

    abilities = AbilityDatabase.getPlayerAbilities();

    _syncCombatStats();
  }

  void _syncCombatStats() {
    combatStats.currentHp.value = currentHp.value;
    combatStats.maxHp.value = maxHp.value;
    combatStats.currentMp.value = currentMp.value;
    combatStats.maxMp.value = maxMp.value;
    combatStats.attack.value = attack.value;
    combatStats.defense.value = defense.value;
  }

  int _calculateXpForLevel(int level) {
    return (100 * pow(level, 1.5)).round();
  }

  void gainXp(int amount) {
    currentXp.value += amount;
    if (currentXp.value >= xpToNextLevel.value) {
      levelUp();
    }
  }

  void levelUp() {
    final xpOverflow = currentXp.value - xpToNextLevel.value;
    level.value++;
    currentXp.value = xpOverflow;
    xpToNextLevel.value = _calculateXpForLevel(level.value);

    maxHp.value += 15;
    maxMp.value += 5;
    baseAttack.value += 3;
    baseDefense.value += 2;

    currentHp.value = maxHp.value;
    currentMp.value = maxMp.value;

    _syncCombatStats();
  }

  void takeDamage(int amount) {
    final damageDealt = (amount - defense.value).clamp(1, 999);
    currentHp.value = (currentHp.value - damageDealt).clamp(0, maxHp.value);

    combatStats.currentHp.value = currentHp.value;

    combatStats.gainUltCharge(10);
  }

  void restoreHealth(int amount) {
    currentHp.value = (currentHp.value + amount).clamp(0, maxHp.value);
    combatStats.currentHp.value = currentHp.value;
  }

  void equipItem(EquipmentItem newItem) {
    final currentItem = equippedItems.value[newItem.slot];

    if (currentItem != null) {
      player.addItem(currentItem);
    }

    final newMap = Map<EquipmentSlot, EquipmentItem>.from(equippedItems.value);
    newMap[newItem.slot] = newItem;
    equippedItems.value = newMap;

    _syncCombatStats();
  }

  void loadEquipment(Map<EquipmentSlot, EquipmentItem> equipment) {
    equippedItems.value = Map.from(equipment);
    _syncCombatStats();
  }

  void unequipItem(EquipmentSlot slot) {
    if (!equippedItems.value.containsKey(slot)) {
      return;
    }

    final itemToReturn = equippedItems.value[slot]!;

    final newMap = Map<EquipmentSlot, EquipmentItem>.from(equippedItems.value);
    newMap.remove(slot);

    equippedItems.value = newMap;

    player.addItem(itemToReturn);

    _syncCombatStats();
  }

  List<UniquePassive> getActivePassives() {
    final passives = <UniquePassive>[];
    for (var item in equippedItems.value.values) {
      passives.addAll(item.uniquePassives);
    }
    return passives;
  }

  bool hasPassive(PassiveType type) {
    return getActivePassives().any((p) => p.type == type);
  }

  double getPassiveValue(PassiveType type) {
    return getActivePassives()
        .where((p) => p.type == type)
        .fold(0.0, (sum, p) => sum + p.value);
  }

  void defeatBoss(String bossId) {
    if (defeatedBosses.add(bossId)) {}
  }

  bool hasBossBeenDefeated(String bossId) {
    return defeatedBosses.contains(bossId);
  }

  void completeQuest(String questId) {
    if (completedQuests.add(questId)) {}
  }

  bool hasQuestBeenCompleted(String questId) {
    return completedQuests.contains(questId);
  }
}
