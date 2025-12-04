
import 'package:flutter/material.dart';

/// Enum que define los niveles de rareza de items
enum ItemRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

/// Configuración de cada nivel de rareza
class RarityConfig {
  final ItemRarity rarity;
  final String displayName;
  final Color color;
  final double dropWeight;
  final int minLevel;
  final double valueMultiplier;

  const RarityConfig({
    required this.rarity,
    required this.displayName,
    required this.color,
    required this.dropWeight,
    this.minLevel = 1,
    this.valueMultiplier = 1.0,
  });

  static const common = RarityConfig(
    rarity: ItemRarity.common,
    displayName: 'Común',
    color: Color(0xFFFFFFFF),
    dropWeight: 60.0,
    minLevel: 1,
    valueMultiplier: 1.0,
  );

  static const uncommon = RarityConfig(
    rarity: ItemRarity.uncommon,
    displayName: 'Poco Común',
    color: Color(0xFF1EFF00),
    dropWeight: 25.0,
    minLevel: 2,
    valueMultiplier: 2.0,
  );

  static const rare = RarityConfig(
    rarity: ItemRarity.rare,
    displayName: 'Raro',
    color: Color(0xFF0070DD),
    dropWeight: 10.0,
    minLevel: 5,
    valueMultiplier: 4.0,
  );

  static const epic = RarityConfig(
    rarity: ItemRarity.epic,
    displayName: 'Épico',
    color: Color(0xFFA335EE),
    dropWeight: 4.0,
    minLevel: 8,
    valueMultiplier: 8.0,
  );

  static const legendary = RarityConfig(
    rarity: ItemRarity.legendary,
    displayName: 'Legendario',
    color: Color(0xFFFF8000),
    dropWeight: 1.0,
    minLevel: 12,
    valueMultiplier: 15.0,
  );

  /// Obtener config por rareza
  static RarityConfig getConfig(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:
        return common;
      case ItemRarity.uncommon:
        return uncommon;
      case ItemRarity.rare:
        return rare;
      case ItemRarity.epic:
        return epic;
      case ItemRarity.legendary:
        return legendary;
    }
  }

  /// Calcular drop chance ajustado por nivel del jugador
  static double calculateDropChance(ItemRarity rarity, int playerLevel) {
    final config = getConfig(rarity);

    if (playerLevel < config.minLevel) {
      return 0.0;
    }

    return config.dropWeight;
  }
}

/// Tipos de efectos pasivos únicos
enum PassiveType {
  lifeSteal,
  thorns,
  critDamageBonus,
  critChanceBonus,
  ultChargeOnHit,
  ultChargeOnKill,
  mpRegen,
  hpRegen,
  damageReduction,
  dodgeChance,
  counterattack,
  poisonOnHit,
  burnOnHit,
  stunChance,
  firstStrike,
  doubleHit,
}

/// Definición de un efecto pasivo único
class UniquePassive {
  final String id;
  final String name;
  final String description;
  final PassiveType type;
  final double value;

  const UniquePassive({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
  });

  static const lifeSteal10 = UniquePassive(
    id: 'life_steal_10',
    name: 'Robo de Vida I',
    description: '10% del daño infligido restaura HP',
    type: PassiveType.lifeSteal,
    value: 0.10,
  );

  static const lifeSteal25 = UniquePassive(
    id: 'life_steal_25',
    name: 'Robo de Vida III',
    description: '25% del daño infligido restaura HP',
    type: PassiveType.lifeSteal,
    value: 0.25,
  );

  static const thorns15 = UniquePassive(
    id: 'thorns_15',
    name: 'Espinas',
    description: 'Refleja el 15% del daño recibido',
    type: PassiveType.thorns,
    value: 0.15,
  );

  static const critBonus50 = UniquePassive(
    id: 'crit_bonus_50',
    name: 'Devastador',
    description: 'Los críticos hacen +50% de daño',
    type: PassiveType.critDamageBonus,
    value: 0.50,
  );

  static const ultOnKill30 = UniquePassive(
    id: 'ult_kill_30',
    name: 'Sed de Sangre',
    description: '+30 carga de Ultimate al matar',
    type: PassiveType.ultChargeOnKill,
    value: 30.0,
  );

  static const mpRegen5 = UniquePassive(
    id: 'mp_regen_5',
    name: 'Meditación',
    description: 'Regenera 5 MP por turno',
    type: PassiveType.mpRegen,
    value: 5.0,
  );

  static const hpRegen3 = UniquePassive(
    id: 'hp_regen_3',
    name: 'Regeneración',
    description: 'Regenera 3% HP máximo por turno',
    type: PassiveType.hpRegen,
    value: 0.03,
  );

  static const dodge15 = UniquePassive(
    id: 'dodge_15',
    name: 'Evasión',
    description: '15% probabilidad de evadir ataques',
    type: PassiveType.dodgeChance,
    value: 0.15,
  );

  static const counter20 = UniquePassive(
    id: 'counter_20',
    name: 'Contraataque',
    description: '20% probabilidad de contraatacar',
    type: PassiveType.counterattack,
    value: 0.20,
  );

  static const firstStrike = UniquePassive(
    id: 'first_strike',
    name: 'Primer Golpe',
    description: 'Siempre atacas primero en combate',
    type: PassiveType.firstStrike,
    value: 1.0,
  );
}
