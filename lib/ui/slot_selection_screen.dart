import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/cloud_save_service.dart';
import '../models/save_slot_metadata.dart';

class SlotSelectionScreen extends StatefulWidget {
  const SlotSelectionScreen({super.key});

  @override
  State<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends State<SlotSelectionScreen> {
  final AuthService _authService = AuthService();
  final CloudSaveService _cloudService = CloudSaveService();

  List<SaveSlotMetadata?> _slots = [null, null, null];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    final userId = _authService.getUserId();
    if (userId == null) return;

    try {
      final slots = await _cloudService.getAllSlotsMetadata(userId);
      setState(() {
        _slots = slots;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading slots: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectSlot(int slotNumber) async {
    // Navigate to game with selected slot
    // TODO: Pass slot number to game
    Navigator.of(context).pushReplacementNamed(
      '/game',
      arguments: {'slot': slotNumber},
    );
  }

  Future<void> _deleteSlot(int slotNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Partida'),
        content: const Text(
          '¿Estás seguro? Esta acción no se puede deshacer',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final userId = _authService.getUserId();
      if (userId == null) return;

      try {
        await _cloudService.deleteSlot(userId, slotNumber);
        _loadSlots(); // Reload slots
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Partida eliminada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona una Partida'),
        backgroundColor: Colors.deepPurple.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade900,
              Colors.black,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 20),
                  _buildSlotCard(1, _slots[0]),
                  const SizedBox(height: 16),
                  _buildSlotCard(2, _slots[1]),
                  const SizedBox(height: 16),
                  _buildSlotCard(3, _slots[2]),
                ],
              ),
      ),
    );
  }

  Widget _buildSlotCard(int slotNumber, SaveSlotMetadata? metadata) {
    final isEmpty = metadata == null;

    return Card(
      color: Colors.grey.shade900,
      elevation: 4,
      child: InkWell(
        onTap: () => _selectSlot(slotNumber),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Slot Number
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isEmpty ? Colors.grey.shade800 : Colors.deepPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$slotNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Slot Info
              Expanded(
                child: isEmpty
                    ? const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nueva Partida',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Click para empezar',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metadata.characterName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nivel ${metadata.level}',
                            style: TextStyle(
                              color: Colors.amber.shade400,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Última vez: ${metadata.formattedLastSaved}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),

              // Delete Button (only if slot has data)
              if (!isEmpty)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSlot(slotNumber),
                  tooltip: 'Eliminar partida',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
