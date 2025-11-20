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

class StatusEffect {
  final String name;
  final int duration; // Turnos
  final Map<String, dynamic> effects;

  const StatusEffect({
    required this.name,
    required this.duration,
    required this.effects,
  });
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
