// lib/utils/damage_calculator.dart

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
    dynamic attackerStats, // PlayerStats para chequear passives
  }) {
    // 1. Daño base de la habilidad
    int baseDamage = ability.effect.baseDamage;

    // 2. Aplicar multiplicador
    double scaledDamage = baseDamage * ability.effect.damageMultiplier;

    // 3. Añadir Attack del atacante
    int totalDamage = scaledDamage.round() + attackerAtk;

    // 4. Restar defensa
    int damageAfterDefense = totalDamage - defenderDef;

    // 5. Aplicar crítico (base 1.5x, puede aumentar con passive)
    bool isCrit = _random.nextDouble() < critChance;
    double critMultiplier = 1.5;

    if (isCrit) {
      // Check for crit damage bonus passive
      if (attackerStats != null) {
        try {
          final critBonus =
              attackerStats.getPassiveValue(PassiveType.critDamageBonus);
          if (critBonus > 0) {
            critMultiplier += critBonus / 100; // +50 → 1.5 becomes 2.0
            print('💥 ¡CRÍTICO con Bonus! Multiplicador: ${critMultiplier}x');
          } else {
            print('💥 ¡CRÍTICO! Daño x$critMultiplier');
          }
        } catch (e) {
          // attackerStats doesn't have getPassiveValue
          print('💥 ¡CRÍTICO! Daño x$critMultiplier');
        }
      } else {
        print('💥 ¡CRÍTICO! Daño x$critMultiplier');
      }
      damageAfterDefense = (damageAfterDefense * critMultiplier).round();
    }

    // 6. Mínimo de daño: 1
    int finalDamage = max(1, damageAfterDefense);

    print(
        'Daño calculado: Base=$baseDamage x${ability.effect.damageMultiplier} + Atk=$attackerAtk - Def=$defenderDef = $finalDamage${isCrit ? ' (CRIT)' : ''}');

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
