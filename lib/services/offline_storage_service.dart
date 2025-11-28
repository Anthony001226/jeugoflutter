import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/player_save_data.dart';
import 'cloud_save_service.dart';
import 'auth_service.dart';

class OfflineStorageService {
  static const String _boxName = 'game_saves';
  final CloudSaveService _cloudService;
  final AuthService _authService;

  late Box _box;
  bool _isOnline = false;
  int? _currentSlot;

  OfflineStorageService(this._cloudService, this._authService);

  // Initialize Hive
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);

    // Start monitoring connectivity
    _monitorConnectivity();
  }

  // Save to local storage
  Future<void> saveLocally(int slotNumber, PlayerSaveData data) async {
    try {
      final key = 'slot_$slotNumber';
      await _box.put(key, data.toJson());
      _currentSlot = slotNumber;
      print('✅ Saved locally to Slot $slotNumber');

      // Try to sync if online
      if (_isOnline) {
        await _syncToCloud(slotNumber, data);
      }
    } catch (e) {
      print('❌ Error saving locally: $e');
    }
  }

  // Load from local storage
  PlayerSaveData? loadLocally(int slotNumber) {
    try {
      final key = 'slot_$slotNumber';
      final data = _box.get(key);

      if (data == null) {
        print('ℹ️ No local save in Slot $slotNumber');
        return null;
      }

      print('✅ Loaded from local storage (Slot $slotNumber)');
      return PlayerSaveData.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      print('❌ Error loading locally: $e');
      return null;
    }
  }

  // Delete local slot
  Future<void> deleteLocalSlot(int slotNumber) async {
    final key = 'slot_$slotNumber';
    await _box.delete(key);
    print('✅ Local Slot $slotNumber deleted');
  }

  // Sync local data to cloud
  Future<bool> _syncToCloud(int slotNumber, PlayerSaveData data) async {
    final userId = _authService.getUserId();
    if (userId == null) {
      print('⚠️ Cannot sync: not logged in');
      return false;
    }

    try {
      await _cloudService.savePlayerData(userId, slotNumber, data);
      print('☁️ Synced Slot $slotNumber to cloud');
      return true;
    } catch (e) {
      print('❌ Sync failed: $e');
      return false;
    }
  }

  // Sync cloud data to local (when user logs in)
  Future<PlayerSaveData?> syncFromCloud(int slotNumber) async {
    final userId = _authService.getUserId();
    if (userId == null) return null;

    try {
      final cloudData = await _cloudService.loadPlayerData(userId, slotNumber);

      if (cloudData != null) {
        // Save to local
        await saveLocally(slotNumber, cloudData);
        print('⬇️ Downloaded Slot $slotNumber from cloud');
        return cloudData;
      }

      return null;
    } catch (e) {
      print('❌ Error syncing from cloud: $e');
      return null;
    }
  }

  // Auto-sync all slots when connection is restored
  Future<void> syncAllSlots() async {
    if (!_isOnline) return;

    final userId = _authService.getUserId();
    if (userId == null) return;

    print('🔄 Auto-syncing all slots...');

    for (int i = 1; i <= 3; i++) {
      final localData = loadLocally(i);
      if (localData != null) {
        await _syncToCloud(i, localData);
      }
    }

    print('✅ All slots synced');
  }

  // Monitor internet connectivity
  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (_isOnline && wasOffline) {
        print('📶 Connection restored');
        syncAllSlots(); // Auto-sync when back online
      } else if (!_isOnline) {
        print('📴 Offline mode');
      }
    });

    // Check initial state
    Connectivity().checkConnectivity().then((ConnectivityResult result) {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  // Get sync status
  bool get isOnline => _isOnline;

  // Resolve conflict (local vs cloud)
  PlayerSaveData resolveConflict(
    PlayerSaveData localData,
    PlayerSaveData cloudData,
  ) {
    // Use most recent save
    if (cloudData.lastSaved.isAfter(localData.lastSaved)) {
      print('☁️ Using cloud data (more recent)');
      return cloudData;
    } else {
      print('💾 Using local data (more recent)');
      return localData;
    }
  }
}
