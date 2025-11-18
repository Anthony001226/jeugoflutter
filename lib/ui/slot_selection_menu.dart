// lib/ui/main_menu.dart

import 'package:flutter/material.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class SlotSelectionMenu extends StatelessWidget {
  final RenegadeDungeonGame game;

  const SlotSelectionMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Renegade Dungeon',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 10, color: Colors.redAccent)],
              ),
            ),
            const SizedBox(height: 50),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                // Le decimos al router que navegue a la pantalla del juego.
                game.router.pushNamed('loading-screen');
              },
              child: const Text('Slot 1 - Empezar Aventura'),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.grey.shade800,
              ),
              onPressed: () {
                 // Por ahora, también inicia una nueva partida.
                 game.router.pushNamed('game-screen');
              },
              child: const Text('Slot 2 - (Vacío)'),
            ),
             const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.grey.shade800,
              ),
              onPressed: () {
                 // Por ahora, también inicia una nueva partida.
                 game.router.pushNamed('game-screen');
              },
              child: const Text('Slot 3 - (Vacío)'),
            ),
          ],
        ),
      ),
    );
  }
}