// lib/game/splash_screen.dart

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class SplashScreen extends Component
    with HasGameReference<RenegadeDungeonGame>, TapCallbacks, KeyboardHandler {
  
  // --- ¡LA SOLUCIÓN! ---
  // Una variable para llevar la cuenta del estado del parpadeo.
  bool _textIsVisible = true;

  @override
  Future<void> onLoad() async {
    // 1. Fondo
    add(
      SpriteComponent(
        sprite: await game.loadSprite('backgrounds/splash_screen.png'),
        size: game.size,
      )..size = game.size,
    );

    // 2. Logo
    const double margin = 20.0;
    final logo = SpriteComponent(
      sprite: await game.loadSprite('ui/logo.png'),
      anchor: Anchor.bottomRight, // Ancla en la esquina inferior derecha
      position: Vector2(game.size.x - margin, game.size.y - margin), // Posición en la esquina inferior derecha
      size: Vector2(125, 125),
    );
    add(logo);

    // 3. Texto que vamos a animar
    final prompt = TextComponent(
      text: 'Presiona cualquier tecla para continuar',
      anchor: Anchor.center,
      position: Vector2(game.size.x / 2, game.size.y * 0.8),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          shadows: [Shadow(blurRadius: 10, color: Colors.black)],
        ),
      ),
    );
    add(prompt);

    // 4. Temporizador con la lógica de estado final
    add(
      TimerComponent(
        period: 1.5,
        repeat: true,
        onTick: () {
          // Invertimos el estado en cada tick (de true a false, de false a true)
          _textIsVisible = !_textIsVisible; 

          final currentStyle = (prompt.textRenderer as TextPaint).style;

          // Creamos un estilo nuevo basado en nuestro booleano, no leyendo el color.
          final newStyle = currentStyle.copyWith(
            color: _textIsVisible
                ? Colors.white.withAlpha(255) // Si es visible, ponlo opaco
                : Colors.white.withAlpha(51),  // Si no, ponlo transparente
          );
          
          prompt.textRenderer = TextPaint(style: newStyle);
        },
      ),
    );
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    game.playMenuMusic();
    game.router.pushReplacementNamed('main-menu');
    return true;
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.playMenuMusic();
    game.router.pushReplacementNamed('main-menu');
  }
}