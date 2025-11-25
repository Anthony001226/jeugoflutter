// lib/models/combat_ability.dart

enum AbilityType {
  basic, // Sin costo, daño base
  strong, // Cuesta MP, más daño
  skill, // Habilidad única del personaje
  ultimate, // Requiere barra llena
}

enum TargetType {
  singleEnemy, // Un solo enemigo
  allEnemies, // Todos los enemigos
  self, // El que usa la habilidad
  singleAlly, // Un aliado
  allAllies, // Todos los aliados
}

/// Types of status effects that can be applied in combat
enum StatusEffectType {
  attackBuff, // Aumenta ataque
  defenseBuff, // Aumenta defensa
  speedBuff, // Aumenta velocidad
  attackDebuff, // Reduce ataque
  defenseDebuff, // Reduce defensa
  speedDebuff, // Reduce velocidad
  poison, // Daño por turno
  burn, // Daño por turno (fuego)
  regeneration, // Cura por turno
  stun, // Salta turno
  // Future Phase 7 effects will be added here
}

/// Represents a temporary status effect in combat
class StatusEffect {
  final StatusEffectType type;
  final String name;
  final String description;
  int remainingTurns;
  final double value; // Multiplier (for %) or flat value
  final bool isPercentage; // true = multiplier, false = flat bonus

  StatusEffect({
    required this.type,
    required this.name,
    required this.description,
    required int duration,
    required this.value,
    this.isPercentage = true,
  }) : remainingTurns = duration;

  /// Decrements the duration by 1 turn
  void tick() {
    if (remainingTurns > 0) {
      remainingTurns--;
    }
  }

  /// Whether the effect has expired
  bool get isExpired => remainingTurns <= 0;

  /// Create a copy of this effect (for applying to multiple targets)
  StatusEffect copy() {
    return StatusEffect(
      type: type,
      name: name,
      description: description,
      duration: remainingTurns,
      value: value,
      isPercentage: isPercentage,
    );
  }

  @override
  String toString() => '$name ($remainingTurns turnos)';

  // Predefined common effects
  static StatusEffect defenseBuffStrong({int duration = 3}) {
    return StatusEffect(
      type: StatusEffectType.defenseBuff,
      name: 'Guardia',
      description: '+50% DEF',
      duration: duration,
      value: 0.5,
      isPercentage: true,
    );
  }

  static StatusEffect attackBuff({int duration = 3, double boost = 0.3}) {
    return StatusEffect(
      type: StatusEffectType.attackBuff,
      name: 'Fuerza',
      description: '+${(boost * 100).toInt()}% ATK',
      duration: duration,
      value: boost,
      isPercentage: true,
    );
  }

  static StatusEffect poison({int duration = 3, double damagePercent = 0.1}) {
    return StatusEffect(
      type: StatusEffectType.poison,
      name: 'Envenenado',
      description: '${(damagePercent * 100).toInt()}% HP por turno',
      duration: duration,
      value: damagePercent,
      isPercentage: true,
    );
  }

  static StatusEffect regeneration({int duration = 3, int healPerTurn = 5}) {
    return StatusEffect(
      type: StatusEffectType.regeneration,
      name: 'Regeneración',
      description: '+$healPerTurn HP por turno',
      duration: duration,
      value: healPerTurn.toDouble(),
      isPercentage: false,
    );
  }
}

class AbilityEffect {
  final int baseDamage;
  final double damageMultiplier;
  final List<StatusEffect> statusEffects;
  final TargetType targetType;
  final int ultGain; // Cuánto ULT genera al usar

  const AbilityEffect({
    required this.baseDamage,
    this.damageMultiplier = 1.0,
    this.statusEffects = const [],
    required this.targetType,
    this.ultGain = 0,
  });
}

class CombatAbility {
  final String name;
  final String description;
  final AbilityType type;
  final int mpCost;
  final int ultCost; // 0-100, solo para ultimates
  final AbilityEffect effect;

  // Animación asociada (por ahora usaremos la que ya existe)
  final String animationKey;

  const CombatAbility({
    required this.name,
    required this.description,
    required this.type,
    this.mpCost = 0,
    this.ultCost = 0,
    required this.effect,
    this.animationKey = 'idle',
  });

  bool canUse(int currentMp, int currentUlt) {
    if (type == AbilityType.ultimate) {
      return currentUlt >= ultCost;
    }
    return currentMp >= mpCost;
  }

  String getCostText() {
    if (type == AbilityType.ultimate) {
      return '$ultCost ULT';
    } else if (mpCost > 0) {
      return '$mpCost MP';
    }
    return 'Gratis';
  }
}
