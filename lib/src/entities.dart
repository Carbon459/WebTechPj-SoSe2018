part of battlecity;

abstract class Entity {
  Map toJson() => {"type":this.runtimeType.toString(),"positionX":positionX,"positionY":positionY,"transparent":transparent, "baseSprite":baseSprite, "orientation":MirrorSystem.getName(orientation)};
  Entity fromJson(Map json) {
    this.positionX = json["positionX"];
    this.positionY = json["positionY"];
    this.transparent = json["transparent"];
    this.baseSprite = json["baseSprite"];
    this.orientation = MirrorSystem.getSymbol(json["orientation"]);
    return this;
  }
  int positionX;
  int positionY;
  bool transparent;
  String baseSprite;
  Symbol orientation;

  /**
   * Gibt den Dateinamen des korrekt orientierten Sprites für dieses [Entity] zurück.
   */
  String getSprite() {
    if(this.orientation == null) return this.baseSprite + ".png";//Falls es keine orientierung gibt:
    switch(this.orientation.toString()) {
      case 'Symbol("left")': return this.baseSprite + "Left.png"; break;
      case 'Symbol("right")': return this.baseSprite + "Right.png"; break;
      case 'Symbol("up")': return this.baseSprite + "Up.png"; break;
      case 'Symbol("down")': return this.baseSprite + "Down.png"; break;
    }
    return this.baseSprite + ".png"; //Falls keine orientierung vorhanden ist, vorallem bei statischen Sprites verwendet:
  }

  /**
   * Entfernt eine Entität aus dem Modellfeld.
   */
  void destroy() {
    activeField.removeEntity(positionX, positionY);
  }
}

abstract class DynamicEntity extends Entity {
  ///EventListener für die nötigen Bewegungen bei jedem Tick
  EventListener ev;

  void shoot(Symbol projectile) {
    new Projectile(this, #basic);
  }

  /**
   * Bewegt die Entität auf dem Modellfeld entsprechend der [orientation]
   * Gibt true zurück, falls bewegt wurde. Bei Kollision/outOfBounds false
   */
  bool move() {
    return activeField.moveEntityRelative(this.positionX, this.positionY, this.orientation);
  }
}

class Player extends DynamicEntity {
  Player(posX, posY) {
    positionX = posX;
    positionY = posY;
    transparent = false;
    baseSprite = "player";
    activeField.setEntity(posX, posY, this);
  }
  void setOrientation(Symbol or) {
    orientation = or;
  }
}

class Projectile extends DynamicEntity {
  /// Maximale Distanz, die der Schuss zurücklegen kann, bevor er verschwindet. -1 = unlimitiert TODO: unbenutzt
  int maxRemainingDistance = -1;

  /**
   * Der Konstruktor erzeugt das Projektilelement und setzt es direkt in die Spielwelt falls möglich.
   * Wenn nicht sollte die Referenz auf das Projektil beim Aufruf nicht gespeichert werden, damit es vom GC entfernt werden kann.
   */
  Projectile(Entity shooter, Symbol type) {
    //TODO verschiedene schusstypen implementieren nach [type]
    this.positionX = shooter.positionX;
    this.positionY = shooter.positionY;
    this.orientation = shooter.orientation;
    this.transparent = false;
    this.baseSprite = "bullet";

    switch(shooter.orientation.toString()) {
      case 'Symbol("left")':
        if(!activeField.collisionAt(shooter.positionX - 1, shooter.positionY)) {
          this.positionX = shooter.positionX - 1;
          window.addEventListener("mDE", ev = (e) => this.move());
        }
        break;
      case 'Symbol("right")':
        if(!activeField.collisionAt(shooter.positionX + 1, shooter.positionY)) {
          this.positionX = shooter.positionX + 1;
          window.addEventListener("mDE", ev = (e) => this.move());
        }
        break;
      case 'Symbol("up")':
        if(!activeField.collisionAt(shooter.positionX, shooter.positionY - 1)) {
          this.positionY = shooter.positionY - 1;
          window.addEventListener("mDE", ev = (e) => this.move());
        }
        break;
      case 'Symbol("down")':
        if(!activeField.collisionAt(shooter.positionX, shooter.positionY + 1)) {
          this.positionY = shooter.positionY + 1;
          window.addEventListener("mDE", ev = (e) => this.move());
        }
        break;
    }

    //Projektil ins modellFeld setzen falls in die gewünschte Richtung überhaupt Platz ist(Kein Platz = eventListener leer).
    if(this.ev != null) {
      activeField.setEntity(this.positionX, this.positionY, this);
    }
  }

  /**
   * Bewegt die Entität auf dem Modellfeld
   * Gibt true zurück, falls bewegt wurde. Bei Kollision/outOfBounds false
   */
  bool move() {
    final bool output = activeField.moveEntityRelative(this.positionX, this.positionY, this.orientation);
    if(!output) { //Wenn OutofBounds oder Kolission -> Projektil zerstören TODO: bei kolission mit anderen entity schaden verteilen
      this.destroy();
    }
    return output;
  }

  /**
   * Entfernt das Projektil vom Spielfeld
   */
  void destroy() {
    window.removeEventListener("mDE", this.ev);
    activeField.removeEntity(positionX, positionY);
  }
}

abstract class Enemy extends DynamicEntity {
  int hp;
  /**
   * Bewegt den Gegner
   * Gibt true zurück, falls bewegt wurde. Ansonsten false
   */
  bool move() {
    //TODO: Gegner wegfindung implementieren
    return false;
  }
}
class BasicTank extends Enemy {
  BasicTank(int posX, int posY) {
    positionX = posX;
    positionY = posY;
    transparent = false;
    baseSprite = "basictank";
    hp = 1;
    activeField.setEntity(posX, posY, this);
    window.addEventListener("mDE", ev = (e) => this.move());
  }
  /**
   * Entfernt den Gegner vom Spielfeld. (vermutlich zerstört worden)
   */
  void destroy() {
    window.removeEventListener("mDE", this.ev);
    activeField.removeEntity(positionX, positionY);
  }
}

abstract class StaticEntity extends Entity {}

class Scenery extends StaticEntity {
  Scenery(int posX, int posY, sprite) {
    positionX = posX;
    positionY = posY;
    transparent = false;
    baseSprite = sprite;
    activeField.setEntity(posX, posY, this);
  }
}
class Powerup extends StaticEntity {}
