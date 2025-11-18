// lib/effects/screen_fade.dart

import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

class ScreenFade extends RectangleComponent {
  // Usamos un Completer para saber cuándo ha terminado el efecto
  Completer<void> _completer = Completer();

  ScreenFade() : super(priority: 1000); // Prioridad alta para que esté por encima de todo

  @override
  void onGameResize(Vector2 size) {
    this.size = size; // Siempre cubre toda la pantalla
    super.onGameResize(size);
  }

  Future<void> fadeOut({double duration = 0.5}) {
    _completer = Completer();
    paint = BasicPalette.black.withAlpha(0).paint(); // Empieza transparente
    add(
      OpacityEffect.to(
        1.0, // Termina completamente opaco
        EffectController(duration: duration),
        onComplete: () => _completer.complete(),
      ),
    );
    return _completer.future;
  }

  Future<void> fadeIn({double duration = 0.5}) {
    _completer = Completer();
    paint = BasicPalette.black.paint(); // Empieza opaco
    add(
      OpacityEffect.to(
        0.0, // Termina completamente transparente
        EffectController(duration: duration),
        onComplete: () {
          _completer.complete();
          // Lo eliminamos para no interferir con el juego
          removeFromParent();
        },
      ),
    );
    return _completer.future;
  }
}