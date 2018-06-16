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
  ///Das momentan aktive Level
  static Level active;

  ///Eine Liste aller Gegner, die noch am Leben sind. Wird vom Pathfinding genutzt.
  static List<Enemy> activeEnemies = new List<Enemy>();
  ///Eine Liste aller Projektile, die noch "in der Luft" sind (Zu Aufräumzwecken getrackt)
  static List<Projectile> activeProjectiles = new List<Projectile>();

  ///Das Spielfeld aller Objekte mit Kollision
  List<List<Entity>> levelField;
  ///Das Spielfeld aller Hintergrund Objekte ohne Kollision
  List<List<Background>> levelFieldBackground;

  ///Enthält das Ergebnis des Pathfindings
  List<List<Coordinates>> pathToPlayer;
  ///Enthält alle Koordinaten von Entities, die beim nächsten Tick neu gerendet werden müssen.
  ///Existiert aus Optimierungsgründen
  List<Coordinates> changed = new List<Coordinates>();

  Map toJson() {
    Map<String, List<dynamic>> map = new Map();
    List<dynamic> list = new List();
    for(int y = 0; y < Config.YFIELDSIZE; y++) {
      for(int x = 0; x < Config.XFIELDSIZE; x++) {
        if(levelField[y][x] != null) {
          list.add(levelField[y][x]);
        }
        if(levelFieldBackground[y][x] != null) {
          list.add(levelFieldBackground[y][x]);
        }
      }
    }

    map.putIfAbsent("Level", () => list);
    return map;
  }

  /**
   * ManyToOne Pathfinding
   * Wie beschrieben in https://en.wikipedia.org/wiki/Pathfinding#Sample_algorithm
   * [mapFrom] ist eine Liste der Entitäten für die der Pfad gemappt werden soll (Startpunkte der Pfade)
   * [mapTo] ist das Ziel der Pfade
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

    for(int y = 0; y < Config.YFIELDSIZE; y++) {//2d Liste reinitialisieren
      for(int x = 0; x < Config.XFIELDSIZE; x++) {
        pathToPlayer[y][x] = new Coordinates.withCounter(x, y, Config.XFIELDSIZE*Config.YFIELDSIZE);
      }
    }

    for(Coordinates ph in queue) { //Ergebnisse auf 2D Liste mappen
      pathToPlayer[ph.positionY][ph.positionX] = ph;
    }

    if(Config.DEBUG && (window.performance.now() - time) > 1) print('pathfinding executed in ${(window.performance.now() - time).toStringAsFixed(2)}ms, mapped ${queue.length} tiles');
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

  /// Setzt im Level der aktuellen Instanz eine Entität in den Vordergrund auf das Spielfeld.
  void setEntity(int posX, int posY, Entity ent) {
    levelField[posY][posX] = ent;
    reportChange(posX, posY);
    ent.positionX = posX;
    ent.positionY = posY;
  }

  /// Äquivalent von [setEntity(x,y,e)] für den Hintergrund
  void setBackground(int posX, int posY, Background bck) {
    reportChange(posX, posY);
    levelFieldBackground[posY][posX] = bck;
  }

  /// Entfernt im Level der aktuellen Instanz eine Entität vom Spielfeld.
  void removeEntity(int posX, int posY) {
    levelField[posY][posX] = null;
    reportChange(posX, posY);
  }

  /// Dreht eine Entität aus dem Vordergrund an der Position [posX][posY] im Uhrzeigersinn
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

  /// Äquivalent von [rotateEntityClockWise(x,y)] für den Hintergrund
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

  /// Prüft, ob die angegebene Koordinate außerhalb des Spielfeldes liegt.
  static bool isInvalid(int atPosX, int atPosY) {
    if(atPosX < 0 || atPosX >= Config.XFIELDSIZE || atPosY < 0 || atPosY >= Config.YFIELDSIZE) {
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

  /// Äquivalent von [getEntityAt(x,y)] für den Hintergrund
  Background getBackgroundAt(int atPosX, int atPosY) {
    if(isInvalid(atPosX, atPosY)) return null;
    return levelFieldBackground[atPosY][atPosX];
  }

  /// Gibt die Koordinate in die [direction] auf der X Ebene an
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
  ///Gibt die Koordinate in die [direction] auf der Y Ebene an
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

  /// Hat die Position [fromPosX][fromPosY] eine freie Sicht zur Position [toPosX][toPosY]?
  bool hasLineOfSight(fromPosX, fromPosY, toPosX, toPosY) {
    switch(Level.getDirection(fromPosX, fromPosY, toPosX, toPosY).toString()) { //Richtung in die das ziel ist
      case 'Symbol("left")':
        for(int i = 1; i <= ((fromPosX - toPosX).abs() - 1); i++) {
          if(this.collisionAt(fromPosX - i, fromPosY)) return false;
        }
        break;
      case 'Symbol("right")':
        for(int i = 1; i <= ((fromPosX - toPosX).abs() - 1); i++) {
          if(this.collisionAt(fromPosX + i, fromPosY)) return false;
        }
        break;
      case 'Symbol("up")':
        for(int i = 1; i <= ((fromPosY - toPosY).abs() - 1); i++) {
          if(this.collisionAt(fromPosX, fromPosY - i)) return false;
        }
        break;
      case 'Symbol("down")':
        for(int i = 1; i <= ((fromPosY - toPosY).abs() - 1); i++) {
          if(this.collisionAt(fromPosX, fromPosY + i)) return false;
        }
        break;
      default: //Ziel ist nicht auf einer selben ebene wie der Ursprung
        return false;
    }

    return true; //Keine Kollision erkannt -> LoS besteht
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
  ///Lädt aus [url] ein im JSON Format gespeichertes Level
  static Future<int> getLevelFromJson (String url) async {
    String s = await HttpRequest.getString(url);
    getLevelfromString(s);
    return 0;
  }

  ///Lädt aus dem [json] String ein im JSON Format gespeichertes Level
  static void getLevelfromString(String json) {
    Map<String, dynamic> jsonMap = JSON.decode(json);

    for(dynamic x in jsonMap["Level"]) {
      if(x != null) {
        Symbol orientation = null;
        if(x["orientation"] != "null") {
          orientation = new Symbol(x["orientation"]);
        }
        createObject(x["type"], x["positionX"], x["positionY"], baseSprite: x["baseSprite"], orientation: orientation);
      }
    }
  }

  ///Instanziiert dem angegebenen [type] entsprechend ein Objekt, welches dadurch auf das Spielfeld platziert wird.
  static void createObject(String type, int posX, int posY, {String baseSprite, Symbol orientation}) {
    switch(type) {
      case "Player":
        new Player(posX,posY, orientation);
        break;
      case "Scenery":
        new Scenery(posX,posY, baseSprite, orientation);
        break;
      case "Background":
        new Background(posX,posY, baseSprite, orientation);
        break;
      case "BasicTank":
        new BasicTank(posX, posY, orientation);
        break;
      case "FastTank":
        new FastTank(posX, posY, orientation);
        break;
      case "PowerupHeal":
        new PowerupHeal(posX,posY);
        break;
      case "removeForeground":
        Level.active.removeEntity(posX, posY);
        break;
      default:
        if(Config.DEBUG) print("LevelLoader from Json: Invalid Type");
        break;
    }
  }

  ///Debugfunktion
  static void printLevelAsJson(Level lvl) {
    print(JSON.encode(lvl));
  }
}
