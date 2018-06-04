part of battlecity;

class BattleView {
  /// Enthält die Referenzen zu den Tabellenzellen
  List<List<Element>> tableFields = new List(YFIELDSIZE);

  void gameStateChange(Symbol gamestate) {
    switch(gamestate.toString()) {
      case 'Symbol("menu")':
        querySelector("#game").style.visibility = "hidden";
        querySelector("#menu").style.visibility = "visible";
        querySelector("#gameover").style.visibility = "hidden";
        break;
      case 'Symbol("running")':
        querySelector("#game").style.visibility = "visible";
        querySelector("#menu").style.visibility = "hidden";
        querySelector("#gameover").style.visibility = "hidden";
        break;
      case 'Symbol("gameover")':
        querySelector("#game").style.visibility = "visible";
        querySelector("#menu").style.visibility = "hidden";
        querySelector("#gameover").style.visibility = "visible";
        break;
    }

  }
  /**
   * Bringt das angezeigte Spielfeld auf den Stand des Modelles.
   */
  void update(Level modelLvl) {
    num time = window.performance.now();

    for(Coordinates cord in modelLvl.getChanged()) {
      //Für Entities
      final tdDiv = tableFields[cord.positionY][cord.positionX].querySelector("div");
      final modelField = modelLvl.levelField[cord.positionY][cord.positionX];

      //Für Backgrounds
      final td = tableFields[cord.positionY][cord.positionX];
      final modelFieldBackground = modelLvl.levelFieldBackground[cord.positionY][cord.positionX];

      final int backgroundRotation = modelFieldBackground?.getSpriteRotation() ?? 0;
      final int foregroundRotation = modelField?.getSpriteRotation() ?? 0;

      if(modelField != null) {
        tdDiv.style.backgroundImage = "url('img/${modelField.getSprite()}')";
        tdDiv.style.setProperty( "transform", "rotate(${foregroundRotation - backgroundRotation}deg)");
      } else {
        tdDiv.style.backgroundImage = "none";
      }

      if(modelFieldBackground != null) {
        td.style.backgroundImage = "url('img/${modelFieldBackground.getSprite()}')";
        td.style.setProperty( "transform", "rotate(${backgroundRotation}deg)");
      } else {
        td.style.backgroundImage = "url('img/grass.png')"; //Standardhintergrund
      }
    }
    modelLvl.clearChanged();

    if(DEBUG && (window.performance.now() - time) > 1) print('model to view mapping executed in ${(window.performance.now() - time).toStringAsFixed(2)}ms');
  }

  void updatePlayerHP(int hp) {
    String hpdiv = "";
    for(int i = 0; i < hp; i++) {
      hpdiv += "<img src='img/heart_full.png'>";
    }
    for(int i = 0; i < (MAXPLAYERHP-hp); i++) {
      hpdiv += "<img src='img/heart_empty.png'>";
    }
    querySelector("#playerhp").innerHtml = hpdiv;
  }

  /**
   * Erzeugt eine leere Tabelle und initialisiert die [tableFields] Liste.
   */
  void createEmptyField() {
    String table = "";
    for (int y = 0; y < YFIELDSIZE; y++) {
      table += "<tr>";
      for (int x = 0; x < XFIELDSIZE; x++) {
        final pos = "x${x}y${y}";
        table += "<td class='background' id='$pos'><div class='foreground'></div></td>";
      }
      table += "</tr>";
    }
    querySelector('#gameTable').innerHtml = table;

    for (int y = 0; y < YFIELDSIZE; y++) {
      tableFields[y] = new List<Element>(XFIELDSIZE);
      for (int x = 0; x < XFIELDSIZE; x++) {
        tableFields[y][x] = querySelector("#x${x}y${y}");
      }
    }
  }

  void setFieldText(int x, int y, String txt) {
    tableFields[y][x].querySelector("div").innerHtml = txt;
  }

  void setFieldColor(int x, int y, String clr) {
    tableFields[y][x].querySelector("div").style.color = clr;
  }

  void unlockMenu(int lastUnlockedLevel) {
    for(int i = 1; i <= lastUnlockedLevel; i++) {
      querySelector("#level$i").attributes.remove("disabled");
    }
  }

  void drawMenu(int levelCount) {
    String html = "Hauptmenü<br>";
    for(int i = 1; i <= levelCount; i++) {
      html += '<button id="level$i" type="button" disabled>Start Level $i</button><br>';
    }
    html += '<button id="toggleFS" type="button">Enable Fullscreen</button>';
    querySelector("#menu").innerHtml = html;
  }
}