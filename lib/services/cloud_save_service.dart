import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_save_data.dart';
import '../models/save_slot_metadata.dart';

class CloudSaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save player data to specific slot
  Future<void> savePlayerData(
    String userId,
    int slotNumber, // 1, 2, or 3
    PlayerSaveData data,
  ) async {
    try {
      final slotId = 'slot_$slotNumber';
      final path = 'users/$userId/saves/$slotId';
      print('☁️ Attempting to SAVE to: $path');

      // Save game data
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saves')
          .doc(slotId)
          .set(data.toJson(), SetOptions(merge: true));

      // Update slot metadata
      await _updateSlotMetadata(userId, slotNumber, data);

      print('✅ Game saved to cloud (Slot $slotNumber)');
    } catch (e) {
      print('❌ Error saving to cloud: $e');
      rethrow;
    }
  }

  // Load player data from specific slot
  Future<PlayerSaveData?> loadPlayerData(String userId, int slotNumber) async {
    try {
      final slotId = 'slot_$slotNumber';
      final path = 'users/$userId/saves/$slotId';
      print('☁️ Attempting to load from: $path');

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saves')
          .doc(slotId)
          .get();

      if (!doc.exists) {
        print('ℹ️ No save found in Cloud Slot $slotNumber (Path: $path)');
        return null;
      }

      print(
          '✅ Game loaded from cloud (Slot $slotNumber). Data size: ${doc.data()?.length ?? 0}');
      return PlayerSaveData.fromJson(doc.data()!);
    } catch (e) {
      print('❌ Error loading from cloud: $e');
      return null;
    }
  }

  // Delete specific slot
  Future<void> deleteSlot(String userId, int slotNumber) async {
    try {
      final slotId = 'slot_$slotNumber';

      // Delete game data
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saves')
          .doc(slotId)
          .delete();

      // Delete metadata
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('slot_metadata')
          .doc(slotId)
          .delete();

      print('✅ Slot $slotNumber deleted');
    } catch (e) {
      print('❌ Error deleting slot: $e');
      rethrow;
    }
  }

  // Get all slots metadata for user
  Future<List<SaveSlotMetadata?>> getAllSlotsMetadata(String userId) async {
    try {
      List<SaveSlotMetadata?> slots = [null, null, null]; // 3 slots

      for (int i = 1; i <= 3; i++) {
        final slotId = 'slot_$i';
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('slot_metadata')
            .doc(slotId)
            .get();

        if (doc.exists) {
          slots[i - 1] = SaveSlotMetadata.fromJson(doc.data()!);
        }
      }

      return slots;
    } catch (e) {
      print('❌ Error loading slots metadata: $e');
      return [null, null, null];
    }
  }

  // Update slot metadata
  Future<void> _updateSlotMetadata(
    String userId,
    int slotNumber,
    PlayerSaveData data,
  ) async {
    final slotId = 'slot_$slotNumber';
    final metadata = SaveSlotMetadata(
      slotNumber: slotNumber,
      characterName: "Héroe", // TODO: Get from player name if added
      level: data.level,
      currentMap: data.currentMap,
      playTimeSeconds: 0, // TODO: Track play time
      lastSaved: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('slot_metadata')
        .doc(slotId)
        .set(metadata.toJson());
  }

  // Check if slot is empty
  Future<bool> isSlotEmpty(String userId, int slotNumber) async {
    final slotId = 'slot_$slotNumber';
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('saves')
        .doc(slotId)
        .get();

    return !doc.exists;
  }
}
