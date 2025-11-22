// lib/ui/map_transition_overlay.dart

import 'package:flutter/material.dart';

/// Overlay que muestra pantalla negra durante transición de mapas
class MapTransitionOverlay extends StatelessWidget {
  const MapTransitionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }
}
