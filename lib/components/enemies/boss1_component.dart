// lib/components/enemies/boss1_component.dart

import 'package:flame/components.dart';
import 'package:renegade_dungeon/models/combat_stats.dart';
import 'package:renegade_dungeon/models/combat_stats_holder.dart';
import 'package:renegade_dungeon/models/combat_ability.dart';
import 'package:renegade_dungeon/models/ability_database.dart';
import 'package:renegade_dungeon/models/inventory_item.dart';
import 'package:renegade_dungeon/models/enemy_stats.dart';

// Boss1 Stats - Implementa CombatStatsHolder para el sistema de combate
class Boss1Stats extends EnemyStats implements CombatStatsHolder {
  @override
  final CombatStats combatStats;

  Boss1Stats(this.combatStats)
      : super(
          maxHp: combatStats.maxHp.value,
          attack: combatStats.attack.value,
          defense: combatStats.defense.value,
          speed: combatStats.speed.value,
          xpValue: 500, // Alto XP por ser un jefe
          lootTable: {
            // Los jefes tienen mejor loot
            ItemDatabase.potion: 1.0, // 100% drop de poción
            ItemDatabase.rustySword: 0.80, // 80% drop de espada
          },
        ) {
    // Sincronizar valores iniciales
    currentHp.value = combatStats.currentHp.value;

    // Escuchar cambios en combatStats y sincronizar
    combatStats.currentHp.addListener(() {
      currentHp.value = combatStats.currentHp.value;
    });
  }

  @override
  void takeDamage(int amount) {
    combatStats.takeDamage(amount);
  }
}

class Boss1Component extends SpriteAnimationComponent with HasGameReference {
  late final Boss1Stats stats;
  late final List<CombatAbility> abilities;

  // Almacenamos las animaciones aquí
  final Map<String, SpriteAnimation> _animations = {};
  String _currentAnimationKey = 'idle1';

  Boss1Component() : super(size: Vector2(160, 117)) {
    // Initialize stats en el constructor - stats de JEFE
    final combatStats = CombatStats(
      initialHp: 150, // ALTO HP
      initialMaxHp: 150,
      initialMp: 50,
      initialMaxMp: 50,
      initialSpeed: 12, // Velocidad media-alta
      initialAttack: 25, // ALTO ATAQUE
      initialDefense: 15, // ALTA DEFENSA
      initialCritChance: 0.15, // 15% crítico
    );

    stats = Boss1Stats(combatStats);

    // Habilidades del jefe - usaremos las de boss1 cuando las agregues a AbilityDatabase
    abilities = AbilityDatabase.getBoss1Abilities();
  }

  @override
  Future<void> onLoad() async {
    await _loadAnimations();
    // Iniciar con la animación idle1
    animation = _animations['idle1'];
  }

  Future<void> _loadAnimations() async {
    // Cargar el JSON con la información de los frames
    final jsonData = await game.assets.readJson('images/enemies/boss1.json');
    final image = await game.images.load('enemies/boss1.png');

    // Parsear datos de Aseprite
    final asepriteData = AsepriteData.fromJson(jsonData);

    // IDLE1 - La única animación que tienes actualmente
    // Como no hay frameTags en el JSON, cargamos todos los frames como idle1
    _animations['idle1'] = await asepriteData.getAllFramesAnimation(image);

    // TODO: Agregar más adelante cuando tengas los sprites
    // _animations['idle2'] = await asepriteData.getAnimation('idle2', image);
    // _animations['ataque'] = await asepriteData.getAnimation('ataque', image);
    // _animations['pesado'] = await asepriteData.getAnimation('pesado', image);
    // _animations['ulti'] = await asepriteData.getAnimation('ulti', image);
  }

  /// Cambia la animación actual
  void playAnimation(String animationKey) {
    if (_animations.containsKey(animationKey)) {
      _currentAnimationKey = animationKey;
      animation = _animations[animationKey];
    }
  }

  /// Obtiene la animación actual
  String get currentAnimation => _currentAnimationKey;
}

// Clase helper para parsear los datos de Aseprite
class AsepriteData {
  final Map<String, dynamic> _json;
  AsepriteData.fromJson(this._json);

  /// Carga una animación específica basada en un frameTag
  Future<SpriteAnimation> getAnimation(String tag, image) async {
    final frameData = _json['frames'] as Map<String, dynamic>;
    final meta = _json['meta'];
    final frameTags = (meta['frameTags'] as List)
        .firstWhere((t) => t['name'] == tag, orElse: () => null);

    if (frameTags == null) {
      throw Exception('Tag "$tag" not found in Aseprite JSON file.');
    }

    final frameKeys = frameData.keys.toList();
    final firstFrameKey = frameKeys[frameTags['from']];
    final firstFrameInfo = frameData[firstFrameKey]['frame'];
    final firstFrameSize =
        Vector2(firstFrameInfo['w'].toDouble(), firstFrameInfo['h'].toDouble());

    final frameDurations = (frameData.values
            .toList()
            .sublist(frameTags['from'], frameTags['to'] + 1))
        .map<double>((e) => (e['duration'] as int) / 1000.0)
        .toList();

    final animationData = SpriteAnimationData.variable(
      amount: frameDurations.length,
      stepTimes: frameDurations,
      textureSize: firstFrameSize,
    );

    return SpriteAnimation.fromFrameData(image, animationData);
  }

  /// Carga todos los frames como una sola animación (para cuando no hay frameTags)
  Future<SpriteAnimation> getAllFramesAnimation(image) async {
    final frameData = _json['frames'] as Map<String, dynamic>;
    final frameKeys = frameData.keys.toList();

    if (frameKeys.isEmpty) {
      throw Exception('No frames found in Aseprite JSON file.');
    }

    // Obtener info del primer frame para el tamaño
    final firstFrameInfo = frameData[frameKeys[0]]['frame'];
    final frameSize =
        Vector2(firstFrameInfo['w'].toDouble(), firstFrameInfo['h'].toDouble());

    // Obtener duraciones de todos los frames
    final frameDurations = frameData.values
        .map<double>((e) => (e['duration'] as int) / 1000.0)
        .toList();

    final animationData = SpriteAnimationData.variable(
      amount: frameDurations.length,
      stepTimes: frameDurations,
      textureSize: frameSize,
    );

    return SpriteAnimation.fromFrameData(image, animationData);
  }
}
