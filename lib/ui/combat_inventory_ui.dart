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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white54),
              ),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Usar Objeto',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Si no hay objetos usables, mostramos un mensaje.
                  if (usableItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No tienes objetos usables.',
                          style: TextStyle(color: Colors.grey)),
                    ),

                  // Creamos una lista de objetos.
                  if (usableItems.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: usableItems.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: Colors.white24, height: 1),
                        itemBuilder: (context, index) {
                          final slot = usableItems[index];
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            dense: true,
                            title: Text(slot.item.name,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14)),
                            trailing: Text('x${slot.quantity}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            onTap: () {
                              game.combatManager.playerUseItem(slot);
                              game.overlays.remove(
                                  'CombatInventoryUI'); // Cierra este menú
                            },
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        game.overlays.remove('CombatInventoryUI');
                      },
                      child: const Text('Cancelar',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
