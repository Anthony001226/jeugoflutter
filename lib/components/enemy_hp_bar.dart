import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:renegade_dungeon/models/enemy_stats.dart';
import 'package:renegade_dungeon/models/combat_stats_holder.dart';

class EnemyHPBar extends PositionComponent {
  final SpriteAnimationComponent enemy;
  late final TextComponent _hpText;
  late final RectangleComponent _backgroundBar;
  late final RectangleComponent _healthBar;

  EnemyHPBar({required this.enemy}) : super(size: Vector2(120, 20));

  @override
  Future<void> onLoad() async {
    _backgroundBar = RectangleComponent(
      size: Vector2(120, 8),
      paint: Paint()..color = Colors.red.withOpacity(0.5),
      position: Vector2(0, 12),
    );
    add(_backgroundBar);

    _healthBar = RectangleComponent(
      size: Vector2(120, 8),
      paint: Paint()..color = Colors.green,
      position: Vector2(0, 12),
    );
    add(_healthBar);

    _hpText = TextComponent(
      text: _getHpText(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(60, 0),
    );
    add(_hpText);

    final stats = (enemy as dynamic).stats;
    if (stats is EnemyStats) {
      stats.currentHp.addListener(_updateHP);
    } else if (stats is CombatStatsHolder) {
      stats.combatStats.currentHp.addListener(_updateHP);
    }
  }

  String _getHpText() {
    final stats = (enemy as dynamic).stats;
    int currentHp = 0;
    int maxHp = 0;

    if (stats is EnemyStats) {
      currentHp = stats.currentHp.value;
      maxHp = stats.maxHp;
    } else if (stats is CombatStatsHolder) {
      currentHp = stats.combatStats.currentHp.value;
      maxHp = stats.combatStats.maxHp.value;
    }

    return '$currentHp/$maxHp HP';
  }

  void _updateHP() {
    _hpText.text = _getHpText();

    final stats = (enemy as dynamic).stats;
    double hpPercent = 0.0;

    if (stats is EnemyStats) {
      hpPercent = stats.currentHp.value / stats.maxHp;
    } else if (stats is CombatStatsHolder) {
      hpPercent =
          stats.combatStats.currentHp.value / stats.combatStats.maxHp.value;
    }

    _healthBar.size.x = (120 * hpPercent).clamp(0, 120);

    if (hpPercent > 0.6) {
      _healthBar.paint.color = Colors.green;
    } else if (hpPercent > 0.3) {
      _healthBar.paint.color = Colors.orange;
    } else {
      _healthBar.paint.color = Colors.red;
    }
  }

  @override
  void onRemove() {
    final stats = (enemy as dynamic).stats;
    if (stats is EnemyStats) {
      stats.currentHp.removeListener(_updateHP);
    } else if (stats is CombatStatsHolder) {
      stats.combatStats.currentHp.removeListener(_updateHP);
    }
    super.onRemove();
  }
}
