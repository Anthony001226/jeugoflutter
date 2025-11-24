// lib/components/battle_scene.dart

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/components/enemy_hp_bar.dart';
import 'package:renegade_dungeon/components/enemy_target_indicator.dart';

class BattleScene extends Component with HasGameReference<RenegadeDungeonGame> {
  // Support both single enemy (legacy) and multi-enemy modes
  final SpriteAnimationComponent? enemy;
  final List<SpriteAnimationComponent>? enemies;

  late final SpriteComponent _background;
  late final SpriteComponent _playerSprite;
  late final List<EnemyHPBar> _hpBars = [];
  EnemyTargetIndicator? _targetIndicator;
  late final List<_ClickableEnemy> _enemyWrappers = [];

  // Constructor supports both modes
  BattleScene({this.enemy, this.enemies});

  @override
  Future<void> onLoad() async {
    // 1. Load background
    _background = SpriteComponent(
      sprite: await game.loadSprite('backgrounds/battle_background_forest.png'),
      anchor: Anchor.center,
      priority: 0, // Render first (background)
    );
    add(_background);

    // 2. Load player
    _playerSprite = SpriteComponent(
      sprite: await game.loadSprite('characters/player_battle.png'),
      size: Vector2.all(200),
      anchor: Anchor.center,
      priority: 10, // Render above background
    );
    add(_playerSprite);

    // 3. Add enemies (single or multi)
    if (enemies != null && enemies!.isNotEmpty) {
      // Multi-enemy mode
      for (int i = 0; i < enemies!.length; i++) {
        final e = enemies![i];

        // Wrap enemy in clickable component
        final clickable = _ClickableEnemy(
          enemy: e,
          enemyIndex: i,
          onTap: _onEnemyTapped,
        );
        clickable.priority = 10; // Same as player
        _enemyWrappers.add(clickable);
        add(clickable);

        // Add HP bar for each enemy
        final hpBar = EnemyHPBar(enemy: e);
        hpBar.priority = 20; // Above sprites
        _hpBars.add(hpBar);
        add(hpBar);
      }

      // Add target indicator for first enemy
      _updateTargetIndicator();

      // Listen for target changes
      game.combatManager.currentTurn.addListener(_onTargetChanged);
    } else if (enemy != null) {
      // Single enemy mode (backward compatibility)
      enemy!.size = Vector2.all(160);
      enemy!.anchor = Anchor.center;
      add(enemy!);

      // Add HP bar for single enemy
      final hpBar = EnemyHPBar(enemy: enemy!);
      _hpBars.add(hpBar);
      add(hpBar);
    }
  }

  /// Remove visual components of a defeated enemy
  void removeEnemy(int index) {
    if (index >= 0 && index < _enemyWrappers.length) {
      // Remove visual components
      final wrapper = _enemyWrappers[index];
      final hpBar = _hpBars[index];

      wrapper.removeFromParent();
      hpBar.removeFromParent();

      // Remove from lists
      _enemyWrappers.removeAt(index);
      _hpBars.removeAt(index);

      // Update indices for remaining enemies
      for (int i = 0; i < _enemyWrappers.length; i++) {
        _enemyWrappers[i].enemyIndex = i;
      }
    }
  }

  void _onEnemyTapped(int index) {
    print('🎯 Enemy #${index + 1} tapped!');
    game.combatManager.selectedTargetIndex = index;
    _updateTargetIndicator();
  }

  void _onTargetChanged() {
    _updateTargetIndicator();
  }

  void _updateTargetIndicator() {
    // Remove old indicator
    if (_targetIndicator != null) {
      _targetIndicator!.removeFromParent();
      _targetIndicator = null;
    }

    // Add new indicator if in multi-enemy mode
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
    _playerSprite.position = Vector2(size.x * 0.25, size.y * 0.6);

    // Position enemies based on count
    if (enemies != null && enemies!.isNotEmpty) {
      final enemyCount = enemies!.length;

      if (enemyCount == 1) {
        // Single enemy: center-right
        enemies![0].position = Vector2(size.x * 0.75, size.y * 0.6);
        if (_hpBars.isNotEmpty)
          _hpBars[0].position = Vector2(size.x * 0.75 - 60, size.y * 0.6 - 100);
      } else if (enemyCount == 2) {
        // Two enemies: spread horizontally (wider)
        enemies![0].position = Vector2(size.x * 0.60, size.y * 0.6);
        enemies![1].position = Vector2(size.x * 0.85, size.y * 0.6);

        if (_hpBars.length >= 2) {
          _hpBars[0].position = Vector2(size.x * 0.60 - 60, size.y * 0.6 - 100);
          _hpBars[1].position = Vector2(size.x * 0.85 - 60, size.y * 0.6 - 100);
        }
      } else if (enemyCount == 3) {
        // Three enemies: left, center, right (wider)
        enemies![0].position = Vector2(size.x * 0.55, size.y * 0.6);
        enemies![1].position = Vector2(size.x * 0.725, size.y * 0.6);
        enemies![2].position = Vector2(size.x * 0.90, size.y * 0.6);

        if (_hpBars.length >= 3) {
          _hpBars[0].position = Vector2(size.x * 0.55 - 60, size.y * 0.6 - 100);
          _hpBars[1].position =
              Vector2(size.x * 0.725 - 60, size.y * 0.6 - 100);
          _hpBars[2].position = Vector2(size.x * 0.90 - 60, size.y * 0.6 - 100);
        }
      }
    } else if (enemy != null) {
      // Single enemy mode (legacy)
      enemy!.position = Vector2(size.x * 0.75, size.y * 0.6);
      if (_hpBars.isNotEmpty) {
        _hpBars[0].position = Vector2(size.x * 0.75 - 60, size.y * 0.6 - 100);
      }
    }
  }
}

/// Wrapper component that makes an enemy clickable
class _ClickableEnemy extends PositionComponent with TapCallbacks {
  final SpriteAnimationComponent enemy;
  int enemyIndex; // Made mutable
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
    enemy.position = Vector2.zero(); // Position relative to wrapper
    add(enemy);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Position is managed by onGameResize, no need to follow enemy
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap(enemyIndex);
  }
}
