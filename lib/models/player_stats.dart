// lib/models/player_stats.dart

import 'package:flutter/foundation.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/components/player.dart';
import 'dart:math';

class PlayerStats {
  late final Player player;
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
  ValueNotifier<int> get attack => ValueNotifier(
    baseAttack.value + (equippedItems.value[EquipmentSlot.weapon]?.attackBonus ?? 0)
  );
  ValueNotifier<int> get defense => ValueNotifier(
    baseDefense.value + (equippedItems.value[EquipmentSlot.armor]?.defenseBonus ?? 0)
  );

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
    attack.value += 3;
    defense.value += 2;

    // Restauramos toda la vida y el maná
    currentHp.value = maxHp.value;
    currentMp.value = maxMp.value;
    
    print('¡SUBISTE DE NIVEL! Ahora eres nivel ${level.value}');
  }

  void takeDamage(int amount) {
    final damageDealt = (amount - defense.value).clamp(1, 999);
    currentHp.value = (currentHp.value - damageDealt).clamp(0, maxHp.value);
  }

  void restoreHealth(int amount) {
    currentHp.value = (currentHp.value + amount).clamp(0, maxHp.value);
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
    
    print('Equipado: ${newItem.name}. Nuevo Ataque: ${attack.value}, Nueva Defensa: ${defense.value}');
  }
}