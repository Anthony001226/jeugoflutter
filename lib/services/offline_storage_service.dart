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

  Future<void> init() async {
    if (kIsWeb) {
      await Hive.initFlutter();
    } else {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);
    }

    _box = await Hive.openBox(_boxName);

    _monitorConnectivity();
  }

  Future<void> saveLocally(int slotNumber, PlayerSaveData data) async {
    try {
      final key = 'slot_$slotNumber';
      await _box.put(key, data.toJson());
      await _box.flush();

      final verification = _box.get(key);
      if (verification == null) {
      } else {
      }

      _currentSlot = slotNumber;

      if (_isOnline) {
        _syncToCloud(slotNumber, data);
      }
    } catch (e) {
    }
  }

  PlayerSaveData? loadLocally(int slotNumber) {
    try {
      final key = 'slot_$slotNumber';

      if (!_box.containsKey(key)) {
        return null;
      }

      final data = _box.get(key);

      if (data == null) {
        return null;
      }


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

  Future<void> deleteSlot(int slotNumber) async {
    final key = 'slot_$slotNumber';
    await _box.delete(key);

    final userId = _authService.getUserId();
    if (userId != null && _isOnline) {
      try {
        await _cloudService.deleteSlot(userId, slotNumber);
      } catch (e) {
      }
    }
  }

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

  Future<PlayerSaveData?> syncFromCloud(int slotNumber) async {
    final userId = _authService.getUserId();
    if (userId == null) return null;

    try {
      final cloudData = await _cloudService.loadPlayerData(userId, slotNumber);

      if (cloudData != null) {
        final localData = loadLocally(slotNumber);

        if (localData != null) {
          if (cloudData.lastSaved.isAfter(localData.lastSaved)) {
            await saveLocally(slotNumber, cloudData);
            return cloudData;
          } else {
            await _syncToCloud(slotNumber, localData);
            return localData;
          }
        } else {
          await saveLocally(slotNumber, cloudData);
          return cloudData;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

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

  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (_isOnline && wasOffline) {
        syncAllSlots();
      } else if (!_isOnline) {
      }
    });

    Connectivity().checkConnectivity().then((ConnectivityResult result) {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  bool get isOnline => _isOnline;

  PlayerSaveData resolveConflict(
    PlayerSaveData localData,
    PlayerSaveData cloudData,
  ) {
    if (cloudData.lastSaved.isAfter(localData.lastSaved)) {
      return cloudData;
    } else {
      return localData;
    }
  }
}
