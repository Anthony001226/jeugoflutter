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
        child: Padding(
          padding: const EdgeInsets.only(top: 200.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón Jugar
              ElevatedButton(
                onPressed: () {
                  game.router.pushNamed('slot-selection-menu');
                },
                child: const Text('Jugar'),
              ),
              const SizedBox(height: 20),

              // Botón Ajustes (placeholder)
              ElevatedButton(
                onPressed: () {
                  print('Botón de Ajustes presionado');
                },
                child: const Text('Ajustes'),
              ),
              const SizedBox(height: 20),

              // Botón Salir con confirmación
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF2a2a2a),
                      title: const Text(
                        'Salir del Juego',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        '¿Estás seguro de que quieres cerrar el juego?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            SystemNavigator.pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD32F2F),
                          ),
                          child: const Text('Salir'),
                        ),
                      ],
                    ),
                  );
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
