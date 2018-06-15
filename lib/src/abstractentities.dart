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
  ///Lebenspunkte (hp<0 = Unzerstörbar)
  int hp = -1;
  String baseSprite;
  Symbol orientation;
  bool collision = true;
  ///Queue für in den nächsten Ticks zu anzeigende Sprites (für Animationen)
  Queue<String> currentAnimation = new Queue<String>();

  String getOrientationAsString() {
    if(this.orientation == null) return "null";
    RegExp exp = new RegExp("(left|right|up|down)");
    return exp.firstMatch(this.orientation.toString()).group(0);
  }

  String getSprite() {
    if(currentAnimation.isNotEmpty) {
      String tmp = currentAnimation.first;
      currentAnimation.removeFirst();
      //if(DEBUG) print("Sprite: $tmp.png");
      return tmp + ".png";
    } else {
      //if(DEBUG) print("BaseSprite: $baseSprite.png");
      return baseSprite + ".png";
    }
  }

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
   * Entfernt eine Entität aus dem Modellfeld.
   */
  void destroy() {
    setAnimationSprite("explode");
    Level.active.reportChange(this.positionX, this.positionY);
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


abstract class DynamicEntity extends Entity {
  ///EventListener für die nötigen Bewegungen bei jedem Tick
  EventListener ev;

  void shoot(Symbol projectile) {
    Level.active.reportChange(positionX, positionY); //Sicherstellen das die Orientierung richtig gerendert ist
    new Projectile(this.positionX, this.positionY, this.orientation, #basic);
  }

  /**
   * Bewegt die Entität auf dem Modellfeld entsprechend der [orientation]
   * Gibt true zurück, falls bewegt wurde. Bei Kollision/outOfBounds false
   */
  bool move() {
    return Level.active.moveEntityRelative(this.positionX, this.positionY, this.orientation);
  }
  bool moveDir(Symbol direction) {
    this.orientation = direction;
    return move();
  }

  void addEventListener(String type) {
    window.addEventListener(type, this.ev = (e) => this.move());
  }
  void removeEventListener() {
    if(ev != null) {
      window.removeEventListener("fullspeed", this.ev);
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
   * Bewegt den Gegner (und schießt wenn möglich)
   * Gibt true zurück, falls bewegt wurde. Ansonsten false
   */
  bool move() {
    if(!Player.isAlive()) return false; //Spieler existiert nicht auf dem Spielfeld

    if(Level.active.hasLineOfSight(this.positionX, this.positionY, Player.active.positionX, Player.active.positionY)) { //LoS zum Spieler? -> Schiessen
      final Symbol dirToPlayer = Level.getDirection(this.positionX, this.positionY, Player.active.positionX, Player.active.positionY);
      if(dirToPlayer != null) this.orientation = dirToPlayer; //Zum Spieler drehen

      this.shoot(#basic);
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
   * Wählt aus dem im aktiven Level vorhandenen Pathmapping den kürzesten nächsten Schritt
   * und setzt die Orientierun dieses Entitys entsprechend
   */
  void pickOrientation() {
    int tmp = Config.XFIELDSIZE*Config.YFIELDSIZE; //Höchster Wert

    //vorgemappte path mit niedrigsten wert auswählen
    List<Coordinates> list = new List();
    if(!Level.active.collisionAt(this.positionX + 1, this.positionY)) list.add(Level.active.pathToPlayer[this.positionY][this.positionX + 1]); //right
    if(!Level.active.collisionAt(this.positionX - 1, this.positionY)) list.add(Level.active.pathToPlayer[this.positionY][this.positionX - 1]); //left
    if(!Level.active.collisionAt(this.positionX, this.positionY + 1)) list.add(Level.active.pathToPlayer[this.positionY + 1][this.positionX]); //down
    if(!Level.active.collisionAt(this.positionX, this.positionY - 1)) list.add(Level.active.pathToPlayer[this.positionY - 1][this.positionX]); //up

    for(Coordinates cord in list) {
      if(cord.counter == tmp) {
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

  void destroy() {
    super.destroy();
    Level.activeEnemies.remove(this);
  }
}

/**
 * Powerup "Interface"
 */
abstract class Powerup extends Entity {
  void apply(Player player);

  void destroy() { //Nicht die destroy methode von Entity benutzen da sonst eine explosions animation abgespielt wird
    Level.active.removeEntity(positionX, positionY);
    Level.active.reportChange(this.positionX, this.positionY);
  }
}