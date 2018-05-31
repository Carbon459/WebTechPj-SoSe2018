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
    LevelLoader.getLevelFromJson("lvl/$lvl.json").then((x) {
      if(debug) print("LevelLoader: done");
      activeField.mapPathToEntity(enemies, player);
      _gamestate = #running;
      view.gameStateChange(_gamestate);
      view.update();
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
          case KeyCode.P: if(debug) LevelLoader.printLevelAsJson(activeField); break;
        }
        view.update();
      });

      if(TouchEvent.supported && running) {
        var rng = new Random();
        if(rng.nextBool()) { //Zufallsauswahl zwischen virtualdpad und swipe steuerung
          int touchdifX, touchdifY;
          window.onTouchStart.listen((TouchEvent te) {
            te.preventDefault();
            touchdifX = te.changedTouches[0].screen.x;
            touchdifY = te.changedTouches[0].screen.y;
          });
          window.onTouchEnd.listen((TouchEvent te) {
            te.preventDefault();
            touchdifX -= te.changedTouches[0].screen.x;
            touchdifY -= te.changedTouches[0].screen.y;
            swipeEvent(touchdifX, touchdifY);
            view.update();
          });
        } else {
          querySelector("#controls").style.visibility = "visible";
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
    });

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
  void swipeEvent(int touchdifX, int touchdifY) {
    if (player == null) return;

    if(touchdifX.abs() > touchdifY.abs()) { //Horizontal mehr geswiped als vertikal
      if(touchdifX > 0) {
        player.moveDir(new Symbol("left"));
      } else if (touchdifX < 0) {
        player.moveDir(new Symbol("right"));
      }
    }
    else if(touchdifX.abs() < touchdifY.abs()) { //Horizontal weniger geswiped als vertikal
      if(touchdifY > 0) {
        player.moveDir(new Symbol("up"));
      } else if (touchdifY < 0) {
        player.moveDir(new Symbol("down"));
      }
    }
    else if (touchdifX == 0 && touchdifY == 0) {
      player.shoot(#basic);
    }
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
            view.setFieldText(x, y, "x${x}y${y}:<br> ${activeField.pathToPlayer[y][x]}");
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