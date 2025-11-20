// lib/utils/damage_calculator.dart

import 'dart:math';
import 'package:renegade_dungeon/models/combat_ability.dart';

class DamageCalculator {
  static final Random _random = Random();

  /// Calcula el daño final de una habilidad
  ///
  /// Fórmula:
  /// 1. Daño base de la habilidad
  /// 2. Aplicar multiplicador
  /// 3. Añadir Attack del atacante
  /// 4. Restar Defense del defensor
  /// 5. Aplicar crítico si corresponde
  /// 6. Mínimo de daño: 1
  static int calculateDamage({
    required CombatAbility ability,
    required int attackerAtk,
    required int defenderDef,
    required double critChance,
  }) {
    // 1. Daño base de la habilidad
    int baseDamage = ability.effect.baseDamage;

    // 2. Aplicar multiplicador
    double scaledDamage = baseDamage * ability.effect.damageMultiplier;

    // 3. Añadir Attack del atacante
    int totalDamage = scaledDamage.round() + attackerAtk;

    // 4. Restar defensa
    int damageAfterDefense = totalDamage - defenderDef;

    // 5. Aplicar crítico (50% más de daño)
    bool isCrit = _random.nextDouble() < critChance;
    if (isCrit) {
      damageAfterDefense = (damageAfterDefense * 1.5).round();
      print('💥 ¡CRÍTICO! Daño x1.5');
    }

    // 6. Mínimode daño: 1
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
