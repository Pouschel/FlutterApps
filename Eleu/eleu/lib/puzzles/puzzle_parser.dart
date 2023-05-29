import 'package:eleu/puzzles/puzzle_types.dart';

import '../types.dart';

class PuzzleParser {
  static void ParseItem(FieldState fs, string s) {
    var parts = s.splitAndRemoveEmpty(' ');
    for (var item in parts) {
      var n = int.tryParse(item);
      if (n != null) {
        fs.SVal = n.toString();
        continue;
      }
      if (!SetItem(fs, item)) fs.SVal = item;
    }
  }

  static bool SetItem(FieldState fs, string s) {
    var col = ParseShapeColor(s, false);
    if (col != null) {
      fs.Color = col;
      return true;
    }
    var shape = ParseFieldShape(s, false);
    if (shape != null) {
      fs.Shape = shape;
      return true;
    }
    var obj = ParseFieldObjects(s, false);
    if (obj != null) {
      fs.Object = obj;
      return true;
    }
    return false;
  }
}
