// lib/game/enemy_ai.dart

import 'dart:math';
import 'package:renegade_dungeon/models/combat_ability.dart';
import 'package:renegade_dungeon/models/combat_stats.dart';

class EnemyAI {
  static final Random _random = Random();

  /// Elige la mejor habilidad para el enemigo según su estado actual
  static CombatAbility chooseAbility({
    required List<CombatAbility> abilities,
    required CombatStats stats,
  }) {
    if (abilities.isEmpty) {
      throw Exception('Enemy has no abilities!');
    }

    final currentHp = stats.currentHp.value;
    final maxHp = stats.maxHp.value;
    final currentMp = stats.currentMp.value;
    final hpPercentage = currentHp / maxHp;

    print(
        '🤖 Enemy AI: HP=${currentHp}/${maxHp} (${(hpPercentage * 100).toStringAsFixed(0)}%), MP=$currentMp');

    // 1. HP crítico - buscar habilidad defensiva
    if (hpPercentage < 0.3) {
      final defensiveAbility = abilities.firstWhere(
        (ability) =>
            ability.name.toLowerCase().contains('guard') ||
            ability.name.toLowerCase().contains('guardia') ||
            ability.effect.targetType == TargetType.self,
        orElse: () => abilities.first,
      );

      if (defensiveAbility != abilities.first &&
          defensiveAbility.canUse(currentMp, 0)) {
        print('   → HP bajo! Usando ${defensiveAbility.name}');
        return defensiveAbility;
      }
    }

    // 2. Intentar usar habilidad más fuerte disponible
    final usableAbilities = abilities
        .where((ability) => ability.canUse(currentMp, stats.ultMeter.value))
        .toList();

    if (usableAbilities.isEmpty) {
      print('   → Sin MP! Usando básica: ${abilities.first.name}');
      return abilities.first;
    }

    // Ordenar por daño base descendente
    usableAbilities.sort((a, b) {
      final damageA = (a.effect.baseDamage * a.effect.damageMultiplier).round();
      final damageB = (b.effect.baseDamage * b.effect.damageMultiplier).round();
      return damageB.compareTo(damageA);
    });

    // 70% usa la más fuerte, 30% aleatorio
    CombatAbility chosenAbility;
    if (_random.nextDouble() < 0.7) {
      chosenAbility = usableAbilities.first;
    } else {
      chosenAbility = usableAbilities[_random.nextInt(usableAbilities.length)];
    }

    print(
        '   → Eligió: ${chosenAbility.name} (${chosenAbility.effect.baseDamage} dmg, ${chosenAbility.mpCost} MP)');
    return chosenAbility;
  }

  /// Elige un objetivo para la habilidad (para futuro party system)
  static int chooseTarget({
    required CombatAbility ability,
    required int numberOfTargets,
  }) {
    // Por ahora siempre ataca al jugador (índice 0)
    return 0;
  }
}
