part of battlecity;

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
    //bool tmp = super.moveDir(direction);
    bool tmp = false;
    switch(direction.toString()) {
      case 'Symbol("up")': if(this.orientation == #up) tmp = super.moveDir(direction); else this.orientation = #up; break;
      case 'Symbol("right")': if(this.orientation == #right) tmp = super.moveDir(direction); else this.orientation = #right; break;
      case 'Symbol("down")': if(this.orientation == #down) tmp = super.moveDir(direction); else this.orientation = #down; break;
      case 'Symbol("left")': if(this.orientation == #left) tmp = super.moveDir(direction); else this.orientation = #left; break;
    }
    Level.active.reportChange(this.positionX, this.positionY);
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
