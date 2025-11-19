// lib/ui/combat_inventory_ui.dart

import 'package:flutter/material.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';

class CombatInventoryUI extends StatelessWidget {
  final RenegadeDungeonGame game;
  const CombatInventoryUI({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // Filtramos el inventario para obtener SOLO los objetos usables.
    final usableItems = game.player.inventory.value
        .where((slot) => slot.item.isUsable)
        .toList();

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white54),
          ),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Usar Objeto', style: TextStyle(color: Colors.white, fontSize: 24)),
              const SizedBox(height: 16),
              
              // Si no hay objetos usables, mostramos un mensaje.
              if (usableItems.isEmpty)
                const Text('No tienes objetos usables.', style: TextStyle(color: Colors.grey)),
              
              // Creamos una lista de objetos.
              ...usableItems.map((slot) => ListTile(
                    title: Text(slot.item.name, style: const TextStyle(color: Colors.white)),
                    trailing: Text('x${slot.quantity}', style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      game.combatManager.playerUseItem(slot);
                      // En el siguiente paso, esto usará el objeto y pasará el turno.
                      print('¡Usar ${slot.item.name}!');
                      game.overlays.remove('CombatInventoryUI'); // Cierra este menú
                    },
                  )),
              
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Cierra el menú de objetos sin hacer nada.
                  game.overlays.remove('CombatInventoryUI');
                },
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}