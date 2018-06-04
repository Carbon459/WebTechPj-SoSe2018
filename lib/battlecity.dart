library battlecity;

import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:js';

//Model--------------------
part 'src/level.dart';
part 'src/entities.dart';
//View---------------------
part 'src/view.dart';
//Controller---------------
part 'src/controller.dart';


const XFIELDSIZE = 15;
const YFIELDSIZE = 10;
const MAXLEVEL = 1;
const MAXPLAYERHP = 3;
const bool DEBUG = false;
const tickSpeed = const Duration(milliseconds: 100);
const shootSpeed = const Duration(milliseconds: 500); ///Ein Schuss alle [shotSpeed] ms erlaubt
const int tickDividerSlow = 5; ///[tickSpeed]*[tickDividerSlow] = langsame Tickspeed für z.B. pathfinding