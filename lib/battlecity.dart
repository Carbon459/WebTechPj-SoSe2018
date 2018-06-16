library battlecity;

import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:js';
import 'dart:collection';

//Model--------------------
part 'src/level.dart';
part 'src/entities.dart';
part 'src/abstractentities.dart';
//View---------------------
part 'src/view.dart';
//Controller---------------
part 'src/controller.dart';


/**
 * Klasse für Spielkonstanten
 */
class Config {
  ///-------------------DEFAULT WERTE-----------------------
  ///Levelgröße
  static int XFIELDSIZE = 18;
  static int YFIELDSIZE = 10;
  ///Anzahl der Level
  static int MAXLEVEL = 2;
  ///Maximale Lebenspunktezahl des Spielers
  static int MAXPLAYERHP = 3;
  ///Debug
  static bool DEBUG = false;
  ///Ein tickUpdate wird so oft ausgeführt
  static Duration TICKSPEED = const Duration(milliseconds: 100);
  ///Ein Schuss alle [shotSpeed] ms erlaubt
  static Duration SHOOTSPEED = const Duration(milliseconds: 500);
  ///Animationsdauer Explosion
  static Duration EXPLOSIONDUR = const Duration(milliseconds: 200);
  ///[TICKSPEED]*[TICKDIVIDERSLOW] = langsame Tickspeed für z.B. pathfinding
  static int TICKDIVIDERSLOW = 5;
  ///Map aller Objekte die im LevelBuilder verfügbar sind
  static Map<String, String> LEVELBUILDINGBLOCKS = const {};

  static Future<int> load() async {
    String json = await HttpRequest.getString("config.json");
    Map<String, dynamic> jsonMap = JSON.decode(json);

    XFIELDSIZE = jsonMap["XFIELDSIZE"];
    YFIELDSIZE = jsonMap["YFIELDSIZE"];
    MAXLEVEL = jsonMap["MAXLEVEL"];
    MAXPLAYERHP = jsonMap["MAXPLAYERHP"];
    DEBUG = jsonMap["DEBUG"] == "true";
    TICKSPEED = new Duration(milliseconds: jsonMap["TICKSPEED"]);
    SHOOTSPEED = new Duration(milliseconds: jsonMap["SHOOTSPEED"]);
    EXPLOSIONDUR = new Duration(milliseconds: jsonMap["EXPLOSIONDUR"]);
    TICKDIVIDERSLOW = jsonMap["TICKDIVIDERSLOW"];
    LEVELBUILDINGBLOCKS = jsonMap["LEVELBUILDINGBLOCKS"];

    return 0;
  }
}