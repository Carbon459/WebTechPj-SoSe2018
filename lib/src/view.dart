part of battlecity;

class BattleView {
  List<List<Element>> tableFields = new List(yFieldSize);

  void update(BattleGame model) {
    for (int y = 0; y < yFieldSize; y++) {
      for (int x = 0; x < xFieldSize; x++) {
        final td = tableFields[y][x];
        final modelField = _field[y][x];
        if(modelField != null) {
          td.style.backgroundImage = "url('img/${modelField.sprite}')";
        } else {
          td.style.backgroundImage = "none";
        }
      }
    }
  }

  void createEmptyField() {
    String table = "";
    for (int y = 0; y < yFieldSize; y++) {
      table += "<tr>";
      for (int x = 0; x < xFieldSize; x++) {
        final pos = "x${x}y${y}";
        table += "<td id='$pos'></td>";
      }
      table += "</tr>";
    }
    querySelector('#game').innerHtml = table;

    for (int y = 0; y < yFieldSize; y++) {
      tableFields[y] = new List<Element>(xFieldSize);
      for (int x = 0; x < xFieldSize; x++) {
        tableFields[y][x] = querySelector("#x${x}y${y}");
      }
    }
  }
}