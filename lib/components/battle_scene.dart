import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/components/enemy_hp_bar.dart';
import 'package:renegade_dungeon/components/enemy_target_indicator.dart';

class BattleScene extends Component with HasGameReference<RenegadeDungeonGame> {
  final SpriteAnimationComponent? enemy;
  final List<SpriteAnimationComponent>? enemies;

  late final SpriteComponent _background;
  late final SpriteComponent _playerSprite;
  late final List<EnemyHPBar> _hpBars = [];
  EnemyTargetIndicator? _targetIndicator;
  late final List<_ClickableEnemy> _enemyWrappers = [];

  BattleScene({this.enemy, this.enemies});

  @override
  Future<void> onLoad() async {
    _background = SpriteComponent(
      sprite: await game.loadSprite('backgrounds/battle_background_forest.png'),
      anchor: Anchor.center,
      priority: 0,
    );
    add(_background);

    _playerSprite = SpriteComponent(
      sprite: await game.loadSprite('characters/player_w.png'),
      size: Vector2.all(200),
      anchor: Anchor.center,
      priority: 10,
    );
    add(_playerSprite);

    if (enemies != null && enemies!.isNotEmpty) {
      for (int i = 0; i < enemies!.length; i++) {
        final e = enemies![i];

        final clickable = _ClickableEnemy(
          enemy: e,
          enemyIndex: i,
          onTap: _onEnemyTapped,
        );
        clickable.priority = 10;
        _enemyWrappers.add(clickable);
        add(clickable);

        final hpBar = EnemyHPBar(enemy: e);
        hpBar.priority = 20;
        _hpBars.add(hpBar);
        add(hpBar);
      }

      _updateTargetIndicator();

      game.combatManager.currentTurn.addListener(_onTargetChanged);
    } else if (enemy != null) {
      enemy!.size = Vector2.all(160);
      enemy!.anchor = Anchor.center;
      add(enemy!);

      final hpBar = EnemyHPBar(enemy: enemy!);
      _hpBars.add(hpBar);
      add(hpBar);
    }
  }

  void removeEnemy(int index) {
    if (index >= 0 && index < _enemyWrappers.length) {
      final wrapper = _enemyWrappers[index];
      final hpBar = _hpBars[index];

      wrapper.removeFromParent();
      hpBar.removeFromParent();

      _enemyWrappers.removeAt(index);
      _hpBars.removeAt(index);

      for (int i = 0; i < _enemyWrappers.length; i++) {
        _enemyWrappers[i].enemyIndex = i;
      }
    }
  }

  void _onEnemyTapped(int index) {
    game.combatManager.selectedTargetIndex = index;
    _updateTargetIndicator();
  }

  void _onTargetChanged() {
    _updateTargetIndicator();
  }

  void _updateTargetIndicator() {
    if (_targetIndicator != null) {
      _targetIndicator!.removeFromParent();
      _targetIndicator = null;
    }

    if (enemies != null && enemies!.isNotEmpty) {
      final targetIndex = game.combatManager.selectedTargetIndex;
      if (targetIndex >= 0 && targetIndex < enemies!.length) {
        _targetIndicator = EnemyTargetIndicator(enemy: enemies![targetIndex]);
        add(_targetIndicator!);
      }
    }
  }

  @override
  void onRemove() {
    game.combatManager.currentTurn.removeListener(_onTargetChanged);
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _background.size = size;
    _background.position = size / 2;

    final double spriteY = size.y * 0.55;

    _playerSprite.position = Vector2(size.x * 0.25, spriteY);

    if (enemies != null && enemies!.isNotEmpty) {
      final enemyCount = enemies!.length;

      if (enemyCount == 1) {
        enemies![0].position = Vector2(size.x * 0.75, spriteY);
        if (_hpBars.isNotEmpty)
          _hpBars[0].position = Vector2(size.x * 0.75 - 60, spriteY - 100);
      } else if (enemyCount == 2) {
        enemies![0].position = Vector2(size.x * 0.60, spriteY);
        enemies![1].position = Vector2(size.x * 0.85, spriteY);

        if (_hpBars.length >= 2) {
          _hpBars[0].position = Vector2(size.x * 0.60 - 60, spriteY - 100);
          _hpBars[1].position = Vector2(size.x * 0.85 - 60, spriteY - 100);
        }
      } else if (enemyCount == 3) {
        enemies![0].position = Vector2(size.x * 0.55, spriteY);
        enemies![1].position = Vector2(size.x * 0.725, spriteY);
        enemies![2].position = Vector2(size.x * 0.90, spriteY);

        if (_hpBars.length >= 3) {
          _hpBars[0].position = Vector2(size.x * 0.55 - 60, spriteY - 100);
          _hpBars[1].position = Vector2(size.x * 0.725 - 60, spriteY - 100);
          _hpBars[2].position = Vector2(size.x * 0.90 - 60, spriteY - 100);
        }
      }
    } else if (enemy != null) {
      enemy!.position = Vector2(size.x * 0.75, spriteY);
      if (_hpBars.isNotEmpty) {
        _hpBars[0].position = Vector2(size.x * 0.75 - 60, spriteY - 100);
      }
    }
  }
}

class _ClickableEnemy extends PositionComponent with TapCallbacks {
  final SpriteAnimationComponent enemy;
  int enemyIndex;
  final void Function(int) onTap;

  _ClickableEnemy({
    required this.enemy,
    required this.enemyIndex,
    required this.onTap,
  }) : super(size: Vector2.all(160), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    enemy.size = Vector2.all(160);
    enemy.anchor = Anchor.center;
    enemy.position = Vector2.zero();
    add(enemy);
  }

  @override
  void update(double dt) {
    super.update(dt);
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap(enemyIndex);
  }
}
