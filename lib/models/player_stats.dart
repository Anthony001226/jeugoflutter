// lib/models/player_stats.dart

import 'package:flutter/foundation.dart';
import 'dart:math';

class PlayerStats {
  // Stats Base
  final ValueNotifier<int> level;
  final ValueNotifier<int> maxHp;
  final ValueNotifier<int> maxMp;
  final ValueNotifier<int> attack;
  final ValueNotifier<int> defense;

  // Stats que cambian constantemente
  late final ValueNotifier<int> currentHp;
  late final ValueNotifier<int> currentMp;
  late final ValueNotifier<int> currentXp;
  late final ValueNotifier<int> xpToNextLevel;

  PlayerStats({
    required int initialLevel,
    required int initialMaxHp,
    required int initialMaxMp,
    required int initialAttack,
    required int initialDefense,
  })  : level = ValueNotifier(initialLevel),
        maxHp = ValueNotifier(initialMaxHp),
        maxMp = ValueNotifier(initialMaxMp),
        attack = ValueNotifier(initialAttack),
        defense = ValueNotifier(initialDefense) {
    currentHp = ValueNotifier(maxHp.value);
    currentMp = ValueNotifier(maxMp.value);
    currentXp = ValueNotifier(0);
    xpToNextLevel = ValueNotifier(_calculateXpForLevel(initialLevel));
  }

  // Fórmula para calcular la XP necesaria para el siguiente nivel
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
    // Restamos la XP necesaria y conservamos el sobrante
    final xpOverflow = currentXp.value - xpToNextLevel.value;
    level.value++;
    currentXp.value = xpOverflow;
    xpToNextLevel.value = _calculateXpForLevel(level.value);

    // ¡Mejora de estadísticas!
    maxHp.value += 15;
    maxMp.value += 5;
    attack.value += 3;
    defense.value += 2;

    // Restauramos toda la vida y el maná
    currentHp.value = maxHp.value;
    currentMp.value = maxMp.value;
    
    print('¡SUBISTE DE NIVEL! Ahora eres nivel ${level.value}');
  }

  void takeDamage(int amount) {
    final damageDealt = (amount - defense.value).clamp(1, 999);
    currentHp.value = (currentHp.value - damageDealt).clamp(0, maxHp.value);
  }

  void restoreHealth(int amount) {
    currentHp.value = (currentHp.value + amount).clamp(0, maxHp.value);
  }
}