part of battlecity;

/**
 * Hilfsklasse (Wird wie ein struct verwendet)
 */
class Coordinates {
  int positionX;
  int positionY;
  int counter;

  Coordinates(int posX, int posY) {
    positionX = posX;
    positionY = posY;
  }

  Coordinates.withCounter(int posX, int posY, int c) {
    positionX = posX;
    positionY = posY;
    counter = c;
  }
}

/**
 * Stellt ein Level dar
 */
class Level{
  static Level active;
  static List<Enemy> activeEnemies = new List<Enemy>();

  List<List<Entity>> levelField;
  List<List<Background>> levelFieldBackground;
  ///Enthält das Ergebnis des Pathfindings
  List<List<int>> pathToPlayer;
  ///Enthält alle Koordinaten von Entities, die beim nächsten Tick neu gerendet werden müssen
  List<Coordinates> changed = new List<Coordinates>();

  Map toJson() {
    Map<String, dynamic> map = new Map();
    int i = 0;
    for(int y = 0; y < YFIELDSIZE; y++) {
      for(int x = 0; x < XFIELDSIZE; x++) {
        if(levelField[y][x] != null) {
          map.putIfAbsent("$i", () => levelField[y][x]);
          i++;
        }
        if(levelFieldBackground[y][x] != null) {
          map.putIfAbsent("$i", () => levelFieldBackground[y][x]);
          i++;
        }
      }
    }
    return map;
  }

  /**
   * ManyToOne Pathfinding
   * Wie beschrieben in https://en.wikipedia.org/wiki/Pathfinding#Sample_algorithm
   */
  void mapPathToEntity(List<Entity> mapFrom, Entity mapTo) {
    if(mapFrom.isEmpty || mapTo == null) return;

    num time = window.performance.now();

    List<Coordinates> queue = new List<Coordinates>();

    int curPosX = mapTo.positionX;
    int curPosY = mapTo.positionY;
    int curCounter = 0;

    queue.add(new Coordinates.withCounter(curPosX, curPosY, curCounter)); //Ziel
    List<Entity> entitiesToMapLeft = new List<Entity>();
    entitiesToMapLeft.addAll(mapFrom);
    try {
    while(!queue.isEmpty) {
      if(entitiesToMapLeft.isEmpty) break; //Bis Queue leer oder Pfade von allen Gegnern zum Spieler gemappt
      List<Coordinates> temp = new List<Coordinates>(4);
      curPosX = queue.elementAt(curCounter).positionX;
      curPosY = queue.elementAt(curCounter).positionY;
      curCounter++;

      temp[0] = new Coordinates.withCounter(curPosX + 1, curPosY, curCounter);
      temp[1] = new Coordinates.withCounter(curPosX - 1, curPosY, curCounter);
      temp[2] = new Coordinates.withCounter(curPosX, curPosY + 1, curCounter);
      temp[3] = new Coordinates.withCounter(curPosX, curPosY - 1, curCounter);

      for(int i = 0; i < 4; i++) {
        if(entitiesToMapLeft.any((f) {return active.getEntityAt(temp[i].positionX, temp[i].positionY) == f;})) break;
        if(collisionAt(temp[i].positionX, temp[i].positionY) || queue.any((ph) {return temp[i].positionX == ph.positionX && temp[i].positionY == ph.positionY && ph.counter <= temp[i].counter;})) {
          temp[i] = null;
        }
      }
      for(Coordinates x in temp) {
        if(x != null && !isInvalid(x.positionX, x.positionY)) queue.add(x);
      }

      //Am Gegner angekommen? Pfad für diesen gemappt, also abhaken
      for(int i = 0; i < entitiesToMapLeft.length; i++) {
        if(curPosX == entitiesToMapLeft[i].positionX && curPosY == entitiesToMapLeft[i].positionY) {
          entitiesToMapLeft.removeAt(i);
        }
      }
    }
    } catch(e) {
      print(e);
      return; //Fortschritte beim Pathing verwerfen
    }

    for(int y = 0; y < YFIELDSIZE; y++) {//2d Liste reinitialisieren
      for(int x = 0; x < XFIELDSIZE; x++) {
        pathToPlayer[y][x] = YFIELDSIZE*XFIELDSIZE;
      }
    }

    for(Coordinates ph in queue) { //Ergebnisse auf 2D Liste mappen
      pathToPlayer[ph.positionY][ph.positionX] = ph.counter;
    }

    if(DEBUG && (window.performance.now() - time) > 1) print('pathfinding executed in ${(window.performance.now() - time).toStringAsFixed(2)}ms, mapped ${queue.length} tiles');
  }

  /**
   * Eine Änderung/Bewegung des Sprites an der Stelle [atPosX][atPosY] anmelden.
   * Die View kümmert sich beim nächsten Tick darum diese Änderungen zu rendern.
   */
  void reportChange(int atPosX, int atPosY) {
    this.changed.add(new Coordinates(atPosX, atPosY));
  }
  List<Coordinates> getChanged() {
    return this.changed;
  }
  void clearChanged() {
    this.changed.clear();
  }

  /**
   * Setzt im Level der aktuellen Instanz eine Entität auf das Spielfeld.
   */
  void setEntity(int posX, int posY, Entity ent) {
    levelField[posY][posX] = ent;
    reportChange(posX, posY);
    ent.positionX = posX;
    ent.positionY = posY;
  }

  /**
   * Entfernt im Level der aktuellen Instanz eine Entität vom Spielfeld.
   */
  void removeEntity(int posX, int posY) {
    reportChange(posX, posY);
    levelField[posY][posX] = null;
  }
  void setBackground(int posX, int posY, Background bck) {
    reportChange(posX, posY);
    levelFieldBackground[posY][posX] = bck;
  }

