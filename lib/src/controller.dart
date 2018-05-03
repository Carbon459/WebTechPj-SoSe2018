part of battlecity;

class BattleGameController {
  var game = new BattleGame();
  final view = new BattleView();

  BattleGameController() {

      querySelector('#output').text = 'Your Dart app is running!';
  }
}