
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

/// RPG-style barrier notification at bottom - auto-closes after 3 seconds
class BarrierDialogUI extends StatefulWidget {
  final RenegadeDungeonGame game;
  final String message;
  final bool isBlocked;

  const BarrierDialogUI({
    super.key,
    required this.game,
    required this.message,
    required this.isBlocked,
  });

  @override
  State<BarrierDialogUI> createState() => _BarrierDialogUIState();
}

class _BarrierDialogUIState extends State<BarrierDialogUI> {
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _autoCloseTimer = Timer(const Duration(seconds: 3), _closeDialog);
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _closeDialog() {
    _autoCloseTimer?.cancel();
    widget.game.overlays.remove('barrier_dialog');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeDialog,
      behavior: HitTestBehavior.translucent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isBlocked
                  ? [
                      const Color(0xFF2A2A2A),
                      const Color(0xFF1A1A1A),
                    ]
                  : [
                      const Color(0xFF2A3A2A),
                      const Color(0xFF1A251A),
                    ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isBlocked
                  ? const Color(0xFF6A6A6A)
                  : const Color(0xFF5A7A5A),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isBlocked ? Icons.lock : Icons.lock_open,
                color: widget.isBlocked
                    ? const Color(0xFFAAAAAA)
                    : const Color(0xFF88AA88),
                size: 28,
              ),

              const SizedBox(width: 12),

              Flexible(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFEEEEEE),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    decoration: TextDecoration.none,
                    fontFamily: 'Arial',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 12),

              const Icon(
                Icons.timer,
                color: Color(0xFF888888),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
