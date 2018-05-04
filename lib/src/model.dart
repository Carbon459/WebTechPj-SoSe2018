part of battlecity;

/// Das momentan aktive Modellspielfeld
Level activeField;
///Liste aller Objekte, die zu jedem Tick bewegt werden müssen (Projektile und Gegner).
List<DynamicEntity> selfmoving;

class BattleGame {
  Symbol _gamestate;
  var player;

  BattleGame() {
    start();
    activeField = LevelLoader.getLevelFromJson("1.json");
    selfmoving = new List<DynamicEntity>();
    player = new Player(0,0);
  }
  bool get stopped => _gamestate == #stopped;
  bool get running => _gamestate == #running;
  void start() { _gamestate = #running; }
  void stop() { _gamestate = #stopped; }


}


/**
 * Repräsentiert ein Level
 */
class Level {
  List<List<Entity>> _levelField;
  List<List<Entity>> get levelField => _levelField;

  /**
   * Setzt im Level der aktuellen Instanz eine Entität auf das Spielfeld.
   */
  void setEntity(int posX, int posY, Entity ent) {
    _levelField[posY][posX] = ent;
    ent.positionX = posX;
    ent.positionY = posY;
  }

  /**
   * Entfernt im Level der aktuellen Instanz eine Entität vom Spielfeld.
   */
  void removeEntity(int posX, int posY) {
    _levelField[posY][posX] = null;
  }

  /**
   * Prüft, ob die angegebene Koordinate außerhalb des Spielfeldes liegt.
   */
  bool outOfBounds(int atPosX, int atPosY) {
    if(atPosX < 0 || atPosX >= xFieldSize || atPosY < 0 || atPosY >= yFieldSize) {
      return true;
    }
    return false;
  }
  /**
   * Prüft ob an der gegeben Koordinate etwas zum kollidieren ist.
   * true: Kollision!
   */
  bool collisionAt(int atPosX, int atPosY) {
    //Wenn Ziel außerhalb des Spielfeldes -> Kollision
    if(outOfBounds(atPosX, atPosY)) {
      if(debug) {print("Pos($atPosX|$atPosY) invalid!");}
      return true;
    }
    //TODO Kollision mit anderen Entitys prüfen
    return false;
  }
  Entity getEntityAt(int atPosX, int atPosY) {
    return _levelField[atPosY][atPosX];
  }
  /**
   * Bewegt im Level der aktuellen Instanz eine Entität um eine Einheit in die gewünschte Richtung.
   * Mögliche Richtungen: #left, #right, #up, #down
   * Gibt true zurück, falls bewegt wurde. Bei Kolission false
   */
  bool moveEntityRelative(int fromPosX, int fromPosY, Symbol direction) {
    final ent = _levelField[fromPosY][fromPosX];
    switch(direction.toString()) {
      case 'Symbol("left")':
        final int newPosX = fromPosX - 1;
        if(!activeField.collisionAt(newPosX, fromPosY)) {
          this.removeEntity(fromPosX, fromPosY);
          this.setEntity(newPosX, fromPosY, ent);
          return true;
        } else if(!activeField.outOfBounds(newPosX, fromPosY)) {
          //TODO: Kollision mit Entity
          return false;
        } else { //OutofBounds
          //wird in _moveDynamicEntities() gesammelt und zerstört, um "Uncaught Error: Concurrent modification during iteration" zu verhindern
          return false;
        }
        break;
      case 'Symbol("right")':
        final int newPosX = fromPosX + 1;
        if(!activeField.collisionAt(newPosX, fromPosY)) {
          this.removeEntity(fromPosX, fromPosY);
          this.setEntity(newPosX, fromPosY, ent);
          return true;
        } else if(!activeField.outOfBounds(newPosX, fromPosY)) {
          //TODO: Kollision mit Entity
          return false;
        } else { //OutofBounds
          //wird in _moveDynamicEntities() gesammelt und zerstört, um "Uncaught Error: Concurrent modification during iteration" zu verhindern
          return false;
        }
        break;
      case 'Symbol("up")':
        final int newPosY = fromPosY - 1;
        if(!activeField.collisionAt(fromPosX, newPosY)) {
          this.removeEntity(fromPosX, fromPosY);
          this.setEntity(fromPosX, newPosY, ent);
          return true;
        } else if(!activeField.outOfBounds(fromPosX, newPosY)) {
          //TODO: Kollision mit Entity
          return false;
        } else { //OutofBounds
          //wird in _moveDynamicEntities() gesammelt und zerstört, um "Uncaught Error: Concurrent modification during iteration" zu verhindern
          return false;
        }
        break;
      case 'Symbol("down")':
        final int newPosY = fromPosY + 1;
        if(!activeField.collisionAt(fromPosX, newPosY)) {
          this.removeEntity(fromPosX, fromPosY);
          this.setEntity(fromPosX, newPosY, ent);
          return true;
        } else if(!activeField.outOfBounds(fromPosX, newPosY)) {
          //TODO: Kollision mit Entity
          return false;
        } else { //OutofBounds
          //wird in _moveDynamicEntities() gesammelt und zerstört, um "Uncaught Error: Concurrent modification during iteration" zu verhindern
          return false;
        }
        break;
    }
    return false;
  }

  /**
   * Konstruktor für ein komplett leeres Level
   */
  Level(int xSize, int ySize) {
    _levelField = new List(ySize);
    for(int i = 0; i < ySize; i++) {
      _levelField[i] = new List(xSize);
    }
  }
}
/**
 * Dient dazu, Level zu laden.
 */
class LevelLoader {
  static Level getLevelFromJson(String name) {
    //TODO json level loader implementieren
    return new Level(xFieldSize, yFieldSize);
  }
}