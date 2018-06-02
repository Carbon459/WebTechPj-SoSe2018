part of battlecity;

class BattleGameController {
  final view = new BattleView();

  Timer tick;
  int tickCounter = 0;
  Symbol gamestate = #menu;
  int lastUnlockedLevel = 1;
  List<StreamSubscription> eventSubscriptions = new List<StreamSubscription>();

  bool get menu => gamestate == #menu;
  bool get gameover => gamestate == #gameover;
  bool get running => gamestate == #running;

  void start(int lvl) {
    Level.active = new Level(XFIELDSIZE, YFIELDSIZE);
    view.createEmptyField();
    LevelLoader.getLevelFromJson("lvl/$lvl.json").then((x) {
      if(DEBUG) print("LevelLoader: done");

      Level.active.mapPathToEntity(Level.activeEnemies, Player.active);
      view.gameStateChange(gamestate = #running);
      view.update(Level.active);
      tick = new Timer.periodic(tickSpeed, (_) => _tickUpdate());

      eventSubscriptions.add(window.onKeyUp.listen((KeyboardEvent ev) {if(ev.keyCode == KeyCode.SPACE) ev.preventDefault();})); //Workaround für Firefox, da sonst mit Leertaste Click Events auf den Level Startbuttons augelöst werden.

      //Tastatursteuerung Events
      eventSubscriptions.add(window.onKeyDown.listen((KeyboardEvent ev) {
        if (!running) return;
        switch (ev.keyCode) {
          case KeyCode.LEFT:  if (Player.isAlive()) Player.active.moveDir(#left); break;
          case KeyCode.RIGHT: if (Player.isAlive()) Player.active.moveDir(#right); break;
          case KeyCode.UP:    if (Player.isAlive()) Player.active.moveDir(#up); break;
          case KeyCode.DOWN:  if (Player.isAlive()) Player.active.moveDir(#down); break;
          case KeyCode.SPACE: if (Player.isAlive()) Player.active.shoot(#basic); break;
          case KeyCode.P:     if(DEBUG) LevelLoader.printLevelAsJson(Level.active); break;
        }
        view.update(Level.active);
      }));

      if(TouchEvent.supported && running) {
        var rng = new Random();
        if(false) { //Zufallsauswahl zwischen virtualdpad und swipe steuerung
          int touchdifX, touchdifY;
          eventSubscriptions.add(window.onTouchStart.listen((TouchEvent te) {
            touchdifX = te.changedTouches[0].screen.x;
            touchdifY = te.changedTouches[0].screen.y;
          }));
          eventSubscriptions.add(window.onTouchEnd.listen((TouchEvent te) {
            touchdifX -= te.changedTouches[0].screen.x;
            touchdifY -= te.changedTouches[0].screen.y;
            swipeEvent(touchdifX, touchdifY);
            view.update(Level.active);
          }));
        } else {
          querySelector("#controls").style.visibility = "visible";
          eventSubscriptions.add(querySelector("#up").onClick.listen(dpadEvent));
          eventSubscriptions.add(querySelector("#down").onClick.listen(dpadEvent));
          eventSubscriptions.add(querySelector("#right").onClick.listen(dpadEvent));
          eventSubscriptions.add(querySelector("#left").onClick.listen(dpadEvent));

          eventSubscriptions.add(querySelector("#gameTable").onClick.listen((MouseEvent event) {
            if (Player.isAlive()) {
              Player.active.shoot(#basic);
            }
            view.update(Level.active);
          }));
        }
      }
    });

  }
  void stop() {
    tick.cancel();
    for(var x in eventSubscriptions) { //Alle Inputevents (außer Menübuttons!) canceln
      x.cancel();
    }
    for(Enemy x in Level.activeEnemies) { //Gegnerevents canceln
      x.removeEventListener();
    }
    for(Projectile x in Level.activeProjectiles) { //Projektilevent canceln (könnten noch welche in der luft sein)
      x.removeEventListener();
    }
    Level.activeEnemies.clear();
    Level.activeProjectiles.clear();
    Player.active = null;
    eventSubscriptions.clear();
    view.gameStateChange(gamestate = #gameover);
  }

  BattleGameController() {
    syncSaveData();
    view.unlockMenu(lastUnlockedLevel);

    querySelector("#level1").onClick.listen((MouseEvent ev) {
      start(1);
    }); //TODO: mehr level

    querySelector("#toggleFS").onClick.listen((MouseEvent ev) {
      var e = new JsObject.fromBrowserObject(document.body);
      e.callMethod("webkitRequestFullScreen", []);
    });
    querySelector("#menuButton").onClick.listen((MouseEvent ev) {
      view.gameStateChange(gamestate = #menu);
    });
  }

  void syncSaveData() {
    if(!window.localStorage.containsKey("lastUnlockedLevel")) {
      window.localStorage["lastUnlockedLevel"] = lastUnlockedLevel.toString();
    } else {
      final int localStorage = int.parse(window.localStorage["lastUnlockedLevel"]);
      if(lastUnlockedLevel > localStorage) window.localStorage["lastUnlockedLevel"] = lastUnlockedLevel.toString();
      else lastUnlockedLevel = localStorage;
    }
  }

  void swipeEvent(int touchdifX, int touchdifY) {
    if (!Player.isAlive()) return;

    if(touchdifX.abs() > touchdifY.abs()) { //Horizontal mehr geswiped als vertikal
      if(touchdifX > 0) {
        Player.active.moveDir(new Symbol("left"));
      } else if (touchdifX < 0) {
        Player.active.moveDir(new Symbol("right"));
      }
    }
    else if(touchdifX.abs() < touchdifY.abs()) { //Horizontal weniger geswiped als vertikal
      if(touchdifY > 0) {
        Player.active.moveDir(new Symbol("up"));
      } else if (touchdifY < 0) {
        Player.active.moveDir(new Symbol("down"));
      }
    }
    else if (touchdifX == 0 && touchdifY == 0) {
      Player.active.shoot(#basic);
    }
  }
  void dpadEvent(MouseEvent event) {
    if (Player.isAlive()) {
      HtmlElement he = event.target;
      Player.active.moveDir(new Symbol(he.id));
      view.update(Level.active);
    }
  }

  /**
   * Wird alle [tickSpeed] Millisekunden durchgeführt, um Bewegungen von Gegnern und Projektilen durchzuführen.
   */
  void _tickUpdate() {
    if(!Player.isAlive())
      stop(); //Spieler tot -> Game over
    if(Level.activeEnemies.isEmpty) {//Alle Gegner tot
      if(lastUnlockedLevel != MAXLEVEL) {  //Nächste Level freischalten falls vorhanden
        lastUnlockedLevel++;
        syncSaveData();
      }
      stop();
    }

    window.dispatchEvent(new CustomEvent("fullspeed"));
    if(tickCounter == 0) {
      window.dispatchEvent(new CustomEvent("slowspeed"));

      if(DEBUG) { //pathing debug
        for(int y = 0; y < Level.active.pathToPlayer.length; y++) {
          for(int x = 0; x < Level.active.pathToPlayer[y].length; x++) {
            view.setFieldText(x, y, "x${x}y${y}:<br> ${Level.active.pathToPlayer[y][x]}");
            if(Level.active.pathToPlayer[y][x] == YFIELDSIZE*XFIELDSIZE) view.setFieldColor(x, y, "black");
            else view.setFieldColor(x, y, "lightgreen");
          }
        }
      }
      tickCounter = tickDividerSlow;
    }

    view.update(Level.active);
    tickCounter--;
  }
}