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
  bool get levelbuilder => gamestate == #levelbuilder;


  BattleGameController() {
    syncSaveData();
    view.drawMenu(MAXLEVEL);
    view.unlockMenu(lastUnlockedLevel);

    for(int i = 1; i <= MAXLEVEL; i++) {
      querySelector("#level$i").onClick.listen((MouseEvent ev) {
        if(TouchEvent.supported) {
          var e = new JsObject.fromBrowserObject(document.body);
          e.callMethod("webkitRequestFullScreen", []);
        }
        start(i);
      });
    }
    
    /*querySelector("#toggleFS").onClick.listen((MouseEvent ev) {
      var e = new JsObject.fromBrowserObject(document.body);
      e.callMethod("webkitRequestFullScreen", []);
    });*/
    querySelector("#menuButton").onClick.listen((MouseEvent ev) {
      view.gameStateChange(gamestate = #menu);
    });
    querySelector("#levelbuilder").onClick.listen((MouseEvent ev) {
      startLevelBuilder();
    });
  }

  void start(int lvl) {
    Level.active = new Level(XFIELDSIZE, YFIELDSIZE);
    view.createEmptyField();
    LevelLoader.getLevelFromJson("lvl/$lvl.json").then((x) {
      if(DEBUG) print("LevelLoader: done");

      Level.active.mapPathToEntity(Level.activeEnemies, Player.active);
      view.gameStateChange(gamestate = #running);
      view.update(Level.active);
      tick = new Timer.periodic(TICKSPEED, (_) => _tickUpdate());

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

  void syncSaveData() {
    if(!window.localStorage.containsKey("lastUnlockedLevel")) {
      window.localStorage["lastUnlockedLevel"] = lastUnlockedLevel.toString();
    } else {
      final int localStorage = int.parse(window.localStorage["lastUnlockedLevel"]);
      if(lastUnlockedLevel > localStorage) window.localStorage["lastUnlockedLevel"] = lastUnlockedLevel.toString();
      else lastUnlockedLevel = localStorage;
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
   * Wird alle [TICKSPEED] Millisekunden durchgeführt, um Bewegungen von Gegnern und Projektilen durchzuführen.
   */
  void _tickUpdate() {
    view.updatePlayerHP(Player.active?.hp ?? 0);

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

      if(DEBUG) showCoordinatesOnField(true); //pathing debug

      tickCounter = TICKDIVIDERSLOW;
    }

    view.update(Level.active);
    tickCounter--;
  }

  void showCoordinatesOnField(bool withCounter) {
    for(int y = 0; y < Level.active.pathToPlayer.length; y++) {
      for(int x = 0; x < Level.active.pathToPlayer[y].length; x++) {
        if(withCounter) {
          view.setFieldText(x, y, "x${x}y${y}:<br> ${Level.active.pathToPlayer[y][x].counter}");
          if(Level.active.pathToPlayer[y][x].counter == YFIELDSIZE*XFIELDSIZE) view.setFieldColor(x, y, "black");
          else view.setFieldColor(x, y, "lightgreen");
        } else {
          view.setFieldText(x, y, "${x} ${y}");
        }
      }
    }
  }

  void startLevelBuilder() {
    Level.active = new Level(XFIELDSIZE, YFIELDSIZE);
    view.createEmptyField();
    /*if((querySelector("textarea") as TextAreaElement).value.toString().isNotEmpty) {
      LevelLoader.getLevelFromJson((querySelector("textarea") as TextAreaElement).value);
    }*/
    view.gameStateChange(gamestate = #levelbuilder);
    showCoordinatesOnField(false);
    view.drawBuildingBlocks();
    view.update(Level.active);

    String spriteSelection = "";
    bool rotateBackground = true;

    querySelector("#levelBuilderControls").onClick.listen((Event e) {
      HtmlElement he = e.target;
      if(!he.id.contains("printLevel") && !he.id.contains("rotateSwitch")  && !he.id.contains("levelBuilderControls")) {
        spriteSelection = he.id;
        print("Current Selection: $spriteSelection");
      }
    });
    querySelectorAll(".foreground").onClick.listen((Event e) {
      HtmlElement he = e.target;
      final int x = int.parse(he.innerHtml.split(" ")[0]);
      final int y = int.parse(he.innerHtml.split(" ")[1]);
      if(spriteSelection.isNotEmpty) {
        LevelLoader.createObject(LEVELBUILDINGBLOCKS[spriteSelection], x, y, baseSprite: spriteSelection, orientation: #up);
        print("Placed Selection: $spriteSelection");
      }
      view.update(Level.active);
    });
    querySelector("#rotateSwitch").onClick.listen((MouseEvent e) {
      HtmlElement he = e.target;
      if(rotateBackground) {
        rotateBackground = false;
        he.innerHtml = "Rotate Foreground";
      }
      else  {
        rotateBackground = true;
        he.innerHtml = "Rotate Background";
      }
    });

    document.addEventListener("contextmenu", (e) {
      HtmlElement he = e.target;
      if(he.toString() == "div") {
        e.preventDefault();
        final int x = int.parse(he.innerHtml.split(" ")[0]);
        final int y = int.parse(he.innerHtml.split(" ")[1]);
        if(rotateBackground) Level.active.rotateBackgroundClockWise(x, y);
        else Level.active.rotateEntityClockWise(x, y);
        view.update(Level.active);
      }
    });
    querySelector("#printLevel").onClick.listen((MouseEvent ev) {
      LevelLoader.printLevelAsJson(Level.active);
    });
  }

}
