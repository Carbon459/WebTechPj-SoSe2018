library battlecity;

import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:js';

//Model--------------------
part 'src/level.dart';
part 'src/entities.dart';
part 'src/abstractentities.dart';
//View---------------------
part 'src/view.dart';
//Controller---------------
part 'src/controller.dart';

///Levelgröße
const XFIELDSIZE = 15;
const YFIELDSIZE = 10;
///Anzahl der Level
const MAXLEVEL = 1;
///Maximale Lebenspunktezahl des Spielers
const MAXPLAYERHP = 3;
///Debug
const bool DEBUG = false;
///Ein tickUpdate wird so oft ausgeführt
const TICKSPEED = const Duration(milliseconds: 100);
///Ein Schuss alle [shotSpeed] ms erlaubt
const SHOOTSPEED = const Duration(milliseconds: 500);
///[TICKSPEED]*[TICKDIVIDERSLOW] = langsame Tickspeed für z.B. pathfinding
const int TICKDIVIDERSLOW = 5;
///Map aller Objekte die im LevelBuilder verfügbar sind
const Map<String, String> LEVELBUILDINGBLOCKS = const { "house":            "Scenery",
                                                          "road_basic":       "Background",
                                                          "road_end":         "Background",
                                                          "road_intersection":"Background",
                                                          "road_L":           "Background",
                                                          "road_T":           "Background"};