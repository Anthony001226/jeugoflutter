// lib/ui/slot_selection_menu.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/models/player_save_data.dart';
import 'dart:ui'; // For ImageFilter

class SlotSelectionMenu extends StatefulWidget {
  final RenegadeDungeonGame game;

  const SlotSelectionMenu({super.key, required this.game});

  @override
  State<SlotSelectionMenu> createState() => _SlotSelectionMenuState();
}

class _SlotSelectionMenuState extends State<SlotSelectionMenu> {
  late Future<List<PlayerSaveData?>> _slotsFuture;

  @override
  void initState() {
    super.initState();
    _refreshSlots();
  }

  void _refreshSlots() {
    setState(() {
      _slotsFuture = Future.wait([
        _loadSlot(1),
        _loadSlot(2),
        _loadSlot(3),
      ]);
    });
  }

  Future<PlayerSaveData?> _loadSlot(int slot) async {
    // Try to sync from cloud first if online, then load local
    if (widget.game.offlineStorage.isOnline) {
      await widget.game.offlineStorage.syncFromCloud(slot);
    }
    return widget.game.offlineStorage.loadLocally(slot);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                FutureBuilder<List<PlayerSaveData?>>(
                  future: _slotsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading saves',
                          style: GoogleFonts.cinzel(color: Colors.red),
                        ),
                      );
                    }

                    final slots = snapshot.data ?? [null, null, null];

                    return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 3,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final slotIndex = index + 1;
                          final data = slots[index];
                          return SlotCard(
                            slotNumber: slotIndex,
                            saveData: data,
                            onTap: () => _onSlotSelected(slotIndex, data),
                            onDelete: data != null
                                ? () => _onDeleteSlot(slotIndex)
                                : null,
                          );
                        });
                  },
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () {
                    print('🔙 Back button pressed');
                    // Swap to Main Menu
                    widget.game.router.pushReplacementNamed('main-menu');

                    // Manual visual update (since MainMenu route is not rebuilt)
                    widget.game.overlays.clear();
                    widget.game.overlays.add('MainMenu');
                    widget.game.playBackgroundVideo('menu_background.mp4');
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  label: Text(
                    'BACK',
                    style: GoogleFonts.cinzel(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSlotSelected(int slotIndex, PlayerSaveData? data) {
    widget.game.currentSlotIndex = slotIndex;
    widget.game.router.pushNamed('loading-screen');
  }

  Future<void> _onDeleteSlot(int slotIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Delete Save?',
            style: GoogleFonts.cinzel(color: Colors.white)),
        content: Text(
          'This action cannot be undone.',
          style: GoogleFonts.cinzel(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.cinzel(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.cinzel(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.game.offlineStorage.deleteLocalSlot(slotIndex);
      // Also try to delete from cloud if needed, but for now local delete is key
      _refreshSlots();
    }
  }
}

class SlotCard extends StatefulWidget {
  final int slotNumber;
  final PlayerSaveData? saveData;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const SlotCard({
    super.key,
    required this.slotNumber,
    this.saveData,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<SlotCard> {
  bool _isHovered = false;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.saveData == null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 200),
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isHovered
                  ? [
                      Colors.black.withOpacity(0.8),
                      const Color(0xFF2A2A2A).withOpacity(0.9),
                    ]
                  : [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.8),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
              left: BorderSide(
                color: _isHovered
                    ? const Color(0xFFD4AF37)
                    : Colors.transparent, // Gold accent
                width: 4,
              ),
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color:
                          const Color(0xFFD4AF37).withOpacity(0.2), // Gold glow
                      blurRadius: 20,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Slot Number
              Container(
                width: 80,
                alignment: Alignment.center,
                child: Text(
                  '${widget.slotNumber}',
                  style: GoogleFonts.cinzel(
                    fontSize: 48,
                    color: Colors.white.withOpacity(0.2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Content
              Expanded(
                child: isEmpty
                    ? Center(
                        child: Text(
                          'CREATE NEW DATA',
                          style: GoogleFonts.cinzel(
                            fontSize: 18,
                            color: Colors.white60,
                            letterSpacing: 1.5,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            // Character Icon / Class Icon (Placeholder)
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person,
                                  color: Colors.white54, size: 30),
                            ),
                            const SizedBox(width: 20),

                            // Stats
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Level ${widget.saveData!.level}',
                                    style: GoogleFonts.cinzel(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    widget.saveData!.currentMap
                                        .replaceAll('.tmx', '')
                                        .toUpperCase(),
                                    style: GoogleFonts.cinzel(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Playtime
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'PLAYTIME',
                                  style: GoogleFonts.cinzel(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  _formatDuration(Duration(
                                      seconds:
                                          widget.saveData!.playtimeSeconds)),
                                  style: GoogleFonts.robotoMono(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),

              // Delete Button (only if not empty and hovered)
              if (!isEmpty && _isHovered && widget.onDelete != null)
                IconButton(
                  onPressed: widget.onDelete,
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Delete Save',
                ),

              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }
}
