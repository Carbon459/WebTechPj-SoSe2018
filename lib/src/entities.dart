part of battlecity;
/**
 * Ein Objekt auf dem Spielfeld
 */
abstract class Entity {
  int positionX;
  int positionY;
  bool transparent;
  String baseSprite;
  Symbol orientation;

  /**
   * Gibt den Dateinamen des korrekt orientierten Sprites für dieses [Entity] zurück.
   */
  String getSprite() {
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
/**
 * Beschreibt ein dynamisches bewegbares Objekt auf dem Spielfeld.
 */
abstract class DynamicEntity extends Entity {
  void moveLeft() {
    activeField.moveEntityRelative(positionX, positionY, #left);
    this.orientation = #left;
  }
  void moveRight() {
    activeField.moveEntityRelative(positionX, positionY, #right);
    this.orientation = #right;
  }
  void moveUp() {
    activeField.moveEntityRelative(positionX, positionY, #up);
    this.orientation = #up;
  }
  void moveDown() {
    activeField.moveEntityRelative(positionX, positionY, #down);
    this.orientation = #down;
  }
  void shoot(Symbol projectile) {
    if(projectile == #basic ) {
      new Projectile(this, #basic);
    }
  }

  /**
   * Bewegt die Entität auf dem Modellfeld
   */
  bool move();

  /**
   * Entfernt zusätzlich noch die Entität aus der Liste der selbst bewegenden dynamischen Entitäten.
   */
  void destroy() {
    super.destroy();
    selfmoving.remove(this);
  }
}
/**
 * Beschreibt ein statisches nicht bewegbares Objekt auf dem Spielfeld.
 */
abstract class StaticEntity extends Entity {
  bool destroyable;
  void destroy() {
    if(destroyable) {
      //TODO
    }
  }
}
/**
 * Die Spielerklasse
 */
class Player extends DynamicEntity {
  Player(posX, posY) {
    positionX = posX;
    positionY = posY;
    transparent = false;
    baseSprite = "player";
    activeField.setEntity(posX, posY, this);
  }
  bool move() {
    //TODO:?
    return false;
  }
}
/**
 * Klasse für alle Arten von Projektilen
 */
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

    switch(shooter.orientation.toString()) {
      case 'Symbol("left")':
        if(debug) {print("Left:${activeField.collisionAt(shooter.positionX - 1, shooter.positionY).toString()}");}
        if(!activeField.collisionAt(shooter.positionX - 1, shooter.positionY)) { //Schießen nach links nicht möglich, wenn Schütze am linken Rand ist.
          this.positionX = shooter.positionX - 1;
          this.orientation = #left;
          selfmoving.add(this);
        }
        break;
      case 'Symbol("right")':
        if(!activeField.collisionAt(shooter.positionX + 1, shooter.positionY)) {
          this.positionX = shooter.positionX + 1;
          this.orientation = #right;
          selfmoving.add(this);
        }
        break;
      case 'Symbol("up")':
        if(!activeField.collisionAt(shooter.positionX, shooter.positionY - 1)) {
          this.positionY = shooter.positionY - 1;
          this.orientation = #up;
          selfmoving.add(this);
        }
        break;
      case 'Symbol("down")':
        if(!activeField.collisionAt(shooter.positionX, shooter.positionY + 1)) {
          this.positionY = shooter.positionY + 1;
          this.orientation = #down;
          selfmoving.add(this);
        }
        break;
    }
    transparent = false;
    baseSprite = "bullet";
    //Projektil ins modellFeld setzen falls in die gewünschte Richtung überhaupt Platz ist(Kein Platz = richtung wurde oben nicht gesetzt).
    if(this.orientation != null) {
      activeField.setEntity(this.positionX, this.positionY, this);
    }
  }
  bool move() {
    return activeField.moveEntityRelative(this.positionX, this.positionY, this.orientation);
  }
}
abstract class Enemy extends DynamicEntity {}
class Scenery extends StaticEntity {}
class Powerup extends StaticEntity {}
