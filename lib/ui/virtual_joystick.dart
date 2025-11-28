import 'package:flutter/material.dart';
import 'dart:math';

class VirtualJoystick extends StatefulWidget {
  final Function(Offset) onDirectionChanged;
  final double size;
  final double deadZone;

  const VirtualJoystick({
    super.key,
    required this.onDirectionChanged,
    this.size = 120.0,
    this.deadZone = 0.3,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _knobPosition = Offset.zero;
  bool _isDragging = false;

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final center = Offset(widget.size / 2, widget.size / 2);
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // Calculate offset from center
    Offset offset = localPosition - center;

    // Clamp to circle boundary
    final distance = offset.distance;
    final maxDistance = widget.size / 2 - 20; // Leave space for knob

    if (distance > maxDistance) {
      offset = Offset.fromDirection(
        atan2(offset.dy, offset.dx),
        maxDistance,
      );
    }

    setState(() {
      _knobPosition = offset;
    });

    // Normalize direction (-1 to 1)
    final normalizedX = offset.dx / maxDistance;
    final normalizedY = offset.dy / maxDistance;

    // Apply deadzone
    if (distance / maxDistance > widget.deadZone) {
      widget.onDirectionChanged(Offset(normalizedX, normalizedY));
    } else {
      widget.onDirectionChanged(Offset.zero);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _knobPosition = Offset.zero;
    });
    widget.onDirectionChanged(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 2,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),

            // Movable knob
            Transform.translate(
              offset: _knobPosition,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _isDragging
                      ? Colors.white.withOpacity(0.9)
                      : Colors.white.withOpacity(0.7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.gamepad,
                  color: Colors.black.withOpacity(0.6),
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
