
import 'dart:math';
import 'package:renegade_dungeon/models/combat_ability.dart';
import 'package:renegade_dungeon/models/item_rarity.dart';

class DamageCalculator {
  static final Random _random = Random();

  /// Calcula el daño final de una habilidad
  ///
  /// Fórmula:
  /// 1. Daño base de la habilidad
  /// 2. Aplicar multiplicador
  /// 3. Añadir Attack del atacante
  /// 4. Restar Defense del defensor
  /// 5. Aplicar crítico si corresponde (con bonus de passive si existe)
  /// 6. Mínimo de daño: 1
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
        } catch (e) {
        }
      }
      damageAfterDefense = (damageAfterDefense * critMultiplier).round();
    }

    int finalDamage = max(1, damageAfterDefense);

    return finalDamage;
  }

  /// Calcula si un ataque es crítico
  static bool rollCritical(double critChance) {
    return _random.nextDouble() < critChance;
  }

  /// Aplica variación aleatoria al daño (±10%)
  static int applyVariance(int damage) {
    double variance = 0.9 + (_random.nextDouble() * 0.2);
    return (damage * variance).round();
  }
}
