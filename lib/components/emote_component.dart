
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
        MoveByEffect(Vector2(0, -10), EffectController(duration: 0.2, curve: Curves.easeOut)),
        OpacityEffect.fadeIn(EffectController(duration: 0.2)),

        MoveByEffect(Vector2.zero(), EffectController(duration: 0.8)),

        OpacityEffect.fadeOut(EffectController(duration: 0.3)),
      ], onComplete: () {
        removeFromParent();
      }),
    );
  }
}