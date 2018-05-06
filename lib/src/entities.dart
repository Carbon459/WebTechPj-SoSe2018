part of battlecity;

abstract class Entity {
  Map toJson() => {"type":this.runtimeType.toString(),"positionX":positionX,"positionY":positionY, "baseSprite":baseSprite};
  Entity fromJson(Map json) {
    //this.orientation = MirrorSystem.getSymbol(json["orientation"]);
    switch(json["type"]) {
      case "Player":
        return new Player(json["positionX"],json["positionY"]);
        break;
      case "Scenery":
        return new Scenery(json["positionX"],json["positionY"], json["baseSprite"]);
        break;
      default:
        return null;
    }
  }
  int positionX;
  int positionY;
  ///Lebenspunkte (hp<0 = Unzerstörbar)
  int hp = -1;
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
    baseSprite = "player";
    hp = 5;
    activeField.setEntity(posX, posY, this);
  }
  void setOrientation(Symbol or) {
    orientation = or;
  }
}

class Projectile extends DynamicEntity {
  int dmg = 1;

  /**
   * Der Konstruktor erzeugt das Projektilelement und setzt es direkt in die Spielwelt falls möglich.
   * Wenn nicht sollte die Referenz auf das Projektil beim Aufruf nicht gespeichert werden, damit es vom GC entfernt werden kann.
   */
  Projectile(Entity shooter, Symbol type) {
    //TODO verschiedene schusstypen implementieren nach [type]
    this.positionX = shooter.positionX;
    this.positionY = shooter.positionY;
    this.orientation = shooter.orientation;
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
    if(!output) { //Wenn OutofBounds oder Kolission TODO: bei kolission mit anderen entity schaden verteilen
      this.destroy(); //Projektil zerstören
      final Entity hitEntity = activeField.getEntityAt(Level.getNewPosX(this.positionX, this.orientation), Level.getNewPosY(this.positionY, this.orientation));
      if(hitEntity != null) {
        hitEntity.damage(this.dmg);
      }
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
    baseSprite = sprite;
    activeField.setEntity(posX, posY, this);
  }
}
class Powerup extends StaticEntity {}
