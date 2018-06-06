part of battlecity;

abstract class Entity {
  Map toJson() => {
    "type":this.runtimeType.toString(),
    "positionX":positionX,
    "positionY":positionY,
    "baseSprite":baseSprite,
    "orientation":this.getOrientation()
  };

  int positionX;
  int positionY;
  ///Lebenspunkte (hp<0 = Unzerstörbar)
  int hp = -1;
  String baseSprite;
  String sprite;
  Symbol orientation;
  bool collision = true;

  String getOrientation() {
    if(this.orientation == null) return "null";
    RegExp exp = new RegExp("(left|right|up|down)");
    return exp.firstMatch(this.orientation.toString()).group(0);
  }
  String getSprite() {
    if(DEBUG) print("getSprite: $sprite.png");
    if(sprite != baseSprite) {
      String tmp = sprite;
      sprite = baseSprite;
      return tmp + ".png";
    }
    return sprite + ".png";
  }

  void setAnimationSprite(Symbol action) {
    switch(action.toString()) {
      case 'Symbol("shoot")':
        sprite = baseSprite + "_shoot";
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
    Level.active.removeEntity(positionX, positionY);
    if(DEBUG) {print("${this} destroyed");}
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

class Player extends DynamicEntity {

  static Player active;

  static bool isAlive() {
    return Player.active != null;
  }

  Timer shootReset;
  bool shootPermission = true;

  Player(posX, posY, Symbol or) {
    this.positionX = posX;
    positionY = posY;
    baseSprite = "player";
    sprite = baseSprite;
    hp = MAXPLAYERHP;
    orientation = or;
    Level.active.setEntity(posX, posY, this);
    Player.active = this;
  }
  void setOrientation(Symbol or) {
    orientation = or;
    Level.active.reportChange(positionX, positionY);
  }
  bool moveDir(Symbol direction) {
    bool tmp = super.moveDir(direction);
    /*bool tmp = false;
    switch(direction.toString()) {
      case 'Symbol("up")': if(this.orientation == #up) tmp = super.moveDir(direction); else this.orientation = #up; break;
      case 'Symbol("right")': if(this.orientation == #right) tmp = super.moveDir(direction); else this.orientation = #right; break;
      case 'Symbol("down")': if(this.orientation == #down) tmp = super.moveDir(direction); else this.orientation = #down; break;
      case 'Symbol("left")': if(this.orientation == #left) tmp = super.moveDir(direction); else this.orientation = #left; break;
    }
    Level.active.reportChange(this.positionX, this.positionY);*/
    Level.active.mapPathToEntity(Level.activeEnemies, Player.active);
    return tmp;
  }
  /**
   * Entfernt den Spieler vom Spielfeld und die Referenz.
   */
  void destroy() {
    super.destroy();
    Player.active = null;
  }
  
  void shoot(Symbol projectile) {
    if(shootPermission) {
      new Projectile(this.positionX, this.positionY, this.orientation, #basic);
      shootPermission = false;
      shootReset = new Timer.periodic(SHOOTSPEED, (_) {shootReset.cancel(); shootPermission = true;});
    }
  }
}

class Projectile extends DynamicEntity {
  ///Schaden den das Projektil anrichtet
  int dmg = 1;


  /**
   * Der Konstruktor erzeugt das Projektilelement und setzt es direkt in die Spielwelt falls möglich.
   * @positionX, positionY X und Y Koordinate vom Schützen
   * @orientation Blickrichtung vom Schützen
   * @type Art des Schusses
   */
  Projectile(int positionX, int positionY, Symbol orientation, Symbol type) {
    //TODO verschiedene schusstypen implementieren nach [type]
    this.positionX = positionX;
    this.positionY = positionY;
    this.orientation = orientation;
    this.baseSprite = "bullet";
    setAnimationSprite(#shoot);
    this.hp = 1;

    final int startPosX = Level.getNewPosX(positionX, orientation);
    final int startPosY = Level.getNewPosY(positionY, orientation);

    if(!Level.active.collisionAt(startPosX, startPosY)) {
      this.positionX = startPosX;
      this.positionY = startPosY;
      this.addEventListener("fullspeed");
    }
    if(Level.active.getEntityAt(startPosX, startPosY) is DynamicEntity) { //falls jemand direkt am angrenzenden Feld war -> Schaden verteilen (Projektil wurde oben nicht erzeugt)
      Level.active.getEntityAt(startPosX, startPosY).damage(dmg);
    }

    //Projektil ins modellFeld setzen falls in die gewünschte Richtung überhaupt Platz ist(Kein Platz = eventListener leer).
    if(this.ev != null) {
      Level.active.setEntity(this.positionX, this.positionY, this);
      Level.activeProjectiles.add(this);
    }
  }

  /**
   * Bewegt die Entität auf dem Modellfeld
   * Gibt true zurück, falls bewegt wurde. Bei Kollision/outOfBounds false
   */
  bool move() {
    final bool output = Level.active.moveEntityRelative(this.positionX, this.positionY, this.orientation);
    if(!output) { //Wenn OutofBounds oder Kolission
      this.destroy(); //Projektil zerstören
      final Entity hitEntity = Level.active.getEntityAt(Level.getNewPosX(this.positionX, this.orientation), Level.getNewPosY(this.positionY, this.orientation));
      if(hitEntity != null) {
        hitEntity.damage(this.dmg);
      }
    }
    return output;
  }
  void destroy() {
    super.destroy();
    Level.activeProjectiles.remove(this);
  }

}

abstract class Enemy extends DynamicEntity {
  /**
   * Gibt an ob sich etwas zwischen dem Spieler und diesem Entity befindet
   */
  bool hasLineOfSight() {
    switch(Level.getDirection(this.positionX, this.positionY, Player.active.positionX, Player.active.positionY).toString()) { //Richtung in die der Spieler ist
      case 'Symbol("left")':
        for(int i = 1; i <= ((this.positionX - Player.active.positionX).abs() - 1); i++) {
          if(Level.active.collisionAt(this.positionX - i, this.positionY)) return false;
        }
        break;
      case 'Symbol("right")':
        for(int i = 1; i <= ((this.positionX - Player.active.positionX).abs() - 1); i++) {
          if(Level.active.collisionAt(this.positionX + i, this.positionY)) return false;
        }
        break;
      case 'Symbol("up")':
        for(int i = 1; i <= ((this.positionY - Player.active.positionY).abs() - 1); i++) {
          if(Level.active.collisionAt(this.positionX, this.positionY - i)) return false;
        }
        break;
      case 'Symbol("down")':
        for(int i = 1; i <= ((this.positionY - Player.active.positionY).abs() - 1); i++) {
          if(Level.active.collisionAt(this.positionX, this.positionY + i)) return false;
        }
        break;
      default: //Spieler ist nicht auf einer selben ebene wie dieses Entity
        return false;
    }

    return true; //Keine Kollision erkannt -> LoS besteht
  }

  /**
   * Bewegt den Gegner (und schießt wenn möglich)
   * Gibt true zurück, falls bewegt wurde. Ansonsten false
   */
  bool move() {
    if(!Player.isAlive()) return false; //Spieler existiert nicht auf dem Spielfeld

    if(this.hasLineOfSight()) {
      final Symbol dirToPlayer = Level.getDirection(this.positionX, this.positionY, Player.active.positionX, Player.active.positionY);
      if(dirToPlayer != null) this.orientation = dirToPlayer;

      this.shoot(#basic);
      return false; //falls geschossen wurde wird keine bewegung durchgeführt
    }

    pickOrientation();
    return super.move();
  }

  /**
   * Wählt aus dem im aktiven Level vorhandenen Pathmapping den kürzesten nächsten Schritt
   * und setzt die Orientierun dieses Entitys entsprechend
   */
  void pickOrientation() {
    int tmp = XFIELDSIZE*YFIELDSIZE; //Höchster Wert

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

class BasicTank extends Enemy {
  BasicTank(int posX, int posY, Symbol or) {
    positionX = posX;
    positionY = posY;
    baseSprite = "enemyBasic";
    sprite = baseSprite;
    hp = 1;
    orientation = or;
    Level.active.setEntity(posX, posY, this);
    this.addEventListener("slowspeed");
    Level.activeEnemies.add(this);
  }
}

class Scenery extends Entity {
  Scenery(int posX, int posY, String sprite, Symbol or) {
    positionX = posX;
    positionY = posY;
    baseSprite = sprite;
    this.sprite = baseSprite;
    this.orientation = or;
    collision = true;
    Level.active.setEntity(posX, posY, this);
  }
}

class Background extends Entity {
  Background(int posX, int posY, String sprite, Symbol or) {
    positionX = posX;
    positionY = posY;
    baseSprite = sprite;
    this.sprite = baseSprite;
    this.orientation = or;
    collision = false;
    Level.active.setBackground(posX, posY, this);
  }
}

class Powerup extends Entity {}
