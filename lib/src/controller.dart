part of battlecity;

class BattleGameController {
  final view = new BattleView();

  Timer tick;
  int tickCounter = 0;
  Symbol _gamestate = #menu;

  bool get menu => _gamestate == #menu;
  bool get gameover => _gamestate == #gameover;
  bool get running => _gamestate == #running;
  void start(int lvl) {
    activeField = new Level(xFieldSize, yFieldSize);
    view.createEmptyField();
    LevelLoader.testlevel(); //TODO [lvl] auswahl machen
    _gamestate = #running;
    view.gameStateChange(_gamestate);
    view.update();
    activeField.mapPathToEntity(enemies, player);
    tick = new Timer.periodic(tickSpeed, (_) => _tickUpdate());


    //Tastatursteuerung Events
    window.onKeyDown.listen((KeyboardEvent ev) {
      if (!running) return;
      switch (ev.keyCode) {
        case KeyCode.LEFT:  if (player != null) player.moveDir(#left); break;
        case KeyCode.RIGHT: if (player != null) player.moveDir(#right); break;
        case KeyCode.UP:    if (player != null) player.moveDir(#up); break;
        case KeyCode.DOWN:  if (player != null) player.moveDir(#down); break;
        case KeyCode.SPACE: if (player != null) player.shoot(#basic); break;
      //case KeyCode.P: LevelLoader.printLevelAsJson(activeField); break;
      //case KeyCode.L: LevelLoader.getLevelFromJson("lvl/1.json").then((x) => activeField = x); break;
      }
      view.update();
    });

    if(TouchEvent.supported && running) {
      querySelector("#controls").style.visibility = "visible";
      //Smartphonesteuerung Events
      querySelector("#up").onClick.listen(dpadEvent);
      querySelector("#down").onClick.listen(dpadEvent);
      querySelector("#right").onClick.listen(dpadEvent);
      querySelector("#left").onClick.listen(dpadEvent);

      querySelector("#gameTable").onClick.listen((MouseEvent event) {
        if (player != null) {
          player.shoot(#basic);
        }
        view.update();
      });
    }
  }
  void stop() {
    tick.cancel();
    _gamestate = #gameover;
    view.gameStateChange(_gamestate);
  }

  BattleGameController() {
    querySelector("#levelStart").onClick.listen((MouseEvent ev) {
      start(1);
    });
  }

  void dpadEvent(MouseEvent event) {
    if (player != null) {
      HtmlElement he = event.target;
      player.moveDir(new Symbol(he.id));
      view.update();
    }
  }

  /**
   * Wird alle [tickSpeed] Millisekunden durchgeführt, um Bewegungen von Gegnern und Projektilen durchzuführen.
   */
  void _tickUpdate() {
    if(player == null) stop(); //Spieler tot -> Game over

    window.dispatchEvent(new CustomEvent("fullspeed"));
    if(tickCounter == 0) {
      window.dispatchEvent(new CustomEvent("slowspeed"));

      if(debug) { //pathing debug
        for(int y = 0; y < activeField.pathToPlayer.length; y++) {
          for(int x = 0; x < activeField.pathToPlayer[y].length; x++) {
            view.setFieldText(x, y, "x${x}y${y}: ${activeField.pathToPlayer[y][x]}");
            if(activeField.pathToPlayer[y][x] == yFieldSize*xFieldSize) view.setFieldColor(x, y, "black");
            else view.setFieldColor(x, y, "lightgreen");
          }
        }
      }
      tickCounter = tickDividerSlow;
    }

    view.update();
    tickCounter--;
  }
}