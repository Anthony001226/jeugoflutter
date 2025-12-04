
import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

class ScreenFade extends RectangleComponent {
  Completer<void> _completer = Completer();

  ScreenFade() : super(priority: 1000);

  @override
  void onGameResize(Vector2 size) {
    this.size = size;
    super.onGameResize(size);
  }

  Future<void> fadeOut({double duration = 0.5}) {
    _completer = Completer();
    paint = BasicPalette.black.withAlpha(0).paint();
    add(
      OpacityEffect.to(
        1.0,
        EffectController(duration: duration),
        onComplete: () => _completer.complete(),
      ),
    );
    return _completer.future;
  }

  Future<void> fadeIn({double duration = 0.5}) {
    _completer = Completer();
    paint = BasicPalette.black.paint();
    add(
      OpacityEffect.to(
        0.0,
        EffectController(duration: duration),
        onComplete: () {
          _completer.complete();
          removeFromParent();
        },
      ),
    );
    return _completer.future;
  }
}