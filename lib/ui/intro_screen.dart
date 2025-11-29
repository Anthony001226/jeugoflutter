import 'package:flutter/material.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class IntroScreen extends StatefulWidget {
  final RenegadeDungeonGame game;
  const IntroScreen({super.key, required this.game});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  int _currentIndex = 0;
  final List<String> _lines = [
    "En el momento en que el reino cae en manos de una extraña enfermedad...",
    "La tierra que unas vez se consideraba invencible, ahora se encuentra en manos de una extraña enfermedad...",
    "Solo unos pocos sobrevivieron...",
    "Pero esa misma enfermedad, también levantó a un Caballero.",
    "Un Caballero Renegado, que se levantó de su tumba para proteger el reino que juraba salvar aun cuando lo traicionaron.",
    "",
  ];

  @override
  void initState() {
    super.initState();
    _checkAndSkip();
  }

  @override
  void didUpdateWidget(IntroScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Also check when widget updates
    _checkAndSkip();
  }

  void _checkAndSkip() {
    // Debug logging
    print(
        '🎬 IntroScreen._checkAndSkip() - isNewGameFlag: ${widget.game.isNewGameFlag}, counter: ${widget.game.introNavigationCount}');

    // If loading an existing save (not a new game), skip intro
    if (!widget.game.isNewGameFlag) {
      print('🎬 Loaded save detected, auto-skipping intro');
      // Use Future to avoid calling setState during build
      Future.microtask(() => _finishIntro());
    } else {
      print('🎬 New game, showing intro');
    }
  }

  void _nextLine() {
    if (_currentIndex < _lines.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishIntro();
    }
  }

  void _finishIntro() {
    // Navigate to game, spawning at Cemetery
    widget.game.router.pushReplacementNamed('game-screen');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _nextLine,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(seconds: 1),
                child: Text(
                  _lines[_currentIndex],
                  key: ValueKey<int>(_currentIndex),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'PixelifySans', // Assuming we have a pixel font
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              right: 30,
              child: TextButton(
                onPressed: _finishIntro,
                child: const Text(
                  'SALTAR >>',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
            const Positioned(
              bottom: 30,
              left: 30,
              child: Text(
                'Toca para continuar...',
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
