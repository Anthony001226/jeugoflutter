class SaveSlotMetadata {
  final int slotNumber;
  final String characterName;
  final int level;
  final String currentMap;
  final int playTimeSeconds;
  final DateTime lastSaved;

  SaveSlotMetadata({
    required this.slotNumber,
    required this.characterName,
    required this.level,
    required this.currentMap,
    required this.playTimeSeconds,
    required this.lastSaved,
  });

  Map<String, dynamic> toJson() {
    return {
      'slotNumber': slotNumber,
      'characterName': characterName,
      'level': level,
      'currentMap': currentMap,
      'playTimeSeconds': playTimeSeconds,
      'lastSaved': lastSaved.toIso8601String(),
    };
  }

  factory SaveSlotMetadata.fromJson(Map<String, dynamic> json) {
    return SaveSlotMetadata(
      slotNumber: json['slotNumber'] ?? 1,
      characterName: json['characterName'] ?? 'Héroe',
      level: json['level'] ?? 1,
      currentMap: json['currentMap'] ?? 'dungeon.tmx',
      playTimeSeconds: json['playTimeSeconds'] ?? 0,
      lastSaved: DateTime.parse(json['lastSaved']),
    );
  }

  // Format play time for display
  String get formattedPlayTime {
    final hours = playTimeSeconds ~/ 3600;
    final minutes = (playTimeSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  // Format last saved for display
  String get formattedLastSaved {
    final now = DateTime.now();
    final difference = now.difference(lastSaved);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }
}
