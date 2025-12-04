// lib/ui/equipment_tab_view.dart

import 'package:flutter/material.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';

class EquipmentTabView extends StatelessWidget {
  final RenegadeDungeonGame game;
  const EquipmentTabView({super.key, required this.game});

  // Un widget de ayuda para mostrar una ranura de equipo equipada.
  Widget _buildEquippedSlot(EquipmentSlot slot, EquipmentItem? item) {
    final String slotName = slot == EquipmentSlot.weapon ? 'Arma' : 'Armadura';

    return ListTile(
      leading: Icon(slot == EquipmentSlot.weapon ? Icons.gavel : Icons.shield,
          color: Colors.white),
      title: Text(
        '$slotName: ${item?.name ?? 'Vacío'}',
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        item?.description ?? 'No tienes nada equipado en esta ranura.',
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: item != null
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
              ),
              onPressed: () {
                game.player.unequipItem(slot);
              },
              child: const Text('Desequipar'),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // --- SECCIÓN 1: EQUIPADO ACTUALMENTE ---
          const Text('Equipado Actualmente',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const Divider(color: Colors.grey),
          // Este ValueListenableBuilder se actualiza cuando el equipo cambia.
          ValueListenableBuilder<Map<EquipmentSlot, EquipmentItem>>(
            valueListenable: game.player.stats.equippedItems,
            builder: (context, equipped, child) {
              return Column(
                children: [
                  _buildEquippedSlot(
                      EquipmentSlot.weapon, equipped[EquipmentSlot.weapon]),
                  _buildEquippedSlot(
                      EquipmentSlot.armor, equipped[EquipmentSlot.armor]),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // --- SECCIÓN 2: EQUIPABLES EN INVENTARIO ---
          const Text('Equipables en Inventario',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const Divider(color: Colors.grey),

          // Removed Expanded, added shrinkWrap to ListView
          ValueListenableBuilder<List<InventorySlot>>(
            valueListenable: game.player.inventory,
            builder: (context, inventory, child) {
              // --- ¡LA SOLUCIÓN! ---
              // La lista de objetos equipables se calcula aquí DENTRO,
              // cada vez que el inventario se actualiza.
              final equipableItems = inventory
                  .where((slot) => slot.item is EquipmentItem)
                  .toList();

              if (equipableItems.isEmpty) {
                return const Center(
                    child: Text(
                        'No tienes objetos equipables en el inventario.',
                        style: TextStyle(color: Colors.white)));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: equipableItems.length,
                itemBuilder: (context, index) {
                  final slot = equipableItems[index];
                  return ListTile(
                    title: Text(slot.item.name,
                        style: const TextStyle(color: Colors.white)),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Llama al método para equipar el objeto.
                        game.player.equipItem(slot);
                      },
                      child: const Text('Equipar'),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
