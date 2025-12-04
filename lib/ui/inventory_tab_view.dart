
import 'package:flutter/material.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/models/item_rarity.dart';

class InventoryTabView extends StatelessWidget {
  final RenegadeDungeonGame game;
  const InventoryTabView({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<InventorySlot>>(
      valueListenable: game.player.inventory,
      builder: (context, inventory, child) {
        if (inventory.isEmpty) {
          return const Center(
            child: Text('El inventario está vacío.',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          );
        }

        return ListView.builder(
          itemCount: inventory.length,
          itemBuilder: (context, index) {
            final slot = inventory[index];
            final bool isUsable = slot.item.isUsable;

            final rarityConfig = RarityConfig.getConfig(slot.item.rarity);

            String subtitle = slot.item.description;
            subtitle += '\n💰 ${slot.item.value}g';
            if (slot.item.levelRequirement > 1) {
              subtitle += ' • Nivel ${slot.item.levelRequirement}';
            }

            if (slot.item is EquipmentItem) {
              final eq = slot.item as EquipmentItem;
              final stats = <String>[];
              if (eq.attackBonus != 0)
                stats.add(
                    'ATK ${eq.attackBonus > 0 ? '+' : ''}${eq.attackBonus}');
              if (eq.defenseBonus != 0)
                stats.add(
                    'DEF ${eq.defenseBonus > 0 ? '+' : ''}${eq.defenseBonus}');
              if (eq.speedBonus != 0)
                stats
                    .add('SPD ${eq.speedBonus > 0 ? '+' : ''}${eq.speedBonus}');
              if (stats.isNotEmpty) {
                subtitle += '\n${stats.join(' • ')}';
              }

              if (eq.uniquePassives.isNotEmpty) {
                subtitle +=
                    '\n✨ ${eq.uniquePassives.map((p) => p.name).join(', ')}';
              }
            }

            return ListTile(
              title: Text(
                '${rarityConfig.displayName}: ${slot.item.name}',
                style: TextStyle(
                  color: rarityConfig.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'x${slot.quantity}',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(width: 16),
                  if (isUsable)
                    ElevatedButton(
                      onPressed: () {
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
