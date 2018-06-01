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
const tickSpeed = const Duration(milliseconds: 100);
const shootSpeed = const Duration(milliseconds: 500); ///Ein Schuss alle [shotSpeed] ms erlaubt
const int tickDividerSlow = 5; ///[tickSpeed]*[tickDividerSlow] = langsame Tickspeed für z.B. pathfinding