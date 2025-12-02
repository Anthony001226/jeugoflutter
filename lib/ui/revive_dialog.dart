import 'package:flutter/material.dart';
import '../game/renegade_dungeon_game.dart';

class ReviveDialog extends StatelessWidget {
  final RenegadeDungeonGame game;

  const ReviveDialog({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade700, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Skull Icon
            Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: Colors.red.shade400,
            ),

            const SizedBox(height: 16),

            // Title
            const Text(
              '¡HAS MUERTO!',
              style: TextStyle(
                color: Colors.red,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // Options
            const Text(
              'Opciones de revivir:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 20),

            // Revive Button
            ValueListenableBuilder<int>(
              valueListenable: game.player.stats.gems,
              builder: (context, gems, _) {
                final canAfford = gems >= 5;
                if (canAfford) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        game.handleRevive();
                      },
                      icon: const Icon(Icons.auto_fix_high, size: 20),
                      label: const Text(
                        'Revivir (5 💎)',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  );
                } else {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        game.openGemShop();
                      },
                      icon: const Icon(Icons.shopping_cart, size: 20),
                      label: Text(
                        'Comprar Gemas ($gems/5)',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 8),

            const Text(
              '✅ Conservas todo tu oro e items',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),

            const SizedBox(height: 20),

            // Normal Death Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  game.handleNormalDeath();
                  game.overlays.remove('ReviveDialog');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Morir Normalmente',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '❌ Pierdes 75% de tu oro',
              style: TextStyle(color: Colors.red.shade300, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
