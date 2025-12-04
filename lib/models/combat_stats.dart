
import 'package:flutter/foundation.dart';
import 'combat_ability.dart';

class CombatStats {
  final ValueNotifier<int> currentHp;
  final ValueNotifier<int> maxHp;
  final ValueNotifier<int> currentMp;
  final ValueNotifier<int> maxMp;

  final ValueNotifier<int> ultMeter;
  final int ultCost = 100;

  final ValueNotifier<int> speed;

  final ValueNotifier<int> attack;
  final ValueNotifier<int> defense;
  final ValueNotifier<double> critChance;

  final List<StatusEffect> activeEffects = [];
  final ValueNotifier<int> effectsVersion = ValueNotifier(0);

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


  /// Apply a status effect to this entity
  void applyEffect(StatusEffect effect) {
    activeEffects.add(effect.copy());
    effectsVersion.value++;
  }

  /// Process effects at the start of this entity's turn
  void tickEffects() {
    if (activeEffects.isEmpty) return;

    final expiredEffects = <StatusEffect>[];

    for (final effect in activeEffects) {
      _applyEffectTick(effect);

      effect.tick();

      if (effect.isExpired) {
        expiredEffects.add(effect);
      }
    }

    for (final expired in expiredEffects) {
      activeEffects.remove(expired);
    }

    if (expiredEffects.isNotEmpty) {
      effectsVersion.value++;
    }
  }

  /// Apply per-turn effects (poison, regeneration, etc.)
  void _applyEffectTick(StatusEffect effect) {
    switch (effect.type) {
      case StatusEffectType.poison:
      case StatusEffectType.burn:
        final damage = effect.isPercentage
            ? (maxHp.value * effect.value).round()
            : effect.value.toInt();
        currentHp.value = (currentHp.value - damage).clamp(0, maxHp.value);
        break;

      case StatusEffectType.regeneration:
        final healing = effect.isPercentage
            ? (maxHp.value * effect.value).round()
            : effect.value.toInt();
        currentHp.value = (currentHp.value + healing).clamp(0, maxHp.value);
        break;

      default:
        break;
    }
  }

  /// Clear all active effects
  void clearEffects() {
    if (activeEffects.isNotEmpty) {
      activeEffects.clear();
      effectsVersion.value++;
    }
  }

  /// Check if a specific effect type is active
  bool hasEffect(StatusEffectType type) {
    return activeEffects.any((e) => e.type == type);
  }


  /// Get effective attack including buffs/debuffs
  int get effectiveAttack {
    double modifier = 1.0;
    int flatBonus = 0;

    for (final effect in activeEffects) {
      if (effect.type == StatusEffectType.attackBuff) {
        if (effect.isPercentage) {
          modifier += effect.value;
        } else {
          flatBonus += effect.value.toInt();
        }
      } else if (effect.type == StatusEffectType.attackDebuff) {
        if (effect.isPercentage) {
          modifier -= effect.value;
        } else {
          flatBonus -= effect.value.toInt();
        }
      }
    }

    return ((attack.value * modifier) + flatBonus).round().clamp(1, 9999);
  }

  /// Get effective defense including buffs/debuffs
  int get effectiveDefense {
    double modifier = 1.0;
    int flatBonus = 0;

    for (final effect in activeEffects) {
      if (effect.type == StatusEffectType.defenseBuff) {
        if (effect.isPercentage) {
          modifier += effect.value;
        } else {
          flatBonus += effect.value.toInt();
        }
      } else if (effect.type == StatusEffectType.defenseDebuff) {
        if (effect.isPercentage) {
          modifier -= effect.value;
        } else {
          flatBonus -= effect.value.toInt();
        }
      }
    }

    return ((defense.value * modifier) + flatBonus).round().clamp(0, 9999);
  }

  /// Get effective speed including buffs/debuffs
  int get effectiveSpeed {
    double modifier = 1.0;
    int flatBonus = 0;

    for (final effect in activeEffects) {
      if (effect.type == StatusEffectType.speedBuff) {
        if (effect.isPercentage) {
          modifier += effect.value;
        } else {
          flatBonus += effect.value.toInt();
        }
      } else if (effect.type == StatusEffectType.speedDebuff) {
        if (effect.isPercentage) {
          modifier -= effect.value;
        } else {
          flatBonus -= effect.value.toInt();
        }
      }
    }

    return ((speed.value * modifier) + flatBonus).round().clamp(1, 9999);
  }


  void takeDamage(int amount) {
    final damageDealt = (amount - effectiveDefense).clamp(1, 999);
    currentHp.value = (currentHp.value - damageDealt).clamp(0, maxHp.value);

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
    effectsVersion.dispose();
  }
}
