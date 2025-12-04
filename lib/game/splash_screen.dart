import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'dart:math' as math;

class SplashScreen extends Component
    with HasGameReference<RenegadeDungeonGame>, TapCallbacks, KeyboardHandler {
  SpriteComponent? _background;
  SpriteComponent? _logo;
  late TextComponent _prompt;

  @override
  Future<void> onLoad() async {
    // 1. Fondo
    try {
      _background = SpriteComponent(
        sprite: await game.loadSprite('backgrounds/splash_screen.png'),
        anchor: Anchor.center,
      );
      add(_background!);
    } catch (e) {
    }

    // 2. Logo
    try {
      _logo = SpriteComponent(
        sprite: await game.loadSprite('ui/logo.png'),
        anchor: Anchor.bottomRight,
        size: Vector2(125, 125),
      );
      add(_logo!);
    } catch (e) {
    }

    // 3. Texto que vamos a animar
    _prompt = TextComponent(
      text: 'Presiona cualquier tecla para continuar',
      anchor: Anchor.center,
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
    add(_prompt);

    // 4. Efecto de pulso suave (Manual)
    double time = 0;
    add(
      TimerComponent(
        period: 0.016, // ~60fps
        repeat: true,
        onTick: () {
          time += 0.05;
          final alpha = (155 + 100 * math.sin(time)).toInt().clamp(0, 255);

          final currentStyle = (_prompt.textRenderer as TextPaint).style;
          _prompt.textRenderer = TextPaint(
            style: currentStyle.copyWith(
              color: currentStyle.color!.withAlpha(alpha),
            ),
          );
        },
      ),
    );

    // 5. Preload menu video to avoid Autoplay errors
    game.preloadBackgroundVideo('menu_background.mp4');

    // 6. Auto-advance after 3 seconds (fallback for mobile)
    add(
      TimerComponent(
        period: 3.0,
        repeat: false,
        onTick: () {
          _startGame();
        },
      ),
    );

    // Initial resize
    _resizeComponents(game.size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Check if components are initialized before resizing
    if (isLoaded) {
      _resizeComponents(size);
    }
  }

  void _resizeComponents(Vector2 size) {
    // Background: BoxFit.cover logic
    if (_background?.sprite != null) {
      final spriteSize = _background!.sprite!.originalSize;
      final scaleX = size.x / spriteSize.x;
      final scaleY = size.y / spriteSize.y;
      final scale = math.max(scaleX, scaleY);

      _background!.scale = Vector2.all(scale);
      _background!.position = size / 2;
    }

    // Logo: Bottom Right with margin
    const double margin = 20.0;
    if (_logo != null) {
      _logo!.position = Vector2(size.x - margin, size.y - margin);
    }

    // Prompt: Bottom Center
    _prompt.position = Vector2(size.x / 2, size.y * 0.85);
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
