library battlecity;

import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

//Model--------------------
part 'src/level.dart';
part 'src/entities.dart';
//View---------------------
part 'src/view.dart';
//Controller---------------
part 'src/controller.dart';


const xFieldSize = 15;
const yFieldSize = 10;
const bool debug = true;



/// Das momentan aktive Modellspielfeld
Level activeField;
Player player;
List<Enemy> enemies = new List<Enemy>();