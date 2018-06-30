part of battlecity;

abstract class Entity {
  Map toJson() => {
    "type":this.runtimeType.toString(),
    "positionX":positionX,
    "positionY":positionY,
    "baseSprite":baseSprite,
    "orientation":this.getOrientationAsString()
  };

  int positionX;
  int positionY;
  /// Lebenspunkte (hp<0 = Unzerstörbar)
  int hp = -1;
  /// Das Hauptsprite der Entität
  String baseSprite;
  /// Richtung in die die Entität zeigt
  Symbol orientation;

  /// Queue für in den nächsten Ticks zu anzeigende Sprites (für Animationen)
  Queue<String> currentAnimation = new Queue<String>();

  String getOrientationAsString() {
    if(this.orientation == null) return "null";
    RegExp exp = new RegExp("(left|right|up|down)");
    return exp.firstMatch(this.orientation.toString()).group(0);
  }

  /// Bestimmt ob das Basissprite oder eine Variation (für Animationen) benutzt wird
  String getSprite() {
    if(currentAnimation.isNotEmpty) {
      return currentAnimation.removeFirst() + ".png";
    } else {
      return baseSprite + ".png";
    }
  }

  /// Reiht eine Animation in die Warteschlange ein, die von [getSprite()] abgearbeitet wird
  void setAnimationSprite(String action) {
    currentAnimation.clear(); //Vorhandene Animation abbrechen.
    switch(action) {
      case 'shoot':
        currentAnimation.add(baseSprite + "_shoot");
        break;
      case 'explode':
        currentAnimation.add("explosion");
        break;
    }
    Level.active.reportChange(this.positionX, this.positionY);
  }

  /**
   * Gibt die korrekte Rotation in Grad für dieses [Entity] zurück.
   */
  int getSpriteRotation() {
    if(orientation == null) return 0;//Falls es keine orientierung gibt:
    switch(orientation.toString()) {
      case 'Symbol("up")': return 0;
      case 'Symbol("right")': return 90;
      case 'Symbol("down")': return 180;
      case 'Symbol("left")': return 270;
    }
    return 0; //Bei ungültigem Symbol keine Rotation
  }

  /**
   * Entfernt eine Entität aus dem Modellfeld. Spielt eine Explosionsanimation ab
   */
  void destroy() {
    setAnimationSprite("explode");
    new Timer(Config.EXPLOSIONDUR, () => Level.active.removeEntity(positionX, positionY));
    if(Config.DEBUG) {print("${this} destroyed");}
  }


  /**
   * Schadensberechnung
   */
  void damage(int dmg) {
    if(this.hp < 0) return; //Unzerstörbar: nichts machen
    else if(hp - dmg <= 0) { this.destroy(); return;}
    else { hp -= dmg; return;}
  }

}

/**
 * Eine Entität, die sich auf dem Spielfeld bewegt
 */
abstract class DynamicEntity extends Entity {
  ///EventListener für die nötigen Bewegungen bei jedem Tick
  EventListener ev;

  /// Gibt einen Schuss in Richtung [orientation] ab
  void shoot() {
    Level.active.reportChange(positionX, positionY); //Sicherstellen das die Orientierung richtig gerendert ist
    new Projectile(this.positionX, this.positionY, this.orientation);
  }

  /**
   * Bewegt die Entität auf dem Modellfeld entsprechend der [orientation]
   * Gibt true zurück, falls bewegt wurde. Bei Kollision oder outOfBounds false
   */
  bool move() {
    return Level.active.moveEntityRelative(this.positionX, this.positionY, this.orientation);
  }

  /// Bewegt die Entität entsprechend [direction]
  bool moveDir(Symbol direction) {
    this.orientation = direction;
    return move();
  }

  /// Eventlistener für Aktionen bei jedem Tick
  void addEventListener(String type) {
    window.addEventListener(type, this.ev = (e) => this.move());
  }
  void removeEventListener() {
    if(ev != null) {
      window.removeEventListener("fullspeed", this.ev);
      window.removeEventListener("middlespeed", this.ev);
      window.removeEventListener("slowspeed", this.ev);
    }
  }

  /**
   * Entfernt die Entität vom Spielfeld. Entfernt Eventlistener falls vorhanden
   */
  void destroy() {
    super.destroy();
    this.removeEventListener();
  }
}


