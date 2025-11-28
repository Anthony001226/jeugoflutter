import 'package:flutter/material.dart';
import '../game/renegade_dungeon_game.dart';
import 'virtual_joystick.dart';
import 'action_button.dart';
import 'dart:async';

class MobileControlsOverlay extends StatefulWidget {
  final RenegadeDungeonGame game;

  const MobileControlsOverlay({super.key, required this.game});

  @override
  State<MobileControlsOverlay> createState() => _MobileControlsOverlayState();
}

class _MobileControlsOverlayState extends State<MobileControlsOverlay> {
  Timer? _movementTimer;
  Offset _currentDirection = Offset.zero;

  @override
  void initState() {
    super.initState();
    _movementTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (_currentDirection != Offset.zero) {
        _handleMovement();
      }
    });
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }

  void _handleJoystickMove(Offset direction) {
    setState(() {
      _currentDirection = direction;
    });
  }

  void _handleMovement() {
    if (widget.game.state != GameState.exploring) return;
    if (_currentDirection == Offset.zero) return;

    final absX = _currentDirection.dx.abs();
    final absY = _currentDirection.dy.abs();

    int gridX = 0;
    int gridY = 0;

    if (absX > absY) {
      gridX = _currentDirection.dx > 0 ? 1 : -1;
    } else {
      gridY = _currentDirection.dy > 0 ? 1 : -1;
    }

    widget.game.handleMobileInput(gridX, gridY);
  }

  void _handleAttack() {
    if (widget.game.state == GameState.inCombat) {
      widget.game.combatManager.playerAttack();
    } else {
      widget.game.checkNPCInteraction();
    }
  }

  void _handleInteract() {
    widget.game.checkNPCInteraction();
  }

  void _handleMenu() {
    widget.game.togglePauseMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 20,
          bottom: 20,
          child: VirtualJoystick(
            onDirectionChanged: _handleJoystickMove,
            size: 130,
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionButton(
                    icon: Icons.chat_bubble_outline,
                    color: Colors.blue,
                    onPressed: _handleInteract,
                    size: 60,
                  ),
                  const SizedBox(width: 12),
                  ActionButton(
                    icon: Icons.menu,
                    color: Colors.purple,
                    onPressed: _handleMenu,
                    size: 60,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ActionButton(
                icon: Icons.flash_on,
                color: Colors.red.shade700,
                onPressed: _handleAttack,
                size: 75,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
