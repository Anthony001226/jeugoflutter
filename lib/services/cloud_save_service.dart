import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_save_data.dart';
import '../models/save_slot_metadata.dart';

class CloudSaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> savePlayerData(
    String userId,
    int slotNumber,
    PlayerSaveData data,
  ) async {
    try {
      final slotId = 'slot_$slotNumber';
      final path = 'users/$userId/saves/$slotId';

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saves')
          .doc(slotId)
          .set(data.toJson(), SetOptions(merge: true));

      await _updateSlotMetadata(userId, slotNumber, data);

    } catch (e) {
      rethrow;
    }
  }

  Future<PlayerSaveData?> loadPlayerData(String userId, int slotNumber) async {
    try {
      final slotId = 'slot_$slotNumber';
      final path = 'users/$userId/saves/$slotId';

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saves')
          .doc(slotId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return PlayerSaveData.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteSlot(String userId, int slotNumber) async {
    try {
      final slotId = 'slot_$slotNumber';

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saves')
          .doc(slotId)
          .delete();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('slot_metadata')
          .doc(slotId)
          .delete();

    } catch (e) {
      rethrow;
    }
  }

  Future<List<SaveSlotMetadata?>> getAllSlotsMetadata(String userId) async {
    try {
      List<SaveSlotMetadata?> slots = [null, null, null];

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
      return [null, null, null];
    }
  }

  Future<void> _updateSlotMetadata(
    String userId,
    int slotNumber,
    PlayerSaveData data,
  ) async {
    final slotId = 'slot_$slotNumber';
    final metadata = SaveSlotMetadata(
      slotNumber: slotNumber,
      characterName: "Héroe",
      level: data.level,
      currentMap: data.currentMap,
      playTimeSeconds: 0,
      lastSaved: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('slot_metadata')
        .doc(slotId)
        .set(metadata.toJson());
  }

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
