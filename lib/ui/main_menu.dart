// lib/ui/main_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class MainMenu extends StatelessWidget {
  final RenegadeDungeonGame game;
  const MainMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        // --- ¡AQUÍ ESTÁ EL CAMBIO! ---
        // Envolvemos la columna con un Padding para empujarla hacia abajo.
        child: Padding(
          // Ajusta este valor (200.0) para mover los botones más arriba o más abajo.
          padding: const EdgeInsets.only(top: 200.0), 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            // Botón Jugar
            ElevatedButton(
              onPressed: () {
                // Navega al menú de selección de slots
                game.router.pushNamed('slot-selection-menu');
              },
              child: const Text('Jugar'),
            ),
            const SizedBox(height: 20),

            // Botón Ajustes (placeholder)
            ElevatedButton(
              onPressed: () {
                // Aún no hace nada
                print('Botón de Ajustes presionado');
              },
              child: const Text('Ajustes'),
            ),
            const SizedBox(height: 20),

            // Botón Salir
            ElevatedButton(
              onPressed: () {
                // Cierra la aplicación
                SystemNavigator.pop();
              },
              child: const Text('Salir'),
            ),
          ],
        ),
      ),
    ),
   );
  }
}