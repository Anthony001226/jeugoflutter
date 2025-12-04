import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/player_save_data.dart';
import 'cloud_save_service.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

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
    if (kIsWeb) {
      // Web uses IndexedDB, no path needed
      await Hive.initFlutter();
    } else {
      // Explicitly set path for Windows/Mobile persistence
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);
    }

    _box = await Hive.openBox(_boxName);

    // Start monitoring connectivity
    _monitorConnectivity();
  }

  // Save to local storage
  Future<void> saveLocally(int slotNumber, PlayerSaveData data) async {
    try {
      final key = 'slot_$slotNumber';
      await _box.put(key, data.toJson());
      await _box.flush(); // Force write to disk

      // Verify save was successful
      final verification = _box.get(key);
      if (verification == null) {
      } else {
      }

      _currentSlot = slotNumber;

      // Try to sync if online (Fire and forget to avoid blocking UI/Autoplay)
      if (_isOnline) {
        _syncToCloud(slotNumber, data);
      }
    } catch (e) {
    }
  }

  // Load from local storage
  PlayerSaveData? loadLocally(int slotNumber) {
    try {
      final key = 'slot_$slotNumber';

      // Debug: Check if key exists
      if (!_box.containsKey(key)) {
        return null;
      }

      final data = _box.get(key);

      if (data == null) {
        return null;
      }

      // print('   Raw Data: $data'); // Uncomment if needed, but might be huge

      try {
        final parsedData =
            PlayerSaveData.fromJson(Map<String, dynamic>.from(data));
        return parsedData;
      } catch (parseError) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Delete slot (Local + Cloud)
  Future<void> deleteSlot(int slotNumber) async {
    // 1. Delete Local
    final key = 'slot_$slotNumber';
    await _box.delete(key);

    // 2. Delete Cloud (if logged in)
    final userId = _authService.getUserId();
    if (userId != null && _isOnline) {
      try {
        await _cloudService.deleteSlot(userId, slotNumber);
      } catch (e) {
      }
    }
  }

  // Sync local data to cloud
  Future<bool> _syncToCloud(int slotNumber, PlayerSaveData data) async {
    final userId = _authService.getUserId();
    if (userId == null) {
      return false;
    }

    try {
      await _cloudService.savePlayerData(userId, slotNumber, data);
      return true;
    } catch (e) {
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
        // Check local data first
        final localData = loadLocally(slotNumber);

        if (localData != null) {
          // Resolve conflict
          if (cloudData.lastSaved.isAfter(localData.lastSaved)) {
            await saveLocally(slotNumber, cloudData);
            return cloudData;
          } else {
            // Upload local to cloud to ensure consistency
            await _syncToCloud(slotNumber, localData);
            return localData;
          }
        } else {
          // No local data, safe to download
          await saveLocally(slotNumber, cloudData);
          return cloudData;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Auto-sync all slots when connection is restored
  Future<void> syncAllSlots() async {
    if (!_isOnline) return;

    final userId = _authService.getUserId();
    if (userId == null) return;


    for (int i = 1; i <= 3; i++) {
      final localData = loadLocally(i);
      if (localData != null) {
        await _syncToCloud(i, localData);
      }
    }

  }

  // Monitor internet connectivity
  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (_isOnline && wasOffline) {
        syncAllSlots(); // Auto-sync when back online
      } else if (!_isOnline) {
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
      return cloudData;
    } else {
      return localData;
    }
  }
}
