// lib/components/npc_component.dart

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/models/npc.dart';

/// Visual component for NPCs in the game world
class NPCComponent extends SpriteComponent
    with HasGameReference<RenegadeDungeonGame> {
  final NPC npc;

  // Interaction indicator
  late TextComponent _interactionIndicator;
  bool _showIndicator = false;

  NPCComponent({required this.npc})
      : super(
          size: Vector2(32, 48), // Same as player
          anchor: Anchor.bottomCenter,
        );

  @override
  Future<void> onLoad() async {
    // Load NPC sprite
    try {
      sprite = await game.loadSprite(npc.spriteSheet);
    } catch (e) {
      // Fallback to default sprite if not found
      sprite = await game.loadSprite('characters/player.png');
    }

    // Set position in isometric space
    position = game.gridToScreenPosition(npc.gridPosition);

    // Priority: above tiles, below player
    priority = 5;

    // Create interaction indicator (E key prompt)
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
      position: Vector2(0, -size.y - 10), // Above NPC
    );
    // Don't add initially, will add when needed

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!game.isPlayerReady) return;

    // Check distance to player
    final playerPos = game.player.gridPosition;
    final distance = (npc.gridPosition - playerPos).length;

    // Show interaction indicator if player is close (1.5 tiles)
    final shouldShow = distance <= 1.5 && game.state == GameState.exploring;

    if (shouldShow != _showIndicator) {
      _showIndicator = shouldShow;
      // Add/remove indicator instead of using opacity
      if (shouldShow) {
        if (!_interactionIndicator.isMounted) {
          add(_interactionIndicator);
        }
      } else {
        _interactionIndicator.removeFromParent();
      }
    }
  }

  /// Check if player can interact with this NPC right now
  bool canInteract() {
    if (!game.isPlayerReady) return false;
    final playerPos = game.player.gridPosition;
    final distance = (npc.gridPosition - playerPos).length;
    return distance <= 1.5 && game.state == GameState.exploring;
  }
}
