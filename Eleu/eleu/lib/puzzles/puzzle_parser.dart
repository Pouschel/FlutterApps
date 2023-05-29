import 'dart:math';
import 'package:hati/hati.dart';

import '../scanning.dart';
import 'puzzle.dart';
import 'puzzle_types.dart';

class PuzzleParser {
  InputStatus? status;
  List<string> lines = [];
  int lineNr = 0;
  // value: string or  Func<FieldState,FieldState>
  Map<string, object> get defs => puzzle.Defs;
  int colCount = 0;
  late Puzzle puzzle;
  Cat get cat => puzzle.cat;
  late PuzzleBundle bundle;
  Random rand = Random();

  string? get CurLine => lineNr >= lines.length ? null : lines[lineNr].trimRight();

  PuzzleParser(string txt, this.status) {
    this.bundle = PuzzleBundle(txt);
    this.puzzle = Puzzle(bundle);
    this.status = status;
    this.lines = txt.split('\n');
  }

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

  void MoveNext() => lineNr++;
  PuzzleBundle Parse() {
    for (int i = 0; i < 10; i++) {
      defs[i.toString()] = i.toString();
    }
    defs["."] = "None None";
    while (true) {
      var line = CurLine;
      if (line == null) break;
      if (line == ":def") {
        ParseDefs();
        continue;
      }
      if (line == ":grid") {
        ParseGrid();
        continue;
      }
      if (line == ":meta") {
        ParseMeta();
        continue;
      }
      if (line == ":info") {
        ParseInfo();
        continue;
      }
      if (line.isEmpty) {
        MoveNext();
        continue;
      }
      throw CreateError("Unbekannte Sektion $line");
    }
    return bundle;
  }

  void ParseInfo() {
    MoveNext();
    var sb = StringBuffer();
    for (;; MoveNext()) {
      var line = CurLine;
      if (line == null) break;
      if (line.isNotEmpty && line[0] == ':') break;
      sb.writeln(line);
    }
    puzzle.Description = sb.toString();
  }

  void ParseMeta() {
    if (puzzle.RowCount == 0)
      throw CreateError("Vor der ':meta'-Sektion muss die ':grid'-Sektion kommen.");
    MoveNext();
    for (;; MoveNext()) {
      var line = CurLine;
      if (line == null) break;
      if (line.isEmpty) continue;
      if (line[0] == ':') break;
      var (key, val) = ParseKeyValue(line);
      switch (key) {
        case "name":
          puzzle.Name = val;
          break;
        case "win":
          puzzle.WinCond = val;
          if (puzzle.CheckWin() == null)
            throw CreateError("Ungültige Siegbedingung: '${val}'");
          break;
        case "hash":
          break;
        case "funcs":
          puzzle.SetFuncs(val);
          break;
        case "score":
          var score = int.tryParse(val);
          if (score == null || score <= 0)
            throw CreateError("Der Score muss eine positive Zahl sein.");
          puzzle.Complexity = score;
          break;
        default:
          throw CreateError("Unsupported key: ${key}");
      }
    }
  }

  void SetGrid(GridType fields, int colCount) {
    for (var line in fields) {
      if (line.length < colCount) {
        for (var i = 0; i < colCount - line.length; i++) {
          line.add(FieldState());
        }
      }
    }
    puzzle.SetGrid(fields);
  }

  void ParseGrid() {
    puzzle = puzzle.Copy();
    bundle.AddPuzzle(puzzle);
    GridType fields = [];
    MoveNext();
    cat.Row = -1;
    for (;; MoveNext()) {
      var line = CurLine;
      if (line == null) break;
      if (line.isNotEmpty && line[0] == ':') break;
      var list = ParseFieldLine(fields.length, line);
      colCount = max(colCount, list.length);
      fields.add(list);
    }
    if (cat.Row < 0) throw CreateError("Das Feld muss eine Katze enthalten.");
    SetGrid(fields, colCount);
  }

  List<FieldState> ParseFieldLine(int row, string line) {
    var result = <FieldState>[];
    for (int i = 0; i < line.length; i++) {
      var ch = line.substring(i, i + 1);
      var fs = FieldState();
      if (ch != " " && ch != ".") {
        var o = defs[ch];
        if (o == null) throw CreateError("Definition für '${ch}' nicht gefunden");
        if (o is string) {
          var fill = o;
          if (fill.startsWith("'")) // field with long string
            fs.SVal = fill.substring(1);
          else if (fill.startsWith("Cat")) {
            if (cat.Row >= 0) throw CreateError("Feld hat schon eine Katze");
            cat.Row = row;
            cat.Col = i;
            var catDir = fill.substring(3);

            var ctDir = ParseDirections(catDir, false);
            if (catDir.isNotEmpty && ctDir == null)
              throw CreateError("Ungültige Blickrichtung für Katze: '${catDir}'");
            ctDir ??= Directions.E;
            cat.LookAt = ctDir;
          } else {
            ParseItem(fs, fill);
          }
        } else if (o is FieldState Function(FieldState)) {
          fs = o(fs);
        } else
          throw CreateError("Can't interpret: $ch");
      }
      fs.FixColor();
      result.add(fs);
    }
    return result;
  }

  void ParseDefs() {
    MoveNext();
    for (;; MoveNext()) {
      var line = CurLine;
      if (line == null) break;
      if (line.isEmpty) continue;
      if (line[0] == ':') break;
      var (key, val) = ParseKeyValue(line);
      if (key == "seed") {
        var ival = int.tryParse(val);
        if (ival == null) throw CreateError("Ungültiger seed-Wert: $val");
        rand = Random(ival);
        continue;
      }
      if (val.startsWith("rnd ")) {
        try {
          var parts = val.splitAndRemoveEmpty(' ');
          int s1 = int.parse(parts[1]);
          int s2 = int.parse(parts[2]);

          FieldState SetRandNumber(FieldState cell, int a, int b) {
            cell.SVal = (a + rand.nextInt(b - a + 1)).toString();
            return cell;
          }

          action(cell) => SetRandNumber(cell, s1, s2);
          defs[key] = action;
          continue;
        } on Exception {
          throw CreateError("Ungültige rnd-Zeile: $val");
        }
      }
      defs[key] = val;
    }
  }

  (string, string) ParseKeyValue(string line) {
    int idx = line.indexOf('=');
    if (idx < 0) throw CreateError("Key = Value erwartet");
    string key = line.substring(0, idx).trim();
    string val = line.substring(idx + 1).trim();
    if (key.isEmpty) throw CreateError("Ein leerer Schlüsselwert ist nicht erlaubt.");
    return (key, val);
  }

  PuzzleParseException CreateError(string msg) {
    InputStatus? stat;
    if (status != null) {
      var ss = status!;
      var shiftedLine = ss.LineStart + lineNr;

      stat = InputStatus(
          FileName: ss.FileName,
          LineStart: shiftedLine,
          LineEnd: shiftedLine,
          ColStart: 1,
          ColEnd: lines[lineNr].length);
    }
    return PuzzleParseException(stat, "Fehler beim Einlesen des Puzzles: $msg");
  }
}
