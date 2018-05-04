part of battlecity;

List<List<Entity>> _field = new List(yFieldSize);

class BattleGame {
  Symbol _gamestate;
  var player;

  BattleGame() {
    start();
    for(int i = 0; i < yFieldSize; i++) {
      _field[i] = new List(xFieldSize);
    }
    player = new Player(0,0);
  }
  bool get stopped => _gamestate == #stopped;
  bool get running => _gamestate == #running;
  void start() { _gamestate = #running; }
  void stop() { _gamestate = #stopped; }


}

abstract class Entity {
  int positionX;
  int positionY;
  bool transparent;
  String sprite;
}
abstract class DynamicEntity extends Entity {
  void moveLeft() {
    if(positionX > 0) {
      _field[positionY][positionX] = null;
      positionX -= 1;
      _field[positionY][positionX] = this;
    }
  }
  void moveRight() {
    if(positionX < (xFieldSize - 1)) {
      _field[positionY][positionX] = null;
      positionX += 1;
      _field[positionY][positionX] = this;
    }
  }
  void moveUp() {
    if(positionY > 0 ) {
      _field[positionY][positionX] = null;
      positionY -= 1;
      _field[positionY][positionX] = this;
    }
  }
  void moveDown() {
    if(positionY < (yFieldSize - 1)) {
      _field[positionY][positionX] = null;
      positionY += 1;
      _field[positionY][positionX] = this;
    }
  }
}
abstract class StaticEntity extends Entity {

}
class Player extends DynamicEntity {
  Player(posX, posY) {
      positionX = posX;
      positionY = posY;
      transparent = false;
      sprite = "player.png";
      _field[posX][posY] = this;
    }
}