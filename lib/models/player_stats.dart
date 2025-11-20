// lib/models/player_stats.dart

import 'package:flutter/foundation.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/components/player.dart';
import 'package:renegade_dungeon/models/combat_stats.dart';
import 'package:renegade_dungeon/models/combat_ability.dart';
import 'package:renegade_dungeon/models/ability_database.dart';
import 'dart:math';

class PlayerStats {
  late final Player player;

  // ===== NUEVO: Sistema de Combate Mejorado =====
  late final CombatStats combatStats;
  late final List<CombatAbility> abilities;

  // Stats Base (¡ahora los renombramos para que quede claro!)
  final ValueNotifier<int> baseAttack;
  final ValueNotifier<int> baseDefense;

  // ... (level, maxHp, maxMp no cambian)
  final ValueNotifier<int> level;
  final ValueNotifier<int> maxHp;
  final ValueNotifier<int> maxMp;

  // --- ¡NUEVO! El equipo que el jugador lleva puesto. ---
  final equippedItems = ValueNotifier<Map<EquipmentSlot, EquipmentItem>>({});

  // Stats Totales (¡estos ahora son getters calculados!)
  ValueNotifier<int> get attack => ValueNotifier(baseAttack.value +
      (equippedItems.value[EquipmentSlot.weapon]?.attackBonus ?? 0));
  ValueNotifier<int> get defense => ValueNotifier(baseDefense.value +
      (equippedItems.value[EquipmentSlot.armor]?.defenseBonus ?? 0));

  // ... (currentHp, currentMp, etc. no cambian)
  late final ValueNotifier<int> currentHp;
  late final ValueNotifier<int> currentMp;
  late final ValueNotifier<int> currentXp;
  late final ValueNotifier<int> xpToNextLevel;

  PlayerStats({
    required int initialLevel,
    required int initialMaxHp,
    required int initialMaxMp,
    required int initialAttack,
    required int initialDefense,
  })  : level = ValueNotifier(initialLevel),
        maxHp = ValueNotifier(initialMaxHp),
        maxMp = ValueNotifier(initialMaxMp),
        // Guardamos los valores iniciales en las stats base.
        baseAttack = ValueNotifier(initialAttack),
        baseDefense = ValueNotifier(initialDefense) {
    currentHp = ValueNotifier(maxHp.value);
    currentMp = ValueNotifier(maxMp.value);
    currentXp = ValueNotifier(0);
    xpToNextLevel = ValueNotifier(_calculateXpForLevel(initialLevel));

    // ===== INICIALIZAR NUEVO SISTEMA DE COMBATE =====
    combatStats = CombatStats(
      initialHp: maxHp.value,
      initialMaxHp: maxHp.value,
      initialMp: maxMp.value,
      initialMaxMp: maxMp.value,
      initialSpeed: 10,
      initialAttack: initialAttack,
      initialDefense: initialDefense,
      initialCritChance: 0.1,
    );

    // Cargar habilidades del jugador
    abilities = AbilityDatabase.getPlayerAbilities();

    // Sincronizar los sistemas viejo y nuevo
    _syncCombatStats();
  }

  // Sincroniza el sistema viejo con el nuevo
  void _syncCombatStats() {
    combatStats.currentHp.value = currentHp.value;
    combatStats.maxHp.value = maxHp.value;
    combatStats.currentMp.value = currentMp.value;
    combatStats.maxMp.value = maxMp.value;
    combatStats.attack.value = attack.value;
    combatStats.defense.value = defense.value;
  }

  // Fórmula para calcular la XP necesaria para el siguiente nivel
  int _calculateXpForLevel(int level) {
    return (100 * pow(level, 1.5)).round();
  }

  void gainXp(int amount) {
    currentXp.value += amount;
    if (currentXp.value >= xpToNextLevel.value) {
      levelUp();
    }
  }

  void levelUp() {
    // Restamos la XP necesaria y conservamos el sobrante
    final xpOverflow = currentXp.value - xpToNextLevel.value;
    level.value++;
    currentXp.value = xpOverflow;
    xpToNextLevel.value = _calculateXpForLevel(level.value);

    // ¡Mejora de estadísticas!
    maxHp.value += 15;
    maxMp.value += 5;
    baseAttack.value += 3;
    baseDefense.value += 2;

    // Restauramos toda la vida y el maná
    currentHp.value = maxHp.value;
    currentMp.value = maxMp.value;

    // Sincronizar con CombatStats
    _syncCombatStats();

    print('¡SUBISTE DE NIVEL! Ahora eres nivel ${level.value}');
  }

  void takeDamage(int amount) {
    final damageDealt = (amount - defense.value).clamp(1, 999);
    currentHp.value = (currentHp.value - damageDealt).clamp(0, maxHp.value);

    // Sincronizar con CombatStats
    combatStats.currentHp.value = currentHp.value;

    // Ganar ULT al recibir daño
    combatStats.gainUltCharge(10);
  }

  void restoreHealth(int amount) {
    currentHp.value = (currentHp.value + amount).clamp(0, maxHp.value);
    combatStats.currentHp.value = currentHp.value;
  }

  void equipItem(EquipmentItem newItem) {
    final currentItem = equippedItems.value[newItem.slot];

    // Si había un objeto equipado antes, lo devolvemos al inventario del jugador.
    if (currentItem != null) {
      player.addItem(currentItem);
      print('Devuelto al inventario: ${currentItem.name}');
    }

    final newMap = Map<EquipmentSlot, EquipmentItem>.from(equippedItems.value);
    newMap[newItem.slot] = newItem;
    equippedItems.value = newMap;

    // Sincronizar stats con CombatStats
    _syncCombatStats();

    print(
        'Equipado: ${newItem.name}. Nuevo Ataque: ${attack.value}, Nueva Defensa: ${defense.value}');
  }

  void unequipItem(EquipmentSlot slot) {
    // 1. Verificamos si realmente hay algo en esa ranura.
    if (!equippedItems.value.containsKey(slot)) {
      print('Nada que desequipar en la ranura $slot.');
      return;
    }

    // 2. Guardamos una referencia al objeto que vamos a quitar.
    final itemToReturn = equippedItems.value[slot]!;

    // 3. Creamos un nuevo mapa SIN el objeto de esa ranura.
    final newMap = Map<EquipmentSlot, EquipmentItem>.from(equippedItems.value);
    newMap.remove(slot);

    // 4. Actualizamos el equipo, lo que notificará a la UI y recalculará las stats.
    equippedItems.value = newMap;

    // 5. Usamos nuestra referencia al 'player' para devolver el objeto al inventario.
    player.addItem(itemToReturn);

    // Sincronizar stats con CombatStats
    _syncCombatStats();

    print(
        'Desequipado: ${itemToReturn.name}. Nuevo Ataque: ${attack.value}, Nueva Defensa: ${defense.value}');
  }
}
