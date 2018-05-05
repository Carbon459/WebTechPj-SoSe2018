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
  Map toJson() => {"positionX":positionX,"positionY":positionY,"transparent":transparent, "baseSprite":baseSprite, "orientation":orientation };
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
  EventListener ev;
  void shoot(Symbol projectile) {
    if(projectile == #basic ) {
      new Projectile(this, #basic);
    }
  }

  /**
   * Bewegt die Entität auf dem Modellfeld
   * Gibt true zurück, falls bewegt wurde. Bei Kollision/outOfBounds false
   */
  bool move() {
    return activeField.moveEntityRelative(this.positionX, this.positionY, this.orientation);
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
  void setOrientation(Symbol or) {
    orientation = or;
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
    this.orientation = shooter.orientation;
    this.transparent = false;
    this.baseSprite = "bullet";

    switch(shooter.orientation.toString()) {
      case 'Symbol("left")':
        if(!activeField.collisionAt(shooter.positionX - 1, shooter.positionY)) { //Schießen nach links nicht möglich, wenn Schütze am linken Rand ist.
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
      window.removeEventListener("mDE", this.ev);
    }
    return output;
  }
}
abstract class Enemy extends DynamicEntity {}

/**
 * Beschreibt ein statisches nicht bewegbares Objekt auf dem Spielfeld.
 */
abstract class StaticEntity extends Entity {}
class Scenery extends StaticEntity {}
class Powerup extends StaticEntity {}
