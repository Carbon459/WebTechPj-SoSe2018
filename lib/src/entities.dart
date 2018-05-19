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
   * Gibt die korrekte Rotation in Grad für dieses [Entity] zurück.
   */
  int getSpriteRotation() {
    if(this.orientation == null) return 0;//Falls es keine orientierung gibt:
    switch(this.orientation.toString()) {
      case 'Symbol("left")': return 270; break;
      case 'Symbol("right")': return 90; break;
      case 'Symbol("up")': return 0; break;
      case 'Symbol("down")': return 180; break;
    }
    return 0; //Falls keine orientierung vorhanden ist, vorallem bei statischen Sprites verwendet:
  }

  /**
   * Entfernt eine Entität aus dem Modellfeld.
   */
  void destroy() {
    activeField.removeEntity(positionX, positionY);
    if(debug) {print("${this} destroyed");}
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
    new Projectile(this.positionX, this.positionY, this.orientation, #basic);
  }

  /**
   * Bewegt die Entität auf dem Modellfeld entsprechend der [orientation]
   * Gibt true zurück, falls bewegt wurde. Bei Kollision/outOfBounds false
   */
  bool move() {
    return activeField.moveEntityRelative(this.positionX, this.positionY, this.orientation);
  }
  /**
   * Entfernt die Entität vom Spielfeld. Entfernt Eventlistener falls vorhanden
   */
  void destroy() {
    super.destroy();
    if(ev != null) window.removeEventListener("mDE", this.ev);
  }
}

class Player extends DynamicEntity {
  Player(posX, posY) {
    positionX = posX;
    positionY = posY;
    baseSprite = "player.png";
    hp = 3;
    activeField.setEntity(posX, posY, this);
  }
  void setOrientation(Symbol or) {
    orientation = or;
  }
  /**
   * Entfernt den Spieler vom Spielfeld und die Referenz.
   */
  void destroy() {
    super.destroy();
    player = null;
  }
}

class Projectile extends DynamicEntity {
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
    this.baseSprite = "bullet.png";

    switch(orientation.toString()) {
      case 'Symbol("left")':
        if(!activeField.collisionAt(positionX - 1, positionY)) {
          this.positionX = positionX - 1;
          window.addEventListener("mDE", ev = (e) => this.move());
        }
        if(activeField.getEntityAt(positionX - 1, positionY) is DynamicEntity) {
          activeField.getEntityAt(positionX - 1, positionY).damage(dmg);
        }
        break;
      case 'Symbol("right")':
        if(!activeField.collisionAt(positionX + 1, positionY)) {
          this.positionX = positionX + 1;
          window.addEventListener("mDE", ev = (e) => this.move());
        }
        if(activeField.getEntityAt(positionX + 1, positionY) is DynamicEntity) {
          activeField.getEntityAt(positionX + 1, positionY).damage(dmg);
        }
        break;
      case 'Symbol("up")':
        if(!activeField.collisionAt(positionX, positionY - 1)) {
          this.positionY = positionY - 1;
          window.addEventListener("mDE", ev = (e) => this.move());
        }
        if(activeField.getEntityAt(positionX, positionY - 1) is DynamicEntity) {
          activeField.getEntityAt(positionX, positionY - 1).damage(dmg);
        }
        break;
      case 'Symbol("down")':
        if(!activeField.collisionAt(positionX, positionY + 1)) {
          this.positionY = positionY + 1;
          window.addEventListener("mDE", ev = (e) => this.move());
        }
        if(activeField.getEntityAt(positionX, positionY + 1) is DynamicEntity) {
          activeField.getEntityAt(positionX, positionY + 1).damage(dmg);
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
    if(!output) { //Wenn OutofBounds oder Kolission
      this.destroy(); //Projektil zerstören
      final Entity hitEntity = activeField.getEntityAt(Level.getNewPosX(this.positionX, this.orientation), Level.getNewPosY(this.positionY, this.orientation));
      if(hitEntity != null) {
        hitEntity.damage(this.dmg);
      }
    }
    return output;
  }

}

abstract class Enemy extends DynamicEntity {
  /**
   * Gibt an ob sich etwas zwischen dem Spieler und dem Gegner befindet
   */
  bool hasLineOfSight() { //TODO: richtig implementieren
    if(this.positionX == player.positionX || this.positionY == player.positionY) return true;
    return false;
  }

  /**
   * Gibt die Richtung zum spieler zurück.
   * Falls beide Entitys nicht auf einer ebene sind wird null zurückgegeben
   */
  Symbol getDirectionToPlayer() {
    if(this.positionX < player.positionX && this.positionY == player.positionY) return #right;
    if(this.positionX > player.positionX && this.positionY == player.positionY) return #left;
    if(this.positionY < player.positionY && this.positionX == player.positionX) return #down;
    if(this.positionY > player.positionY && this.positionX == player.positionX) return #up;
    return null;
  }
  /**
   * Bewegt den Gegner
   * Gibt true zurück, falls bewegt wurde. Ansonsten false
   */
  bool move() { //TODO: refactoren
    if(player == null) return false;
    int tmp = 0;
    Symbol dir;

    //vorgemappte path mit niedrigsten wert auswählen
    if(!activeField.collisionAt(this.positionX + 1, this.positionY)) {
      tmp = activeField.pathToPlayer[this.positionY][this.positionX + 1];
      this.orientation = #right;
      dir = #right;
    }
    if(!activeField.collisionAt(this.positionX - 1, this.positionY)) {
      if(activeField.pathToPlayer[this.positionY][this.positionX - 1] < tmp) {
        tmp = activeField.pathToPlayer[this.positionY][this.positionX - 1];
        this.orientation = #left;
        dir = #left;
      }
    }
    if(!activeField.collisionAt(this.positionX, this.positionY + 1)) {
      if(activeField.pathToPlayer[this.positionY + 1][this.positionX] < tmp) {
        tmp = activeField.pathToPlayer[this.positionY + 1][this.positionX];
        this.orientation = #down;
        dir = #down;
      }
    }
    if(!activeField.collisionAt(this.positionX, this.positionY - 1)) {
      if(activeField.pathToPlayer[this.positionY - 1][this.positionX] < tmp) {
        tmp = activeField.pathToPlayer[this.positionY - 1][this.positionX];
        this.orientation = #up;
        dir = #up;
      }
    }
    if(this.hasLineOfSight()) {
      if(getDirectionToPlayer() != null) this.orientation = getDirectionToPlayer();
      this.shoot(#basic);
    }
    return activeField.moveEntityRelative(this.positionX, this.positionY, dir);
  }
  void destroy() {
    super.destroy();
    enemies.remove(this);
  }
}
class BasicTank extends Enemy {
  BasicTank(int posX, int posY) {
    positionX = posX;
    positionY = posY;
    baseSprite = "enemyBasic.png";
    hp = 1;
    activeField.setEntity(posX, posY, this);
    window.addEventListener("mDE", ev = (e) => this.move());
    enemies.add(this);
  }
}

//TODO falls nicht nötig entfernen
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
