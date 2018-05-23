part of battlecity;

class BattleView {
  /// Enthält die Referenzen zu den Tabellenzellen
  List<List<Element>> tableFields = new List(yFieldSize);

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
  void update() {
    num time = window.performance.now();

    for(Coordinates cord in activeField.getChanged()) {
      //Für Entities
      final tdDiv = tableFields[cord.positionY][cord.positionX].querySelector("div");
      final modelField = activeField.levelField[cord.positionY][cord.positionX];
      if(modelField != null) {
        tdDiv.style.backgroundImage = "url('img/${modelField.getSprite()}')";
        tdDiv.style.setProperty( "transform", "rotate(${modelField.getSpriteRotation()}deg)");
      } else {
        tdDiv.style.backgroundImage = "none";
      }
      //Für Backgrounds
      final td = tableFields[cord.positionY][cord.positionX];
      final modelFieldBackground = activeField._levelFieldBackground[cord.positionY][cord.positionX];
      if(modelFieldBackground != null) {
        td.style.backgroundImage = "url('img/${modelFieldBackground.getSprite()}')";
      } else {
        td.style.backgroundImage = "url('img/grass.png')"; //Standardhintergrund
      }
    }
    activeField.clearChanged();

    if(debug && (window.performance.now() - time) > 1) print('model to view mapping executed in ${(window.performance.now() - time).toStringAsFixed(2)}ms');
  }

  /**
   * Erzeugt eine leere Tabelle und initialisiert die [tableFields] Liste.
   */
  void createEmptyField() {
    String table = "";
    for (int y = 0; y < yFieldSize; y++) {
      table += "<tr>";
      for (int x = 0; x < xFieldSize; x++) {
        final pos = "x${x}y${y}";
        table += "<td id='$pos'><div class='field'></div></td>";
      }
      table += "</tr>";
    }
    querySelector('#gameTable').innerHtml = table;

    for (int y = 0; y < yFieldSize; y++) {
      tableFields[y] = new List<Element>(xFieldSize);
      for (int x = 0; x < xFieldSize; x++) {
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
}