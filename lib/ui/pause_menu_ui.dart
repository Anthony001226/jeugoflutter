// lib/ui/pause_menu_ui.dart

import 'package:flutter/material.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/ui/status_tab_view.dart';
import 'package:renegade_dungeon/ui/inventory_tab_view.dart';
import 'package:renegade_dungeon/ui/equipment_tab_view.dart';
import 'package:renegade_dungeon/ui/map_tab_view.dart';

class PauseMenuUI extends StatelessWidget {
  final RenegadeDungeonGame game;
  const PauseMenuUI({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.black.withAlpha(215),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
          child: Column(
            children: [
              const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(child: Text('ESTADO')),
                  Tab(child: Text('INVENTARIO')),
                  Tab(child: Text('EQUIPO')),
                  Tab(child: Text('MAPA')),
                ],
              ),

              const SizedBox(height: 24),

              Expanded(
                child: TabBarView(
                  children: [
                    StatusTabView(game: game),
                    InventoryTabView(game: game),
                    EquipmentTabView(game: game),
                    MapTabView(game: game),
                  ],
                ),
              ),

              // Botones de control
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón Reanudar
                  ElevatedButton.icon(
                    onPressed: () {
                      game.togglePauseMenu();
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Reanudar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Botón Volver al Menú Principal
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF2a2a2a),
                          title: const Text(
                            'Volver al Menú Principal',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            '¿Estás seguro de que quieres volver al menú?\nTu progreso se guardará automáticamente.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                // Save game before exiting
                                await game.saveGame();

                                // Reset game state to ensure clean slate for next session
                                game.reset();

                                game.state = GameState.inMenu;
                                // Removed delay to preserve user interaction token for Web Autoplay
                                game.router.pushReplacementNamed('main-menu');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD32F2F),
                              ),
                              child: const Text('Volver al Menú'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Menú Principal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
