// lib/models/ability_database.dart

import 'package:renegade_dungeon/models/combat_ability.dart';

class AbilityDatabase {
  // ==================== PLAYER ABILITIES ====================

  static const CombatAbility playerBasicAttack = CombatAbility(
    name: 'Corte',
    description: 'Un ataque básico con la espada',
    type: AbilityType.basic,
    mpCost: 0,
    effect: AbilityEffect(
      baseDamage: 8,
      damageMultiplier: 1.0,
      targetType: TargetType.singleEnemy,
      ultGain: 5,
    ),
    animationKey: 'attack',
  );

  static const CombatAbility playerStrongAttack = CombatAbility(
    name: 'Tajo Poderoso',
    description: 'Un golpe cargado que inflige gran daño',
    type: AbilityType.strong,
    mpCost: 15,
    effect: AbilityEffect(
      baseDamage: 18,
      damageMultiplier: 1.2,
      targetType: TargetType.singleEnemy,
      ultGain: 3,
    ),
    animationKey: 'attack',
  );

  static const CombatAbility playerSkill = CombatAbility(
    name: 'Destello',
    description: 'Ataque de energía que daña a todos los enemigos',
    type: AbilityType.skill,
    mpCost: 25,
    effect: AbilityEffect(
      baseDamage: 12,
      damageMultiplier: 1.0,
      targetType: TargetType.allEnemies,
      ultGain: 3,
    ),
    animationKey: 'attack',
  );

  static const CombatAbility playerUltimate = CombatAbility(
    name: 'Filo Devastador',
    description: 'Un ataque devastador con todo tu poder',
    type: AbilityType.ultimate,
    ultCost: 100,
    effect: AbilityEffect(
      baseDamage: 50,
      damageMultiplier: 1.5,
      targetType: TargetType.singleEnemy,
      ultGain: 0,
    ),
    animationKey: 'attack',
  );

  // ==================== SLIME ABILITIES ====================

  static const CombatAbility slimeBasicAttack = CombatAbility(
    name: 'Salto',
    description: 'El slime salta sobre el objetivo',
    type: AbilityType.basic,
    mpCost: 0,
    effect: AbilityEffect(
      baseDamage: 4,
      damageMultiplier: 1.0,
      targetType: TargetType.singleEnemy,
    ),
    animationKey: 'attack',
  );

  // ==================== GOBLIN ABILITIES ====================

  static const CombatAbility goblinBasicAttack = CombatAbility(
    name: 'Puñalada',
    description: 'Ataca con su daga',
    type: AbilityType.basic,
    mpCost: 0,
    effect: AbilityEffect(
      baseDamage: 6,
      damageMultiplier: 1.0,
      targetType: TargetType.singleEnemy,
    ),
    animationKey: 'attack',
  );

  static const CombatAbility goblinStrongAttack = CombatAbility(
    name: 'Daga Arrojadiza',
    description: 'Lanza su daga con fuerza',
    type: AbilityType.strong,
    mpCost: 10,
    effect: AbilityEffect(
      baseDamage: 14,
      damageMultiplier: 1.1,
      targetType: TargetType.singleEnemy,
    ),
    animationKey: 'attack',
  );

  // ==================== BAT ABILITIES (NUEVO) ====================

  static const CombatAbility batBasicAttack = CombatAbility(
    name: 'Picotazo',
    description: 'Picotazo rápido con alto crítico',
    type: AbilityType.basic,
    mpCost: 0,
    effect: AbilityEffect(
      baseDamage: 5,
      damageMultiplier: 1.0,
      targetType: TargetType.singleEnemy,
    ),
    animationKey: 'attack',
  );

  // ==================== SKELETON ABILITIES (NUEVO) ====================

  static const CombatAbility skeletonBasicAttack = CombatAbility(
    name: 'Espadazo',
    description: 'Ataque con espada oxidada',
    type: AbilityType.basic,
    mpCost: 0,
    effect: AbilityEffect(
      baseDamage: 8,
      damageMultiplier: 1.0,
      targetType: TargetType.singleEnemy,
    ),
    animationKey: 'attack',
  );

  static const CombatAbility skeletonGuard = CombatAbility(
    name: 'Guardia',
    description: 'Aumenta defensa 50% por 3 turnos',
    type: AbilityType.strong,
    mpCost: 10,
    effect: AbilityEffect(
      baseDamage: 0,
      damageMultiplier: 0.0,
      targetType: TargetType.self,
      statusEffects: [
        // Use the predefined defense buff factory
        // Note: Due to const limitations, we'll apply this in combat logic
      ],
    ),
    animationKey: 'idle',
  );

  // Helper methods para obtener kits completos
  static List<CombatAbility> getPlayerAbilities() {
    return [
      playerBasicAttack,
      playerStrongAttack,
      playerSkill,
      playerUltimate,
    ];
  }

  static List<CombatAbility> getSlimeAbilities() {
    return [slimeBasicAttack];
  }

  static List<CombatAbility> getGoblinAbilities() {
    return [goblinBasicAttack, goblinStrongAttack];
  }

  static List<CombatAbility> getBatAbilities() {
    return [batBasicAttack];
  }

  static List<CombatAbility> getSkeletonAbilities() {
    return [skeletonBasicAttack, skeletonGuard];
  }

  // General method to get enemy abilities by type
  static List<CombatAbility> getEnemyAbilities(String enemyType) {
    switch (enemyType) {
      case 'slime':
        return getSlimeAbilities();
      case 'goblin':
        return getGoblinAbilities();
      case 'bat':
        return getBatAbilities();
      case 'skeleton':
        return getSkeletonAbilities();
      default:
        return getSlimeAbilities();
    }
  }
}
