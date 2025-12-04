
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
        return defensiveAbility;
      }
    }

    final usableAbilities = abilities
        .where((ability) => ability.canUse(currentMp, stats.ultMeter.value))
        .toList();

    if (usableAbilities.isEmpty) {
      return abilities.first;
    }

    usableAbilities.sort((a, b) {
      final damageA = (a.effect.baseDamage * a.effect.damageMultiplier).round();
      final damageB = (b.effect.baseDamage * b.effect.damageMultiplier).round();
      return damageB.compareTo(damageA);
    });

    CombatAbility chosenAbility;
    if (_random.nextDouble() < 0.7) {
      chosenAbility = usableAbilities.first;
    } else {
      chosenAbility = usableAbilities[_random.nextInt(usableAbilities.length)];
    }

    return chosenAbility;
  }

  /// Elige un objetivo para la habilidad (para futuro party system)
  static int chooseTarget({
    required CombatAbility ability,
    required int numberOfTargets,
  }) {
    return 0;
  }
}
