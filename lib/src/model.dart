part of battlecity;

class BattleGame {
  Symbol _gamestate;
  List<List<Entity>> _field;
  Player _player;

  BattleGame() {
    start();
    _player = new Player();

  }
  bool get stopped => _gamestate == #stopped;
  bool get running => _gamestate == #running;
  void start() { _gamestate = #running; }
  void stop() { _gamestate = #stopped; }

}

abstract class Entity {
  int positionX;
  int positionY;
  bool active;
  bool transparent;
}
abstract class DynamicEntity extends Entity {

}
abstract class StaticEntity extends Entity {

}
class Player extends DynamicEntity {
  Player() {

  }
}