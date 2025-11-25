// lib/ui/barrier_dialog_ui.dart

import 'package:flutter/material.dart';

/// Simple dialog overlay for barrier messages
class BarrierDialogUI extends StatelessWidget {
  final String message;
  final bool isBlocked; // true = blocked (red), false = unlocked (green)

  const BarrierDialogUI({
    super.key,
    required this.message,
    required this.isBlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isBlocked
                  ? [
                      const Color(0xFF2D1B1B), // Dark red
                      const Color(0xFF1A0F0F),
                    ]
                  : [
                      const Color(0xFF1B2D1B), // Dark green
                      const Color(0xFF0F1A0F),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isBlocked
                  ? Colors.red.withOpacity(0.5)
                  : Colors.green.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isBlocked
                    ? Colors.red.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                isBlocked ? Icons.lock : Icons.lock_open,
                size: 48,
                color: isBlocked ? Colors.red[300] : Colors.green[300],
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                isBlocked ? '🚫 Acceso Denegado' : '✅ Acceso Permitido',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isBlocked ? Colors.red[200] : Colors.green[200],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Close instruction
              Text(
                'Presiona cualquier tecla para continuar',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
