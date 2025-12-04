import 'package:flame/components.dart';

class TurnEntity {
  final bool isPlayer;
  final SpriteAnimationComponent?
      enemy;
  final int initiative;

  TurnEntity({required this.isPlayer, this.enemy, required this.initiative});

  @override
  String toString() {
    return isPlayer ? 'Player(Init: $initiative)' : 'Enemy(Init: $initiative)';
  }
}
