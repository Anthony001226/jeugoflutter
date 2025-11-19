// lib/ui/inventory_tab_view.dart

import 'package:flutter/material.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';

class InventoryTabView extends StatelessWidget {
  final RenegadeDungeonGame game;
  const InventoryTabView({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios en el inventario del jugador.
    return ValueListenableBuilder<List<InventorySlot>>(
      valueListenable: game.player.inventory,
      builder: (context, inventory, child) {
        // Si el inventario está vacío, mostramos un mensaje.
        if (inventory.isEmpty) {
          return const Center(
            child: Text('El inventario está vacío.', style: TextStyle(color: Colors.white, fontSize: 18)),
          );
        }

        // Si hay objetos, los mostramos en una lista.
        return ListView.builder(
          itemCount: inventory.length,
          itemBuilder: (context, index) {
            final slot = inventory[index];
            // Comprobamos si el objeto tiene un efecto usable.
              final bool isUsable = slot.item.isUsable;
              return ListTile(
              title: Text(
                slot.item.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                slot.item.description,
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min, // Para que la fila ocupe el mínimo espacio
                children: [
                  Text(
                    'x${slot.quantity}',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(width: 16),
                  // Solo mostramos el botón si el objeto es usable.
                  if (isUsable)
                    ElevatedButton(
                      onPressed: () {
                        // ¡Llamamos al método que creamos en el Player!
                        game.player.useItem(slot);
                      },
                      child: const Text('Usar'),
                    )
                ],
              ),
            );
          },
        );
      },
    );
  }
}