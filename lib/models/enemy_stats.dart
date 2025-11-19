// lib/models/enemy_stats.dart

import 'package:flutter/foundation.dart';
import 'package:renegade_dungeon/models/inventory_item.dart'; // Importa los modelos de objetos

class EnemyStats {
  final int maxHp;
  final int attack;
  final int defense;
  final int xpValue;

  // Un mapa que asocia un objeto con su probabilidad de drop (de 0.0 a 1.0).
  final Map<InventoryItem, double> lootTable;

  late final ValueNotifier<int> currentHp;

  EnemyStats({
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.xpValue,
    // Por defecto, un enemigo no suelta nada.
    this.lootTable = const {},
  }) {
    currentHp = ValueNotifier(maxHp);
  }

  void takeDamage(int amount) {
    final damageDealt = (amount - defense).clamp(1, 999);
    currentHp.value = (currentHp.value - damageDealt).clamp(0, maxHp);
  }
}