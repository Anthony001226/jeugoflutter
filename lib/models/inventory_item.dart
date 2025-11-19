// lib/models/inventory_item.dart
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
// La definición base de cualquier objeto en el juego.
class InventoryItem {
  final String id; // Un identificador único, ej: 'potion_hp_small'
  final String name;
  final String description;
  final void Function(RenegadeDungeonGame game) effect;
  final bool isUsable;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.description,
    // El efecto por defecto no hace nada.
    this.effect = _doNothing,
    this.isUsable = false,
    
  });
  static void doNothing(RenegadeDungeonGame game) {}
}

enum EquipmentSlot {
  weapon,
  armor,
  // En el futuro, podríamos añadir: relic, ring, etc.
}

class EquipmentItem extends InventoryItem {
  final EquipmentSlot slot;
  final int attackBonus;
  final int defenseBonus;

  const EquipmentItem({
    required super.id,
    required super.name,
    required super.description,
    required this.slot,
    this.attackBonus = 0,
    this.defenseBonus = 0,
  }) : super(isUsable: false); // Un objeto de equipo no es "usable" como una poción.
}

void _doNothing(RenegadeDungeonGame game) {
  // No hace nada
}

// Una clase para representar un "slot" o espacio en el inventario.
// Guarda el objeto y la cantidad que tenemos de él.
class InventorySlot {
  final InventoryItem item;
  int quantity;

  InventorySlot({required this.item, this.quantity = 1});
}

// --- Definiciones de Objetos Específicos ---
// Aquí es donde crearías todos los objetos de tu juego.

class ItemDatabase {
  static final InventoryItem potion = InventoryItem( // Ya no es 'const' porque tiene una función
    id: 'potion_hp_small',
    name: 'Poción Pequeña',
    description: 'Restaura 25 puntos de HP.',
    isUsable: true,
    // --- ¡AQUÍ ESTÁ LA LÓGICA! ---
    effect: (game) {
      // Le decimos al jugador que restaure 25 de vida.
      game.player.stats.restoreHealth(25);
      print('¡Usaste una poción! HP restaurado.');
    },
  );

  static final InventoryItem slimeResidue = const InventoryItem(
    id: 'residue_slime',
    name: 'Residuo de Slime',
    description: 'Una sustancia pegajosa. No se puede usar directamente.',
    // Este objeto no tiene efecto, por lo que usará el valor por defecto (_doNothing).
  );

  static final EquipmentItem rustySword = const EquipmentItem(
    id: 'sword_rusty',
    name: 'Espada Oxidada',
    description: 'Un trozo de metal apenas afilado. Es mejor que nada.',
    slot: EquipmentSlot.weapon,
    attackBonus: 2,
  );

  static final EquipmentItem leatherTunic = const EquipmentItem(
    id: 'tunic_leather',
    name: 'Túnica de Cuero',
    description: 'Ofrece una protección modesta contra los golpes.',
    slot: EquipmentSlot.armor,
    defenseBonus: 1,
  );
  
  static final EquipmentItem goblinScimitar = const EquipmentItem(
    id: 'weapon_goblin_scimitar',
    name: 'Cimitarra Goblin',
    description: 'Una hoja curva y dentada. Sorprendentemente efectiva.',
    slot: EquipmentSlot.weapon,
    attackBonus: 5, // ¡Es mejor que la Espada Oxidada!
  );
}