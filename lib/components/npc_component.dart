import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/models/npc.dart';

class NPCComponent extends SpriteComponent
    with HasGameReference<RenegadeDungeonGame> {
  final NPC npc;

  late TextComponent _interactionIndicator;
  bool _showIndicator = false;

  NPCComponent({required this.npc})
      : super(
          size: Vector2(32, 48),
          anchor: Anchor.bottomCenter,
        );

  @override
  Future<void> onLoad() async {
    try {
      sprite = await game.loadSprite(npc.spriteSheet);
    } catch (e) {
      sprite = await game.loadSprite('characters/player.png');
    }

    position = game.gridToScreenPosition(npc.gridPosition);

    priority = 5;

    _interactionIndicator = TextComponent(
      text: 'E',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(0, -size.y - 10),
    );

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!game.isPlayerReady) return;

    final playerPos = game.player.gridPosition;
    final distance = (npc.gridPosition - playerPos).length;

    final shouldShow = distance <= 1.5 && game.state == GameState.exploring;

    if (shouldShow != _showIndicator) {
      _showIndicator = shouldShow;
      if (shouldShow) {
        if (!_interactionIndicator.isMounted) {
          add(_interactionIndicator);
        }
      } else {
        _interactionIndicator.removeFromParent();
      }
    }
  }

  bool canInteract() {
    if (!game.isPlayerReady) return false;
    final playerPos = game.player.gridPosition;
    final distance = (npc.gridPosition - playerPos).length;
    return distance <= 1.5 && game.state == GameState.exploring;
  }
}
