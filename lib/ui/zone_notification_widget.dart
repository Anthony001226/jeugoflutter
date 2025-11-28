import 'package:flutter/material.dart';
import '../game/renegade_dungeon_game.dart';

class ZoneNotificationWidget extends StatefulWidget {
  final RenegadeDungeonGame game;

  const ZoneNotificationWidget({Key? key, required this.game})
      : super(key: key);

  @override
  State<ZoneNotificationWidget> createState() => _ZoneNotificationWidgetState();
}

class _ZoneNotificationWidgetState extends State<ZoneNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  String _zoneName = '';
  int _dangerLevel = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // Total duration
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0), weight: 20), // Fade in
      TweenSequenceItem(
          tween: ConstantTween(1.0),
          weight: 80), // Stay visible forever (or until next change)
    ]).animate(_controller);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
    ));

    // Listen to zone changes
    widget.game.currentZoneNameNotifier.addListener(_onZoneChanged);

    // Initial state
    _zoneName = widget.game.currentZoneNameNotifier.value;
    _dangerLevel = widget.game.currentDangerLevelNotifier.value;

    // Show immediately on load
    if (_zoneName.isNotEmpty) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    widget.game.currentZoneNameNotifier.removeListener(_onZoneChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onZoneChanged() {
    final newZone = widget.game.currentZoneNameNotifier.value;
    if (newZone != _zoneName) {
      setState(() {
        _zoneName = newZone;
        _dangerLevel = widget.game.currentDangerLevelNotifier.value;
      });
      _controller.forward(from: 0.0);
    }
  }

  Color _getDangerColor(int level) {
    switch (level) {
      case 0: // Safe
        return Colors.greenAccent;
      case 1: // Low
        return Colors.yellowAccent;
      case 2: // Medium
        return Colors.orangeAccent;
      case 3: // High
        return Colors.redAccent;
      default:
        return Colors.white;
    }
  }

  String _getDangerText(int level) {
    switch (level) {
      case 0:
        return 'SAFE AREA';
      case 1:
        return 'DANGER: LOW';
      case 2:
        return 'DANGER: MEDIUM';
      case 3:
        return 'DANGER: HIGH';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.value == 0 || _controller.value == 1) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 100, // Below HUD
          left: 0,
          right: 0,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _zoneName,
                      style: const TextStyle(
                        fontFamily: 'PixelFont',
                        fontSize: 32,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getDangerColor(_dangerLevel).withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        _getDangerText(_dangerLevel),
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 14,
                          color: _getDangerColor(_dangerLevel),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
