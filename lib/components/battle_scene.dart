// lib/components/battle_scene.dart

import 'package:flame/components.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';

class BattleScene extends Component with HasGameReference<RenegadeDungeonGame> {
  // ¡LÍNEA MODIFICADA! Ahora acepta el componente enemigo directamente.
  final SpriteAnimationComponent enemy;

  late final SpriteComponent _background;
  late final SpriteComponent _playerSprite;

  // ¡CONSTRUCTOR MODIFICADO!
  BattleScene({required this.enemy});

  @override
  Future<void> onLoad() async {
    // 1. Cargar fondo
    _background = SpriteComponent(
      sprite: await game.loadSprite('backgrounds/battle_background_forest.png'),
      anchor: Anchor.center,
    );
    add(_background);

    // 2. Cargar jugador
    _playerSprite = SpriteComponent(
      sprite: await game.loadSprite('characters/player_battle.png'),
      size: Vector2.all(200),
      anchor: Anchor.center,
    );
    add(_playerSprite);

    // 3. El enemigo ya fue pre-cargado pero removido del juego
    // Ahora lo agregamos como hijo de BattleScene
    add(enemy);
    // Ajustamos su tamaño aquí
    enemy.size = Vector2.all(160);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _background.size = size;
    _background.position = size / 2;
    _playerSprite.position = Vector2(size.x * 0.25, size.y * 0.6);
    // Posicionamos al enemigo que nos pasaron
    enemy.position = Vector2(size.x * 0.75, size.y * 0.6);
  }
}
