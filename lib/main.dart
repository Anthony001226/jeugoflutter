// lib/main.dart

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:renegade_dungeon/ui/combat_ui.dart';
import 'package:renegade_dungeon/ui/loading_ui.dart';
import 'package:renegade_dungeon/ui/main_menu.dart';
import 'package:renegade_dungeon/ui/player_hud.dart';
import 'package:renegade_dungeon/ui/slot_selection_menu.dart';
import 'game/renegade_dungeon_game.dart';
import 'services/auth_service.dart';
import 'services/cloud_save_service.dart';
import 'services/offline_storage_service.dart';
import 'package:renegade_dungeon/ui/pause_menu_ui.dart';
import 'package:renegade_dungeon/ui/combat_inventory_ui.dart';
import 'package:renegade_dungeon/ui/map_transition_overlay.dart';
import 'package:renegade_dungeon/ui/barrier_dialog_ui.dart';
import 'package:renegade_dungeon/ui/dialogue_ui.dart';
import 'package:renegade_dungeon/ui/revive_dialog.dart';
import 'package:renegade_dungeon/ui/full_map_overlay.dart';
import 'package:renegade_dungeon/ui/mobile_controls_overlay.dart';
import 'package:renegade_dungeon/ui/gem_shop_screen.dart';
import 'package:renegade_dungeon/ui/intro_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// Platform detection
bool get isMobile {
  if (kIsWeb) return false;
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (e) {
    return false;
  }
}

// El StatefulWidget que creamos está perfecto. No necesita cambios.
class MyApp extends StatefulWidget {
  final OfflineStorageService offlineStorage;
  const MyApp({super.key, required this.offlineStorage});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final RenegadeDungeonGame _game;

  @override
  void initState() {
    super.initState();
    _game = RenegadeDungeonGame(offlineStorage: widget.offlineStorage);
    _game.videoPlayerControllerNotifier.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // print('--- PASO 3: Reconstruyendo UI... ---');
    print(
        '🎨 Building UI. Video Controller: ${_game.videoPlayerControllerNotifier.value != null ? "Present" : "NULL"} | Initialized: ${_game.videoPlayerControllerNotifier.value?.value.isInitialized ?? false}');
    return Stack(
      children: [
        // CAPA 0: Fondo Negro (Para rellenar letterboxing en Splash Screen)
        Container(color: Colors.black),

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
            'barrier_dialog': (context, game) => BarrierDialogUI(
                  game: game,
                  message: game.currentBarrierMessage,
                  isBlocked: game.currentBarrierIsBlocked,
                ),
            'DialogueUI': (context, game) => DialogueUI(game: game),
            'ReviveDialog': (context, game) => ReviveDialog(game: game),
            'GemShop': (context, game) => GemShopScreen(
                game: game, onClose: () => game.overlays.remove('GemShop')),
            'FullMap': (context, game) => FullMapOverlay(
                game: game, onClose: () => game.overlays.remove('FullMap')),
            if (isMobile)
              'MobileControls': (context, game) =>
                  MobileControlsOverlay(game: game),
            'IntroScreen': (context, game) => IntroScreen(game: game),
          },
        ),
      ],
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }

  // Initialize Services
  final authService = AuthService();
  final cloudService = CloudSaveService();
  final offlineStorage = OfflineStorageService(cloudService, authService);
  await offlineStorage.init();

  // --- ¡AQUÍ ESTÁ LA SOLUCIÓN! ---
  // Envolvemos nuestro widget MyApp dentro de un MaterialApp.
  runApp(
    MaterialApp(
      // Esto quita la cinta de "Debug" de la esquina superior derecha.
      debugShowCheckedModeBanner: false,
      // Le decimos que nuestra página de inicio es el widget que ya creamos.
      home: MyApp(offlineStorage: offlineStorage),
    ),
  );
}
