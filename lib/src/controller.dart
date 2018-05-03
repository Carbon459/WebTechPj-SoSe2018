part of battlecity;

class BattleGameController {
  final game = new BattleGame();
  final view = new BattleView();

  BattleGameController() {
    view.createEmptyField();
    view.update(game);

    window.onKeyDown.listen((KeyboardEvent ev) {
      if (game.stopped) return;
      switch (ev.keyCode) {
        case KeyCode.LEFT:  game.player.moveLeft(); break;
        case KeyCode.RIGHT: game.player.moveRight(); break;
        case KeyCode.UP:    game.player.moveUp(); break;
        case KeyCode.DOWN:  game.player.moveDown(); break;
      }
      view.update(game);

    });
  }


















}