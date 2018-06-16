part of battlecity;

class BattleGameController {
  BattleView view;

  Timer tick;
  int tickCounter = 0;
  Symbol gamestate = #menu;
  int currentLevel = 0;
  int lastUnlockedLevel = 1;
  ///Enthält Steuerungsevent subscriptions
  List<StreamSubscription> eventSubscriptions = new List<StreamSubscription>();

  bool get menu => gamestate == #menu;
  bool get gameover => gamestate == #gameover;
  bool get gamewon => gamestate == #gamewon;
  bool get running => gamestate == #running;
  bool get levelbuilder => gamestate == #levelbuilder;


  BattleGameController() {
    Config.load().then((x) {
      view = new BattleView();

      syncSaveData();
      view.drawMenu(Config.MAXLEVEL);
      view.unlockMenu(lastUnlockedLevel);

      for(int i = 1; i <= Config.MAXLEVEL; i++) {
        querySelector("#level$i").onClick.listen((MouseEvent ev) {
          if(TouchEvent.supported) fullscreenWorkaround(document.body);
          start(i);
        });
      }

      querySelectorAll(".btm").onClick.listen((MouseEvent ev) {
        view.gameStateChange(gamestate = #menu);
      });
      querySelector("#retry").onClick.listen((MouseEvent ev) {
        start(currentLevel);
      });


      if(!TouchEvent.supported) {
        querySelector("#levelbuilder").onClick.listen((MouseEvent ev) {
          startLevelBuilder();
        });
      }
      window.addEventListener('orientationchange',(x) {
        if(menu) {
          view.drawMenu(Config.MAXLEVEL);
          view.unlockMenu(lastUnlockedLevel);
        }
      });
   });
  }

  /**
   * Startet das Level mit der Nummer [lvl]
   */
  void start(int lvl) {
    currentLevel = lvl;
    Level.active = new Level(Config.XFIELDSIZE, Config.YFIELDSIZE);
    view.createEmptyField();
    LevelLoader.getLevelFromJson("lvl/$lvl.json").then((x) {
      if(Config.DEBUG) print("LevelLoader: done");

      Level.active.mapPathToEntity(Level.activeEnemies, Player.active);
      view.gameStateChange(gamestate = #running);
      view.update(Level.active);
      tick = new Timer.periodic(Config.TICKSPEED, (_) => tickUpdate());

      eventSubscriptions.add(window.onKeyUp.listen((KeyboardEvent ev) {if(ev.keyCode == KeyCode.SPACE) ev.preventDefault();})); //Workaround für Firefox, da sonst mit Leertaste Click Events auf den Level Startbuttons augelöst werden.

      //Tastatursteuerung Events
      eventSubscriptions.add(window.onKeyDown.listen((KeyboardEvent ev) {
        if (!running) return;
        switch (ev.keyCode) {
          case KeyCode.LEFT:  if (Player.isAlive()) Player.active.moveDir(#left); break;
          case KeyCode.RIGHT: if (Player.isAlive()) Player.active.moveDir(#right); break;
          case KeyCode.UP:    if (Player.isAlive()) Player.active.moveDir(#up); break;
          case KeyCode.DOWN:  if (Player.isAlive()) Player.active.moveDir(#down); break;
          case KeyCode.SPACE: if (Player.isAlive()) Player.active.shoot(); break;
          case KeyCode.P:     if(Config.DEBUG) LevelLoader.printLevelAsJson(Level.active); break;
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
            Player.active.shoot();
          }
          view.update(Level.active);
        }));
      }
    });

  }

  /**
   * Stoppt das aktive Level
   * [won] gibt an ob das Level beendet wurde weil der Spieler gestorben ist oder weil alle Gegner besiegt wurden
   */
  void stop(bool won) {
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

    if(won) view.gameStateChange(gamestate = #gamewon);
    else view.gameStateChange(gamestate = #gameover);

    view.unlockMenu(lastUnlockedLevel);
  }

  /**
   * Synchronisiert die Variable [lastUnlockedLevel] mit dem Local Storage des Browsers
   */
  void syncSaveData() {
    if(!window.localStorage.containsKey("lastUnlockedLevel")) {
      window.localStorage["lastUnlockedLevel"] = lastUnlockedLevel.toString();
    } else {
      final int localStorage = int.parse(window.localStorage["lastUnlockedLevel"]);
      if(lastUnlockedLevel > localStorage) window.localStorage["lastUnlockedLevel"] = lastUnlockedLevel.toString();
      else lastUnlockedLevel = localStorage;
    }
  }

  /**
   * Verarbeitet die Events für das DPad
   */
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
  void tickUpdate() {
    view.updatePlayerHP(Player.active?.hp ?? 0);

    if(!Player.isAlive())
      stop(false); //Spieler tot -> Game over
    else if(Level.activeEnemies.isEmpty) {//Alle Gegner tot
      if(lastUnlockedLevel != Config.MAXLEVEL) {  //Nächste Level freischalten falls vorhanden
        lastUnlockedLevel++;
        syncSaveData();
      }
      stop(true);
    }

    if(tickCounter == 0) { //Jeden [Config.TICKDIVIVERSLOW] tick ausgeführt
      window.dispatchEvent(new CustomEvent("slowspeed"));
      if(Config.DEBUG) showCoordinatesOnField(true); //pathing debug

      tickCounter = Config.TICKDIVIDERSLOW;
    }
    if(tickCounter % 2 == 0) { //Jeden [Config.TICKDIVIVERSLOW]/2 tick ausgeführt
      window.dispatchEvent(new CustomEvent("middlespeed"));
    }

    tickCounter--;

    window.dispatchEvent(new CustomEvent("fullspeed"));
    view.update(Level.active);
  }

  /**
   * Zeigt zu Debugzwecken die Koordinaten der einzelnen Felder an
   */
  void showCoordinatesOnField(bool withCounter) {
    for(int y = 0; y < Level.active.pathToPlayer.length; y++) {
      for(int x = 0; x < Level.active.pathToPlayer[y].length; x++) {
        if(withCounter) {
          view.setFieldText(x, y, "x${x}y${y}:<br> ${Level.active.pathToPlayer[y][x].counter}");
          if(Level.active.pathToPlayer[y][x].counter == Config.YFIELDSIZE*Config.XFIELDSIZE) view.setFieldColor(x, y, "black");
          else view.setFieldColor(x, y, "lightgreen");
        } else {
          view.setFieldText(x, y, "${x} ${y}");
        }
      }
    }
  }

  /**
   * Initialisiert den LevelBuilder
   */
  void startLevelBuilder() {
    Level.active = new Level(Config.XFIELDSIZE, Config.YFIELDSIZE);
    view.createEmptyField();
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
        LevelLoader.createObject(Config.LEVELBUILDINGBLOCKS[spriteSelection], x, y, baseSprite: spriteSelection, orientation: #up);
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

  /**
   * Fullscreen workaround: https://stackoverflow.com/a/29715395
   */
  void fullscreenWorkaround(Element element) {
    var elem = new JsObject.fromBrowserObject(element);

    if (elem.hasProperty("requestFullscreen")) {
      elem.callMethod("requestFullscreen");
    }
    else {
      List<String> vendors = ['moz', 'webkit', 'ms', 'o'];
      for (String vendor in vendors) {
        String vendorFullscreen = "${vendor}RequestFullscreen";
        if (vendor == 'moz') {
          vendorFullscreen = "${vendor}RequestFullScreen";
        }
        if (elem.hasProperty(vendorFullscreen)) {
          elem.callMethod(vendorFullscreen);
          return;
        }
      }
    }
  }

}
