// lib/ui/pause_menu_ui.dart

import 'package:flutter/material.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/ui/status_tab_view.dart';
import 'package:renegade_dungeon/ui/inventory_tab_view.dart';

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
                    // Este no es 'const' porque depende de 'game'
                    StatusTabView(game: game),
                    InventoryTabView(game: game),
                    const Center(child: Text('Aquí mostraremos el equipamiento del jugador.', style: TextStyle(color: Colors.white))),
                    const Center(child: Text('Aquí, en el futuro, podríamos mostrar un mapa.', style: TextStyle(color: Colors.white))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}