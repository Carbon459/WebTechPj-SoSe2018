part of battlecity;

const tickSpeed = const Duration(milliseconds: 200);

class BattleGameController {
  final game = new BattleGame();
  final view = new BattleView();

  Timer tick;

  BattleGameController() {
    view.createEmptyField();
    view.update(game);
    tick = new Timer.periodic(tickSpeed, (_) => _tickUpdate());

    //Tastatursteuerung Events
    window.onKeyDown.listen((KeyboardEvent ev) {
      if (game.stopped) return;
      switch (ev.keyCode) {
        case KeyCode.LEFT:  if (player != null) { player.setOrientation(#left); player.move(); } break;
        case KeyCode.RIGHT: if (player != null) { player.setOrientation(#right); player.move(); } break;
        case KeyCode.UP:    if (player != null) { player.setOrientation(#up); player.move(); } break;
        case KeyCode.DOWN:  if (player != null) { player.setOrientation(#down); player.move(); } break;
        case KeyCode.SPACE: if (player != null) { player.shoot(#basic); } break;
        //case KeyCode.P: LevelLoader.printLevelAsJson(activeField); break;
        //case KeyCode.L: LevelLoader.getLevelFromJson("lvl/1.json").then((x) => activeField = x); break;
      }
      view.update(game);
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
        view.update(game);
      });
    }

    LevelLoader.testlevel();
  }
  void dpadEvent(MouseEvent event) {
    HtmlElement he = event.target;
    if (player != null) {
      player.setOrientation(new Symbol(he.id));
      player.move();
    }
    view.update(game);
  }

  /**
   * Wird alle [tickSpeed] Millisekunden durchgeführt, um Bewegungen von Gegnern und Projektilen durchzuführen.
   */
  void _tickUpdate() {
    window.dispatchEvent(new CustomEvent("mDE"));
    view.update(game);
  }
}