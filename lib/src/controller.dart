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
    LevelLoader.testlevel();
  }

  /**
   * Wird alle [tickSpeed] Millisekunden durchgeführt, um Bewegungen von Gegnern und Projektilen durchzuführen.
   */
  void _tickUpdate() {
    window.dispatchEvent(new CustomEvent("mDE"));
    view.update(game);
  }
}