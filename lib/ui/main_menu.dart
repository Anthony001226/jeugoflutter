// lib/ui/main_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'dart:ui'; // For ImageFilter

class MainMenu extends StatefulWidget {
  final RenegadeDungeonGame game;
  const MainMenu({super.key, required this.game});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Allow video background to show
      body: Stack(
        children: [
          // Gradient Overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Spacer to push menu below the video's title
                      const SizedBox(height: 300),

                      // Horizontal Menu
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FantasyButton(
                              label: 'Jugar',
                              onPressed: () {
                                // Direct to Slot 1
                                widget.game.currentSlotIndex = 1;
                                widget.game.router
                                    .pushReplacementNamed('loading-screen');
                              },
                            ),
                            const SizedBox(width: 40),
                            FantasyButton(
                              label: 'Borrar',
                              isDestructive: true,
                              onPressed: () {
                                _showDeleteConfirmation(context);
                              },
                            ),
                            const SizedBox(width: 40),
                            FantasyButton(
                              label: 'Ajustes',
                              onPressed: () {
                              },
                            ),
                            const SizedBox(width: 40),
                            // Login Section integrated in row
                            _buildLoginSection(),
                            const SizedBox(width: 40),
                            FantasyButton(
                              label: 'Salir',
                              isDestructive: true,
                              onPressed: () {
                                _showExitDialog(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isLoggingIn = false;

  Widget _buildLoginSection() {
    if (_isLoggingIn) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return StreamBuilder(
      stream: widget.game.authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return FantasyButton(
            label: 'Login',
            onPressed: () async {
              setState(() {
                _isLoggingIn = true;
              });
              try {
                final credential =
                    await widget.game.authService.signInWithGoogle();
                if (credential == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('⚠️ Login cancelado o fallido')),
                    );
                  }
                } else {
                  // Download save from cloud (Slot 1)
                  await widget.game.offlineStorage.syncFromCloud(1);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('☁️ Sincronización completada')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Error: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoggingIn = false;
                  });
                }
              }
            },
          );
        } else {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '👤 ${user.email?.split('@')[0] ?? "User"}',
                style: GoogleFonts.cinzel(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(width: 20),
              FantasyButton(
                label: 'Logout',
                isDestructive: true,
                onPressed: () async {
                  await widget.game.authService.signOut();
                },
              ),
            ],
          );
        }
      },
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text('⚠️ Borrar Partida',
            style: TextStyle(color: Colors.red)),
        content: const Text(
          '¿Estás seguro? Esto borrará tu progreso local y en la nube permanentemente.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              await widget.game.offlineStorage.deleteSlot(1);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🗑️ Partida borrada')),
              );
            },
            child: const Text('Borrar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Color(0xFF4A4A4A))),
        title: Text(
          'Salir del Juego',
          style: GoogleFonts.cinzel(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que quieres abandonar las profundidades?',
          style: GoogleFonts.cinzel(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar',
                style: GoogleFonts.cinzel(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
            ),
            child: Text('Salir', style: GoogleFonts.cinzel()),
          ),
        ],
      ),
    );
  }
}

class FantasyButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isDestructive;
  final bool isPrimary;

  const FantasyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDestructive = false,
    this.isPrimary = false,
  });

  @override
  State<FantasyButton> createState() => _FantasyButtonState();
}

class _FantasyButtonState extends State<FantasyButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Text style based on hover state
    final TextStyle textStyle = GoogleFonts.cinzel(
      color: _isHovered ? Colors.white : Colors.white60,
      fontSize: 20, // Slightly larger for text-only menu
      fontWeight: _isHovered ? FontWeight.bold : FontWeight.normal,
      letterSpacing: 2.0,
      shadows: _isHovered
          ? [
              Shadow(
                blurRadius: 15.0,
                color:
                    widget.isDestructive ? Colors.redAccent : Colors.cyanAccent,
                offset: const Offset(0, 0),
              ),
            ]
          : [],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          // Removed background decoration for text-only look
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
            color: _isHovered
                ? (widget.isDestructive ? Colors.redAccent : Colors.cyanAccent)
                : Colors.transparent,
            width: 2,
          ))),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon,
                    color: _isHovered ? Colors.white : Colors.white60,
                    size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                widget.label.toUpperCase(),
                style: textStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
