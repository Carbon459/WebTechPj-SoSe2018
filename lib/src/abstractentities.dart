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
