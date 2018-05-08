part of battlecity;

/// Das momentan aktive Modellspielfeld
Level activeField;
Player player;

class BattleGame {
  Symbol _gamestate;

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
    return new Level.fromList(json["levelField"]);
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
    if(isOutOfBounds(atPosX, atPosY)) return null;
    return _levelField[atPosY][atPosX];
  }
  static int getNewPosX(int posX, Symbol direction) {
    int newPosX = posX;
    switch(direction.toString()) {
      case 'Symbol("left")':
        newPosX = posX - 1;
        break;
      case 'Symbol("right")':
        newPosX = posX + 1;
        break;
    }
    return newPosX;
  }
  static int getNewPosY(int posY, Symbol direction) {
    int newPosY = posY;
    switch(direction.toString()) {
      case 'Symbol("up")':
        newPosY = posY - 1;
        break;
      case 'Symbol("down")':
        newPosY = posY + 1;
        break;
    }
    return newPosY;
  }
  /**
   * Bewegt im Level der aktuellen Instanz eine Entität um eine Einheit in die gewünschte Richtung.
   * Mögliche Richtungen: #left, #right, #up, #down
   * Gibt true zurück, falls bewegt wurde. Bei Kolission false
   */
  bool moveEntityRelative(int fromPosX, int fromPosY, Symbol direction) {
    DynamicEntity ent = _levelField[fromPosY][fromPosX];
    if(debug) {print("moveEntityFrom:($fromPosX|$fromPosY)$direction $ent");}

    final int newPosX = getNewPosX(fromPosX, direction);
    final int newPosY = getNewPosY(fromPosY, direction);

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
  Level.fromList(List<List<Entity>> l) {
    _levelField = l;
  }
}

class LevelLoader {
  //TODO json level loader implementieren
  static Future<Level> getLevelFromJson (String url) async {
    String s = await HttpRequest.getString(url);
    return JSON.decode(s);
  }
  static void printLevelAsJson(Level lvl) {
    print(JSON.encode(lvl));
  }
  static void testlevel() {
    new Scenery(5, 5, "house.png");
    new Scenery(6, 5, "house.png");
    new Scenery(7, 5, "house.png");
    new Scenery(8, 5, "house.png");
    new Scenery(8, 4, "house.png");
    new Scenery(8, 6, "house.png");
  }
}