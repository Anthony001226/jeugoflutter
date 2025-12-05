import 'dart:math';
import 'package:renegade_dungeon/models/combat_ability.dart';
import 'package:renegade_dungeon/models/item_rarity.dart';

class DamageCalculator {
  static final Random _random = Random();

  static int calculateDamage({
    required CombatAbility ability,
    required int attackerAtk,
    required int defenderDef,
    required double critChance,
    dynamic attackerStats,
  }) {
    int baseDamage = ability.effect.baseDamage;

    double scaledDamage = baseDamage * ability.effect.damageMultiplier;

    int totalDamage = scaledDamage.round() + attackerAtk;

    int damageAfterDefense = totalDamage - defenderDef;

    bool isCrit = _random.nextDouble() < critChance;
    double critMultiplier = 1.5;

    if (isCrit) {
      if (attackerStats != null) {
        try {
          final critBonus =
              attackerStats.getPassiveValue(PassiveType.critDamageBonus);
          if (critBonus > 0) {
            critMultiplier += critBonus / 100;
          }
        } catch (e) {}
      }
      damageAfterDefense = (damageAfterDefense * critMultiplier).round();
    }

    int finalDamage = max(1, damageAfterDefense);

    return finalDamage;
  }

  static bool rollCritical(double critChance) {
    return _random.nextDouble() < critChance;
  }

  static int applyVariance(int damage) {
    double variance = 0.9 + (_random.nextDouble() * 0.2);
    return (damage * variance).round();
  }
}
