part of battlecity;

class BattleView {
  /// Enthält die Referenzen zu den Tabellenzellen
  List<List<Element>> tableFields = new List(Config.YFIELDSIZE);

  /// Kümmert sich darum, das immer die richtigen divs entsprechend dem [gamestate] sichtbar sind
  void gameStateChange(Symbol gamestate) {
    switch(gamestate.toString()) {
      case 'Symbol("menu")':
        querySelector("#game").style.visibility = "hidden";
        querySelector("#menu").style.visibility = "visible";
        querySelector("#gameover").style.visibility = "hidden";
        querySelector("#gamewon").style.visibility = "hidden";
        querySelector("#levelBuilderControls").style.visibility = "hidden";
        break;
      case 'Symbol("running")':
        querySelector("#game").style.visibility = "visible";
        querySelector("#menu").style.visibility = "hidden";
        querySelector("#gameover").style.visibility = "hidden";
        querySelector("#gamewon").style.visibility = "hidden";
        querySelector("#levelBuilderControls").style.visibility = "hidden";
        break;
      case 'Symbol("gameover")':
        querySelector("#game").style.visibility = "visible";
        querySelector("#menu").style.visibility = "hidden";
        querySelector("#gameover").style.visibility = "visible";
        querySelector("#gamewon").style.visibility = "hidden";
        querySelector("#levelBuilderControls").style.visibility = "hidden";
        break;
      case 'Symbol("gamewon")':
        querySelector("#game").style.visibility = "visible";
        querySelector("#menu").style.visibility = "hidden";
        querySelector("#gameover").style.visibility = "hidden";
        querySelector("#gamewon").style.visibility = "visible";
        querySelector("#levelBuilderControls").style.visibility = "hidden";
        break;
      case 'Symbol("levelbuilder")':
        querySelector("#game").style.visibility = "visible";
        querySelector("#menu").style.visibility = "hidden";
        querySelector("#gameover").style.visibility = "hidden";
        querySelector("#gamewon").style.visibility = "hidden";
        querySelector("#levelBuilderControls").style.visibility = "visible";
        break;
    }

  }

  /// Bringt das angezeigte Spielfeld auf den Stand des Modelles [modelLvl].
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

    if(Config.DEBUG && (window.performance.now() - time) > 1) print('model to view mapping executed in ${(window.performance.now() - time).toStringAsFixed(2)}ms');
  }

  /// Aktualisiert die Lebenspunkteanzeige
  void updatePlayerHP(int hp) {
    String hpdiv = "";
    for(int i = 0; i < hp; i++) {
      hpdiv += "<img src='img/heart_full.png'>";
    }
    for(int i = 0; i < (Config.MAXPLAYERHP-hp); i++) {
      hpdiv += "<img src='img/heart_empty.png'>";
    }
    querySelector("#playerhp").innerHtml = hpdiv;
  }

  /// Erzeugt eine leere Tabelle und initialisiert die [tableFields] Liste.
  void createEmptyField() {
    String table = "";
    for (int y = 0; y < Config.YFIELDSIZE; y++) {
      table += "<tr>";
      for (int x = 0; x < Config.XFIELDSIZE; x++) {
        final pos = "x${x}y${y}";
        table += "<td class='background' id='$pos'><div class='foreground'></div></td>";
      }
      table += "</tr>";
    }
    querySelector('#gameTable').innerHtml = table;

    for (int y = 0; y < Config.YFIELDSIZE; y++) {
      tableFields[y] = new List<Element>(Config.XFIELDSIZE);
      for (int x = 0; x < Config.XFIELDSIZE; x++) {
        tableFields[y][x] = querySelector("#x${x}y${y}");
      }
    }
  }

  /// Zeigt den Text [txt] an der Koordinate [x][y] an
  void setFieldText(int x, int y, String txt) {
    tableFields[y][x].querySelector("div").innerHtml = txt;
  }

  /// Färbt die Koordinate [x][y] in der Farbe [clr] ein.
  void setFieldColor(int x, int y, String clr) {
    tableFields[y][x].querySelector("div").style.color = clr;
  }

  ///Passt das Stylesheet an die aktuelle Spielfeldgröße an
  void setGameSize(int xSize) {
    querySelectorAll("td").style.setProperty("width", "calc(100%/${xSize})");
    querySelector("#game").style.setProperty("max-width", "${xSize}0vh");
  }

  /// Entsperrt alle Buttons bis Level [lastUnlockedLevel]
  void unlockMenu(int lastUnlockedLevel) {
    for(int i = 1; i <= lastUnlockedLevel; i++) {
      querySelector("#level$i").attributes.remove("disabled");
    }
  }

  /// Zeigt das Menü an. Es werden [levelCount] Buttons für die Auswahl der Level erstellt.
  void drawMenu(int levelCount) {
    String html = "Hauptmenü<br>";
    for(int i = 1; i <= levelCount; i++) {
      html += '<button id="level$i" type="button" disabled>Level $i</button>';
    }
    if (!TouchEvent.supported) html += '<button id="levelbuilder" type="button">Level Builder</button><br>';
    html+= '<div id="orientationWarning">Playing in Landscape mode is strongly advised!</div>';
    querySelector("#menu").innerHtml = html;
  }

  ///Zeigt oder versteckt die Orientierungswarnung
  void showOrientationWarning(bool show) {
    querySelector("#orientationWarning").style.visibility = show ? "visible" : "hidden";
  }

  /// Erstellt und zeigt das Hauptbedienungselement des LevelBuilders
  void drawBuildingBlocks() {
    String html = '<button id="printLevel" type="button">Print Level JSON</button> ';
    html += '<button id="rotateSwitch" type="button">Rotate Background</button><br>';
    int i = 0;
    for(String x in Config.LEVELBUILDINGBLOCKS.keys) {
      if(i % 10 == 0) html+="<br>";
      html += "<img id='$x' src='img/$x.png'>";
      i++;
    }
    querySelector("#levelBuilderControls").innerHtml = html;
  }
}