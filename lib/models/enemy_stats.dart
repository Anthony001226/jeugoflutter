// lib/models/enemy_stats.dart

import 'package:flutter/foundation.dart';

class EnemyStats {
  final int maxHp;
  final int attack;
  final int defense;
  final int xpValue; // NUEVO: Cantidad de XP que otorga

  late final ValueNotifier<int> currentHp;

  EnemyStats({
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.xpValue, // NUEVO
  }) {
    currentHp = ValueNotifier(maxHp);
  }

  void takeDamage(int amount) {
    final damageDealt = (amount - defense).clamp(1, 999);
    currentHp.value = (currentHp.value - damageDealt).clamp(0, maxHp);
  }
}