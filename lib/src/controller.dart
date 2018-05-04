part of battlecity;

const tickSpeed = const Duration(milliseconds: 200);

class BattleGameController {
  final game = new BattleGame();
  final view = new BattleView();

  Timer tick;

  BattleGameController() {
    view.createEmptyField();
    view.update(game);

    tick = new Timer.periodic(tickSpeed, (_) => _moveDynamicEntities());

    //Tastatursteuerung Events
    window.onKeyDown.listen((KeyboardEvent ev) {
      if (game.stopped) return;
      switch (ev.keyCode) {
        case KeyCode.LEFT:  game.player.moveLeft(); break;
        case KeyCode.RIGHT: game.player.moveRight(); break;
        case KeyCode.UP:    game.player.moveUp(); break;
        case KeyCode.DOWN:  game.player.moveDown(); break;
        case KeyCode.SPACE: game.player.shoot(#basic); break;
      }
      view.update(game);

    });
  }

  void _moveDynamicEntities() {
    //Uncaught Error: Concurrent modification during iteration -> dEntity wird bei kollision mit spielfeldrändern entfernt während hier iteriert wird.
    //Lösung: zu entfernende entities in liste sammeln und anschließend entfernen
    var toRemove = [];
    selfmoving.forEach((dEntity) {
      if(!dEntity.move()) {
        toRemove.add(dEntity);
      }
    });

    toRemove.forEach((dEntity) {
      dEntity.destroy();
    });

    view.update(game);
  }
}