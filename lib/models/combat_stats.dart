// lib/models/combat_stats.dart

import 'package:flutter/foundation.dart';

class CombatStats {
  // Estadísticas base
  final ValueNotifier<int> currentHp;
  final ValueNotifier<int> maxHp;
  final ValueNotifier<int> currentMp;
  final ValueNotifier<int> maxMp;

  // Sistema de Ultimate
  final ValueNotifier<int> ultMeter; // 0-100
  final int ultCost = 100;

  // Velocidad (determina orden de turnos)
  final ValueNotifier<int> speed;

  // Estadísticas de combate
  final ValueNotifier<int> attack;
  final ValueNotifier<int> defense;
  final ValueNotifier<double> critChance; // 0.0 - 1.0

  CombatStats({
    required int initialHp,
    required int initialMaxHp,
    required int initialMp,
    required int initialMaxMp,
    int initialSpeed = 10,
    int initialAttack = 10,
    int initialDefense = 5,
    double initialCritChance = 0.1,
  })  : currentHp = ValueNotifier(initialHp),
        maxHp = ValueNotifier(initialMaxHp),
        currentMp = ValueNotifier(initialMp),
        maxMp = ValueNotifier(initialMaxMp),
        ultMeter = ValueNotifier(0),
        speed = ValueNotifier(initialSpeed),
        attack = ValueNotifier(initialAttack),
        defense = ValueNotifier(initialDefense),
        critChance = ValueNotifier(initialCritChance);

  // Métodos de gestión de recursos
  void takeDamage(int amount) {
    final damageDealt = (amount - defense.value).clamp(1, 999);
    currentHp.value = (currentHp.value - damageDealt).clamp(0, maxHp.value);

    // Ganar ULT al recibir daño
    gainUltCharge(10);
  }

  void heal(int amount) {
    currentHp.value = (currentHp.value + amount).clamp(0, maxHp.value);
  }

  void spendMp(int amount) {
    currentMp.value = (currentMp.value - amount).clamp(0, maxMp.value);
  }

  void restoreMp(int amount) {
    currentMp.value = (currentMp.value + amount).clamp(0, maxMp.value);
  }

  void gainUltCharge(int amount) {
    ultMeter.value = (ultMeter.value + amount).clamp(0, 100);
  }

  void spendUlt() {
    ultMeter.value = 0;
  }

  bool get isDead => currentHp.value <= 0;

  void dispose() {
    currentHp.dispose();
    maxHp.dispose();
    currentMp.dispose();
    maxMp.dispose();
    ultMeter.dispose();
    speed.dispose();
    attack.dispose();
    defense.dispose();
    critChance.dispose();
  }
}
