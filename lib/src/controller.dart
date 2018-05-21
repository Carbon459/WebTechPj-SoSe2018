part of battlecity;

const tickSpeed = const Duration(milliseconds: 120);

class BattleGameController {
  final view = new BattleView();

  Timer tick;

  Symbol _gamestate;

  bool get stopped => _gamestate == #stopped;
  bool get running => _gamestate == #running;
  void start() { _gamestate = #running; }
  void stop() { _gamestate = #stopped; }

  BattleGameController() {
    start();
    activeField = new Level(xFieldSize, yFieldSize);
    player = new Player(0,0);

    view.createEmptyField();
    view.update();
    tick = new Timer.periodic(tickSpeed, (_) => _tickUpdate());

    //Tastatursteuerung Events
    window.onKeyDown.listen((KeyboardEvent ev) {
      if (stopped) return;
      switch (ev.keyCode) {
        case KeyCode.LEFT:  if (player != null) { player.setOrientation(#left); player.move(); } break;
        case KeyCode.RIGHT: if (player != null) { player.setOrientation(#right); player.move(); } break;
        case KeyCode.UP:    if (player != null) { player.setOrientation(#up); player.move(); } break;
        case KeyCode.DOWN:  if (player != null) { player.setOrientation(#down); player.move(); } break;
        case KeyCode.SPACE: if (player != null) { player.shoot(#basic); } break;
        //case KeyCode.P: LevelLoader.printLevelAsJson(activeField); break;
        //case KeyCode.L: LevelLoader.getLevelFromJson("lvl/1.json").then((x) => activeField = x); break;
      }
      view.update();
    });

    if(TouchEvent.supported) {
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

    LevelLoader.testlevel();
    activeField.mapPathToPlayer();
  }
  void dpadEvent(MouseEvent event) {
    HtmlElement he = event.target;
    if (player != null) {
      player.setOrientation(new Symbol(he.id));
      player.move();
    }
    view.update();
  }

  //TODO bennenen und konstante machen
  int tickCounter = 0;
  /**
   * Wird alle [tickSpeed] Millisekunden durchgeführt, um Bewegungen von Gegnern und Projektilen durchzuführen.
   */
  void _tickUpdate() {
    window.dispatchEvent(new CustomEvent("fullspeed"));
    if(tickCounter == 6) {
      window.dispatchEvent(new CustomEvent("slowspeed"));
      activeField.mapPathToPlayer();
      if(debug) { //pathing debug
        for(int y = 0; y < activeField.pathToPlayer.length; y++) {
          for(int x = 0; x < activeField.pathToPlayer[y].length; x++) {
            view.setFieldText(x, y, "x${x}y${y}: ${activeField.pathToPlayer[y][x]}");
          }
        }
      }
      tickCounter = 0;
    }
    view.update();
    tickCounter++;
  }
}