abstract class Enemy extends DynamicEntity {
  /**
   * Beschreibt das Verhalten der Gegner
   * Gibt true zurück, falls bewegt wurde. Ansonsten false
   */
  bool move() {
    if(!Player.isAlive()) return false; //Spieler existiert nicht auf dem Spielfeld

    if(Level.active.hasLineOfSight(this.positionX, this.positionY, Player.active.positionX, Player.active.positionY)) { //LoS zum Spieler? -> Schiessen
      this.orientation = Level.getDirection(this.positionX, this.positionY, Player.active.positionX, Player.active.positionY); //Zum Spieler drehen
      this.shoot();
      return false; //falls geschossen wurde wird keine bewegung durchgeführt
    }

    //Falls einer der umgebenen vier Felder LoS hat auf Spieler bewegt sich der Gegner dort hin
    if(Level.active.hasLineOfSight(this.positionX + 1, this.positionY, Player.active.positionX, Player.active.positionY) && !Level.active.collisionAt(this.positionX + 1, this.positionY)) {
      this.orientation = #right;
      return super.move();
    }
    if(Level.active.hasLineOfSight(this.positionX - 1, this.positionY, Player.active.positionX, Player.active.positionY) && !Level.active.collisionAt(this.positionX - 1, this.positionY)) {
      this.orientation = #left;
      return super.move();
    }
    if(Level.active.hasLineOfSight(this.positionX, this.positionY + 1, Player.active.positionX, Player.active.positionY) && !Level.active.collisionAt(this.positionX, this.positionY + 1)) {
      this.orientation = #down;
      return super.move();
    }
    if(Level.active.hasLineOfSight(this.positionX, this.positionY - 1, Player.active.positionX, Player.active.positionY) && !Level.active.collisionAt(this.positionX, this.positionY - 1)) {
      this.orientation = #up;
      return super.move();
    }

    //Normale Wegfindung
    pickOrientation();
    return super.move();
  }

  /**
   * Wählt aus dem im aktiven Level vorhandenen Pathmapping [Level.active.pathToPlayer] den kürzesten nächsten Schritt
   * und dreht den Gegner in die daraus berechnete Richtung
   */
  void pickOrientation() {
    int tmp = Config.XFIELDSIZE*Config.YFIELDSIZE; //Höchster Wert

    //Die vier möglichen Bewegungsrichtungen
    List<Coordinates> list = new List();
    if(!Level.active.collisionAt(this.positionX + 1, this.positionY)) list.add(Level.active.pathToPlayer[this.positionY][this.positionX + 1]); //right
    if(!Level.active.collisionAt(this.positionX - 1, this.positionY)) list.add(Level.active.pathToPlayer[this.positionY][this.positionX - 1]); //left
    if(!Level.active.collisionAt(this.positionX, this.positionY + 1)) list.add(Level.active.pathToPlayer[this.positionY + 1][this.positionX]); //down
    if(!Level.active.collisionAt(this.positionX, this.positionY - 1)) list.add(Level.active.pathToPlayer[this.positionY - 1][this.positionX]); //up

    for(Coordinates cord in list) { //Wähle die Richtung, mit dem niedrigsten Counter Wert
      if(cord.counter == tmp) { //Falls die Richtung den selben Counter wert hat wie das aktuelle Feld -> Zufällige Richtung
        var rng = new Random();
        if(rng.nextBool()) {
          tmp = cord.counter;
          this.orientation = Level.getDirection(this.positionX, this.positionY, cord.positionX, cord.positionY);
        }
      } else if(cord.counter < tmp) {
        tmp = cord.counter;
        this.orientation = Level.getDirection(this.positionX, this.positionY, cord.positionX, cord.positionY);
      }
    }
  }

  /// Entfernt den Gegner außerdem noch aus der Liste vom Level.
  void destroy() {
    super.destroy();
    Level.active.activeEnemies.remove(this);
  }
}

/**
 * Basis für alle Powerup Klassen
 */
abstract class Powerup extends Entity {
  void apply(Player player);

  void destroy() { //Nicht die destroy methode von Entity benutzen da sonst eine explosions animation abgespielt wird
    Level.active.removeEntity(positionX, positionY);
    Level.active.reportChange(this.positionX, this.positionY);
  }
}