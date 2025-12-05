import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/models/npc.dart';

class DialogueUI extends StatelessWidget {
  final RenegadeDungeonGame game;

  const DialogueUI({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final npcId = game.activeDialogueNPC;
    if (npcId == null) {
      return const SizedBox.shrink();
    }

    final npc = game.npcs[npcId];
    if (npc == null) {
      return const SizedBox.shrink();
    }

    return KeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          game.endDialogue();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.5),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getNPCTypeColor(npc.type),
                width: 3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getNPCTypeIcon(npc.type),
                      color: _getNPCTypeColor(npc.type),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      npc.name,
                      style: TextStyle(
                        color: _getNPCTypeColor(npc.type),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _getNPCTypeLabel(npc.type),
                      style: TextStyle(
                        color: _getNPCTypeColor(npc.type).withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  npc.dialogue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => game.endDialogue(),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Cerrar (ESC)',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNPCTypeColor(NPCType type) {
    switch (type) {
      case NPCType.vendor:
        return Colors.amber;
      case NPCType.questGiver:
        return Colors.green;
      case NPCType.lore:
        return Colors.blue;
      case NPCType.generic:
        return Colors.grey;
    }
  }

  IconData _getNPCTypeIcon(NPCType type) {
    switch (type) {
      case NPCType.vendor:
        return Icons.shopping_bag;
      case NPCType.questGiver:
        return Icons.assignment;
      case NPCType.lore:
        return Icons.menu_book;
      case NPCType.generic:
        return Icons.person;
    }
  }

  String _getNPCTypeLabel(NPCType type) {
    switch (type) {
      case NPCType.vendor:
        return 'VENDEDOR';
      case NPCType.questGiver:
        return 'MISIÓN';
      case NPCType.lore:
        return 'INFORMACIÓN';
      case NPCType.generic:
        return 'NPC';
    }
  }
}
