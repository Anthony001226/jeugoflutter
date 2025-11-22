// lib/main.dart

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:renegade_dungeon/ui/combat_ui.dart';
import 'package:renegade_dungeon/ui/loading_ui.dart';
import 'package:renegade_dungeon/ui/main_menu.dart';
import 'package:renegade_dungeon/ui/player_hud.dart';
import 'package:renegade_dungeon/ui/slot_selection_menu.dart';
import 'game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/ui/pause_menu_ui.dart';
import 'package:renegade_dungeon/ui/combat_inventory_ui.dart';
import 'package:renegade_dungeon/ui/map_transition_overlay.dart';

// El StatefulWidget que creamos está perfecto. No necesita cambios.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final RenegadeDungeonGame _game;

  @override
  void initState() {
    super.initState();
    _game = RenegadeDungeonGame();
    _game.videoPlayerControllerNotifier.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    print(
        '--- PASO 3: Reconstruyendo UI. Estado del video: ${_game.videoPlayerControllerNotifier.value == null ? "NULL" : "EXISTE Y ESTÁ INICIALIZADO: ${_game.videoPlayerControllerNotifier.value!.value.isInitialized}"} ---');
    return Stack(
      children: [
        // CAPA 1: El Video de Fondo
        if (_game.videoPlayerControllerNotifier.value != null &&
            _game.videoPlayerControllerNotifier.value!.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width:
                    _game.videoPlayerControllerNotifier.value!.value.size.width,
                height: _game
                    .videoPlayerControllerNotifier.value!.value.size.height,
                child: VideoPlayer(_game.videoPlayerControllerNotifier.value!),
              ),
            ),
          ),

        // CAPA 2: El Juego
        GameWidget<RenegadeDungeonGame>.controlled(
          gameFactory: () => _game,
          backgroundBuilder: (context) => Container(color: Colors.transparent),
          overlayBuilderMap: {
            'CombatUI': (context, game) => CombatUI(game: game),
            'PlayerHud': (context, game) => PlayerHud(game: game),
            'LoadingUI': (context, game) => const LoadingUI(),
            'MainMenu': (context, game) => MainMenu(game: game),
            'SlotSelectionMenu': (context, game) =>
                SlotSelectionMenu(game: game),
            'PauseMenuUI': (context, game) => PauseMenuUI(game: game),
            'CombatInventoryUI': (context, game) =>
                CombatInventoryUI(game: game),
            'map_transition': (context, game) => const MapTransitionOverlay(),
          },
        ),
      ],
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // --- ¡AQUÍ ESTÁ LA SOLUCIÓN! ---
  // Envolvemos nuestro widget MyApp dentro de un MaterialApp.
  runApp(
    const MaterialApp(
      // Esto quita la cinta de "Debug" de la esquina superior derecha.
      debugShowCheckedModeBanner: false,
      // Le decimos que nuestra página de inicio es el widget que ya creamos.
      home: MyApp(),
    ),
  );
}