  /**
   * Prüft, ob die angegebene Koordinate außerhalb des Spielfeldes liegt.
   */
  static bool isInvalid(int atPosX, int atPosY) {
    if(atPosX < 0 || atPosX >= XFIELDSIZE || atPosY < 0 || atPosY >= YFIELDSIZE) {
      return true;
    }
    return false;
  }

  /**
   * Prüft ob an der gegeben Koordinate etwas zum kollidieren ist.
   * true: Kollision!
   */
  bool collisionAt(int atPosX, int atPosY) {
    if(isInvalid(atPosX, atPosY)) { //Wenn Ziel außerhalb des Spielfeldes
      //if(debug) {print("Pos($atPosX|$atPosY) out of bounds!");}
      return true;
    }
    if(getEntityAt(atPosX, atPosY) != null) { //Kollision mit anderen Entitäten
      //if(debug) {print("Pos($atPosX|$atPosY) collision with ${getEntityAt(atPosX, atPosY)}!");}
      //if(debug) {print("Pos($atPosX|$atPosY) collision with ${getEntityAt(atPosX, atPosY)}!");}
      return true;
    }
    return false;
  }

  /**
   * Gibt die Entität an der gegebenen Position zurück.
   * Falls dort keine existiert wird null zurückgegeben.
   */
  Entity getEntityAt(int atPosX, int atPosY) {
    if(isInvalid(atPosX, atPosY)) return null;
    return levelField[atPosY][atPosX];
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
    DynamicEntity ent = levelField[fromPosY][fromPosX];
    //if(debug) {print("moveEntityFrom:($fromPosX|$fromPosY)$direction $ent");}

    final int newPosX = getNewPosX(fromPosX, direction);
    final int newPosY = getNewPosY(fromPosY, direction);

    if(!active.collisionAt(newPosX, newPosY)) {
      this.removeEntity(fromPosX, fromPosY);
      this.setEntity(newPosX, newPosY, ent);
      return true;
    } else { //Kollision mit Entity oder OutofBounds
      this.reportChange(fromPosX, fromPosY);
      return false;
    }
  }

  /**
   * Konstruktor für ein komplett leeres Level
   */
  Level(int xSize, int ySize) {
    levelField = new List(ySize);
    levelFieldBackground = new List(ySize);
    pathToPlayer = new List(ySize);
    for(int i = 0; i < ySize; i++) {
      levelField[i] = new List(xSize);
      levelFieldBackground[i] = new List(xSize);
      pathToPlayer[i] = new List(xSize);
    }
  }

}

class LevelLoader {
  static Future<int> getLevelFromJson (String url) async {
    String s = await HttpRequest.getString(url);
    Map<String, dynamic> jsonMap = JSON.decode(s);

    for(Map<String, dynamic> x in jsonMap.values) {
      if(x != null) {
        Symbol orientation = null;
        if(x["orientation"] != "null") {
          orientation = new Symbol(x["orientation"]);
        }
        switch(x["type"]) {
            case "Player":
              new Player(x["positionX"],x["positionY"], orientation);
              break;
            case "Scenery":
              new Scenery(x["positionX"],x["positionY"], x["baseSprite"]);
              break;
            case "Background":
              new Background(x["positionX"],x["positionY"], x["baseSprite"]);
              break;
            case "BasicTank":
              new BasicTank(x["positionX"],x["positionY"], orientation);
              break;
            default:
              if(DEBUG) print("LevelLoader from Json: Invalid Type");
              break;
        }
      }
    }
    return 0;
  }
  static void printLevelAsJson(Level lvl) {
    print(JSON.encode(lvl));
  }
  static void testlevel() {
    new Player(0,0, #right);
    new Scenery(0, 5, "wall");
    new Scenery(1, 7, "wall");
    new Scenery(2, 5, "wall");
    new Scenery(2, 7, "wall");
    new Scenery(2, 8, "wall");
    new Scenery(3, 0, "wall");
    new Scenery(3, 1, "wall");
    new Scenery(3, 2, "wall");
    new Scenery(3, 4, "wall");
    new Scenery(3, 5, "wall");
    new Scenery(4, 7, "wall");
    new Scenery(4, 8, "wall");
    new Scenery(5, 8, "wall");
    new Scenery(6, 2, "wall");
    new Scenery(6, 3, "wall");
    new Scenery(6, 5, "wall");
    new Scenery(6, 8, "wall");
    new Scenery(7, 5, "wall");
    new Scenery(7, 8, "wall");
    new Scenery(8, 5, "wall");
    new Scenery(8, 8, "wall");
    new Scenery(9, 1, "wall");
    new Scenery(9, 2, "wall");
    new Scenery(9, 3, "wall");
    new Scenery(9, 4, "wall");
    new Scenery(9, 5, "wall");
    new Scenery(9, 6, "wall");
    new Scenery(9, 8, "wall");
    new Scenery(11, 0, "wall");
    new Scenery(11, 2, "wall");
    new Scenery(11, 3, "wall");
    new Scenery(11, 4, "wall");
    new Scenery(11, 5, "wall");
    new Scenery(11, 6, "wall");
    new Scenery(11, 7, "wall");
    new Scenery(11, 8, "wall");
    new Scenery(13, 5, "wall");
    new Scenery(14, 4, "wall");
    new Scenery(14, 5, "wall");

    new BasicTank(14, 2, #left);
    new BasicTank(14, 7, #left);

  }
}