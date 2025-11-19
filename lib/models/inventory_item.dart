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
}