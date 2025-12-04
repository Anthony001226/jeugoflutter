
import 'package:flutter/foundation.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';

class EnemyStats {
  final int maxHp;
  final int attack;
  final int defense;
  final int xpValue;
  final int speed;
  final int goldDrop;

  final Map<InventoryItem, double> lootTable;

  late final ValueNotifier<int> currentHp;

  EnemyStats({
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.xpValue,
    this.speed = 5,
    this.goldDrop = 10,
    this.lootTable = const {},
  }) {
    currentHp = ValueNotifier(maxHp);
  }

  void takeDamage(int amount) {
    final damageDealt = (amount - defense).clamp(1, 999);
    currentHp.value = (currentHp.value - damageDealt).clamp(0, maxHp);
  }
}
