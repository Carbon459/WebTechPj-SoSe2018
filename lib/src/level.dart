part of battlecity;

/**
 * Hilfsklasse
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
  static List<Projectile> activeProjectiles = new List<Projectile>();

  List<List<Entity>> levelField;
  List<List<Background>> levelFieldBackground;
  ///Enthält das Ergebnis des Pathfindings
  List<List<Coordinates>> pathToPlayer;
  ///Enthält alle Koordinaten von Entities, die beim nächsten Tick neu gerendet werden müssen
  List<Coordinates> changed = new List<Coordinates>();

  Map toJson() {
    Map<String, dynamic> map = new Map();
    for(int y = 0; y < YFIELDSIZE; y++) {
      for(int x = 0; x < XFIELDSIZE; x++) {
        if(levelField[y][x] != null) {
          map.putIfAbsent("($x|$y)f", () => levelField[y][x]);
        }
        if(levelFieldBackground[y][x] != null) {
          map.putIfAbsent("($x|$y)b", () => levelFieldBackground[y][x]);
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
          if(entitiesToMapLeft.any((f) { return active.getEntityAt(temp[i].positionX, temp[i].positionY) == f;})) break; //Falls alle Entities gemappt sind -> fertig
          if(collisionAt(temp[i].positionX, temp[i].positionY) //Entfernt position aus liste wenn kollision vorhanden
              || queue.any((ph) { return temp[i].positionX == ph.positionX && temp[i].positionY == ph.positionY && ph.counter <= temp[i].counter;})) { //oder schon gemappt wurde mit niedrigeren counter
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
        pathToPlayer[y][x] = new Coordinates.withCounter(x, y, XFIELDSIZE*YFIELDSIZE);
      }
    }

    for(Coordinates ph in queue) { //Ergebnisse auf 2D Liste mappen
      pathToPlayer[ph.positionY][ph.positionX] = ph;
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
  void rotateEntityClockWise(int posX, int posY) {
    if(getEntityAt(posX, posY) == null) return;
    switch(getEntityAt(posX, posY).orientation.toString()) {
      case 'Symbol("up")': getEntityAt(posX, posY).orientation = #right; break;
      case 'Symbol("right")': getEntityAt(posX, posY).orientation = #down; break;
      case 'Symbol("down")': getEntityAt(posX, posY).orientation = #left; break;
      case 'Symbol("left")': getEntityAt(posX, posY).orientation = #up; break;
    }
    reportChange(posX, posY);
  }
  void rotateBackgroundClockWise(int posX, int posY) {
    if(getBackgroundAt(posX, posY) == null) return;
    switch(getBackgroundAt(posX, posY).orientation.toString()) {
      case 'Symbol("up")': getBackgroundAt(posX, posY).orientation = #right; break;
      case 'Symbol("right")': getBackgroundAt(posX, posY).orientation = #down; break;
      case 'Symbol("down")': getBackgroundAt(posX, posY).orientation = #left; break;
      case 'Symbol("left")': getBackgroundAt(posX, posY).orientation = #up; break;
    }
    reportChange(posX, posY);
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
  Background getBackgroundAt(int atPosX, int atPosY) {
    if(isInvalid(atPosX, atPosY)) return null;
    return levelFieldBackground[atPosY][atPosX];
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

  static Symbol getDirection(int fromPosX, int fromPosY, int toPosX, int toPosY) {
    if(fromPosX < toPosX && fromPosY == toPosY) return #right;
    if(fromPosX > toPosX && fromPosY == toPosY) return #left;
    if(fromPosY < toPosY && fromPosX == toPosX) return #down;
    if(fromPosY > toPosY && fromPosX == toPosX) return #up;
    return null;
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
              new Scenery(x["positionX"],x["positionY"], x["baseSprite"], orientation);
              break;
            case "Background":
              new Background(x["positionX"],x["positionY"], x["baseSprite"], orientation);
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
    new Player(1,7, #right);
    new Background(14,4,"road_basic",#right);
    new Background(13,4,"road_basic",#right);
    new Background(12,4,"road_basic",#right);
    new Background(11,4,"road_T",#up);
    new Background(11,3,"road_basic",#up);
    new Background(11,2,"road_basic",#up);
    new Background(11,1,"road_L",#right);
    new Background(12,1,"road_basic",#right);
    new Background(13,1,"road_basic",#right);
    new Background(14,1,"road_basic",#right);
    new Background(10,4,"road_basic",#right);
    new Background(9,4,"road_basic",#right);
    new Background(8,4,"road_basic",#right);
    new Background(7,4,"road_intersection",#up);
    new Background(6,4,"road_basic",#right);
    new Background(5,4,"road_basic",#right);
    new Background(4,4,"road_basic",#right);
    new Background(3,4,"road_intersection",#down);
    new Background(3,3,"road_basic",#down);
    new Background(3,2,"road_basic",#down);
    new Background(3,1,"road_basic",#down);
    new Background(3,0,"road_basic",#down);
    new Background(3,5,"road_basic",#down);
    new Background(3,6,"road_basic",#down);
    new Background(3,7,"road_L",#left);
    new Background(2,7,"road_basic",#left);
    new Background(1,7,"road_end",#right);
    new Background(2,4,"road_basic",#right);
    new Scenery(2,6,"house", #down);
    new Scenery(6,3,"house", #down);
    new Scenery(5,3,"house", #down);
    new Scenery(4,3,"house", #down);
    new Scenery(8,3,"house", #down);
    new Scenery(9,3,"house", #down);
    new Scenery(10,3,"house", #down);
    new Scenery(2,5,"house", #up);
    new Scenery(6,5,"house", #up);
    new Scenery(5,5,"house", #up);
    new Scenery(4,5,"house", #up);
    new Scenery(4,6,"house", #left);
    new Scenery(8,5,"house", #up);
    new Scenery(9,5,"house", #up);
    new Scenery(10,5,"house", #up);
    new Scenery(4,7,"house", #left);
    new Scenery(4,7,"house", #left);
    new Background(1,4,"road_basic",#right);
    new Background(0,4,"road_basic",#right);
    new Background(7,3,"road_basic",#up);
    new Background(7,2,"road_basic",#up);
    new Background(7,1,"road_basic",#up);
    new Background(7,0,"road_basic",#up);
    new Background(7,5,"road_basic",#up);
    new Background(7,6,"road_basic",#up);
    new Background(7,7,"road_T",#right);
    new Background(8,7,"road_basic",#right);
    new Background(9,7,"road_basic",#right);
    new Background(10,7,"road_basic",#right);
    new Background(11,7,"road_end",#left);
    new Background(7,8,"road_basic",#up);
    new Background(7,9,"road_basic",#up);


    new BasicTank(14, 4, #left);

    printLevelAsJson(Level.active);
  }
}