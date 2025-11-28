import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'dart:math' as math;

class SplashScreen extends Component
    with HasGameReference<RenegadeDungeonGame>, TapCallbacks, KeyboardHandler {
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
      anchor: Anchor.bottomRight,
      position: Vector2(game.size.x - margin, game.size.y - margin),
      size: Vector2(125, 125),
    );
    add(logo);

    // 3. Texto que vamos a animar
    final prompt = TextComponent(
      text: 'Presiona cualquier tecla para continuar',
      anchor: Anchor.center,
      position: Vector2(game.size.x / 2, game.size.y * 0.85),
      textRenderer: TextPaint(
        style: GoogleFonts.cinzel(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          shadows: [
            const Shadow(
                blurRadius: 15, color: Colors.black, offset: Offset(0, 2))
          ],
        ),
      ),
    );
    add(prompt);

    // 4. Efecto de pulso suave (Manual)
    double time = 0;
    add(
      TimerComponent(
        period: 0.016, // ~60fps
        repeat: true,
        onTick: () {
          time += 0.05;
          final alpha = (155 + 100 * math.sin(time)).toInt().clamp(0, 255);

          final currentStyle = (prompt.textRenderer as TextPaint).style;
          prompt.textRenderer = TextPaint(
            style: currentStyle.copyWith(
              color: currentStyle.color!.withAlpha(alpha),
            ),
          );
        },
      ),
    );
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _startGame();
    return true;
  }

  @override
  void onTapDown(TapDownEvent event) {
    _startGame();
  }

  void _startGame() {
    // Play menu music
    game.playMenuMusic();
    game.router.pushReplacementNamed('main-menu');
  }
}
