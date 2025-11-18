// lib/components/emote_component.dart

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

class EmoteComponent extends SpriteComponent with HasGameReference {
  EmoteComponent() : super(size: Vector2.all(32));

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('emotes/surprise.png');
    
    anchor = Anchor.bottomCenter;

    add(
      SequenceEffect([
        // Aparece subiendo y haciéndose visible (esto no cambia)
        MoveByEffect(Vector2(0, -10), EffectController(duration: 0.2, curve: Curves.easeOut)),
        OpacityEffect.fadeIn(EffectController(duration: 0.2)),

        // --- ¡LA SOLUCIÓN ALTERNATIVA ESTÁ AQUÍ! ---
        // En lugar de DelayEffect, usamos un efecto que no hace nada por 0.8 segundos.
        // Mueve el componente 0 píxeles en 0.8 segundos, creando una pausa.
        MoveByEffect(Vector2.zero(), EffectController(duration: 0.8)),

        // Se desvanece (esto no cambia)
        OpacityEffect.fadeOut(EffectController(duration: 0.3)),
      ], onComplete: () {
        // Se elimina a sí mismo (esto no cambia)
        removeFromParent();
      }),
    );
  }
}