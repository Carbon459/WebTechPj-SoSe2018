part of battlecity;

/// Das momentan aktive Modellspielfeld
Level activeField;

class BattleGame {
  Symbol _gamestate;
  Player player;

  BattleGame() {
    start();
    activeField = new Level(xFieldSize, yFieldSize);
    player = new Player(0,0);
  }
  bool get stopped => _gamestate == #stopped;
  bool get running => _gamestate == #running;
  void start() { _gamestate = #running; }
  void stop() { _gamestate = #stopped; }


}

class Level{
  List<List<Entity>> _levelField;
  List<List<Entity>> get levelField => _levelField;
  Map toJson() => {"levelField":_levelField};
  Level fromJson(Map json) {
    this._levelField = json["levelField"];
    return this;
  }
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
  bool isOutOfBounds(int atPosX, int atPosY) {
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
    if(isOutOfBounds(atPosX, atPosY)) { //Wenn Ziel außerhalb des Spielfeldes
      if(debug) {print("Pos($atPosX|$atPosY) out of bounds!");}
      return true;
    }
    if(getEntityAt(atPosX, atPosY) != null) { //Kollision mit anderen Entitäten
      if(debug) {print("Pos($atPosX|$atPosY) collision!");}
      return true;
    }
    return false;
  }

  /**
   * Gibt die Entität an der gegebenen Position zurück.
   * Falls dort keine existiert wird null zurückgegeben.
   */
  Entity getEntityAt(int atPosX, int atPosY) {
    return _levelField[atPosY][atPosX];
  }

  /**
   * Bewegt im Level der aktuellen Instanz eine Entität um eine Einheit in die gewünschte Richtung.
   * Mögliche Richtungen: #left, #right, #up, #down
   * Gibt true zurück, falls bewegt wurde. Bei Kolission false
   */
  bool moveEntityRelative(int fromPosX, int fromPosY, Symbol direction) {
    DynamicEntity ent = _levelField[fromPosY][fromPosX];
    if(debug) {print("moveEntityFrom:($fromPosX|$fromPosY)$direction $ent");}
    int newPosX = fromPosX;
    int newPosY = fromPosY;
    switch(direction.toString()) {
      case 'Symbol("left")':
        newPosX = fromPosX - 1;
        break;
      case 'Symbol("right")':
        newPosX = fromPosX + 1;
        break;
      case 'Symbol("up")':
        newPosY = fromPosY - 1;
        break;
      case 'Symbol("down")':
        newPosY = fromPosY + 1;
        break;
    }
    if(!activeField.collisionAt(newPosX, newPosY)) {
      this.removeEntity(fromPosX, fromPosY);
      this.setEntity(newPosX, newPosY, ent);
      return true;
    } else if(!activeField.isOutOfBounds(newPosX, newPosY)) {
        //TODO: Kollision mit Entity
      return false;
    } else { //OutofBounds
      return false;
    }
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

class LevelLoader {
  //TODO json level loader implementieren
  static Level getLevelFromJson(String url) {
    HttpRequest.getString(url).then((String json) {return JSON.decode(json);});
    return null;
  }
  static void saveLevelToJson(Level lvl, String fileName) {
    if(debug) { print(JSON.encode(lvl)); }
  }
  static void testlevel() {
    new Scenery(5, 5, "house");
    new Scenery(6, 5, "house");
    new Scenery(7, 5, "house");
    new Scenery(8, 5, "house");
    new Scenery(8, 4, "house");
    new Scenery(8, 6, "house");
  }
}