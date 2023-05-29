import 'dart:math';

import 'parser.dart';
import 'types.dart';
import 'package:hati/hati.dart';

typedef GridType = List<List<FieldState>>;

class Puzzle {
  GridType Grid = [[]];
  List<string> funcs = [];

  /// Index in bundle.
  int BundleIndex = 0;
  int get RowCount => Grid.length;
  int get ColCount => Grid.isEmpty ? 0 : Grid[0].length;
  Cat cat = Cat();
  int EnergyUsed = 0;
  int ReadCount = 0;
  string Name = "";
  string Description = "";
  string WinCond = "";
  int Complexity = 1000;
  string ImageNameHint = "";
  late PuzzleBundle Bundle;
  Map<string, object> Defs = {};

  Puzzle(this.Bundle);

  FieldState get(int row, int col) {
    if (row < 0 || row >= RowCount || col < 0 || col >= ColCount)
      return FieldState.RedWall;
    return Grid[row][col];
  }

  void set(int row, int col, FieldState value) {
    Grid[row][col] = value;
  }

//	public ref FieldState GetRefAt(int row, int col) => ref Grid[row, col];
  void SetFuncs(string s) => funcs = s.split(' ');
  void SetGrid(GridType grid) => this.Grid = grid;
  bool IsFuncAllowed(string funcName) {
    if (funcs.isEmpty) return true;
    if (funcName.isNotEmpty && funcName[0] == '_') return true;
    return funcs.contains(funcName);
  }

  string GetAllowedFuncString(string seperator) => funcs.join(seperator);
  Puzzle Copy() {
    var copy = Puzzle(Bundle);

    for (var el in Grid) {
      List<FieldState> l = [];
      copy.Grid.add(l);
      for (var el1 in el) {
        l.add(el1.Copy());
      }
    }
    copy
      ..BundleIndex = BundleIndex
      ..EnergyUsed = EnergyUsed
      ..ReadCount = ReadCount
      ..Name = Name
      ..Description = Description
      ..WinCond = WinCond
      ..Complexity = Complexity
      ..ImageNameHint = ImageNameHint
      ..cat = this.cat.Copy()
      ..Defs.addAll(Defs);
    return copy;
  }

  bool IsCatAt(int x, int y) => cat.Row == y && cat.Col == x;

  FieldState get FieldInFrontOfCat {
    var (x, y) = cat.FieldInFront;
    return get(y, x);
  }

  bool? CheckSingleCondition(string wc) {
    var args = wc.splitAndRemoveEmpty(' ');
    if (args.isEmpty) return true;
    try {
      switch (args[0]) {
        case "True":
          return true;
        case "CatAt":
          {
            int x = int.parse(args[1]);
            int y = int.parse(args[2]);
            return IsCatAt(x, y);
          }
        case "Val":
          {
            int x = int.parse(args[1]);
            int y = int.parse(args[2]);
            var cell = get(y, x);
            var cmp = args[3];
            if (cmp.startsWith("'")) {
              var o = Defs[cmp.substring(1)];
              cmp = o?.toString() ?? "";
              if (cmp.startsWith("'")) cmp = cmp.substring(1);
            }
            return cell.SVal == cmp;
          }
        case "MiceInBowls":
          return CheckAllCells((cell) =>
              cell.Object != FieldObjects.Mouse && cell.Object != FieldObjects.Bowl);
        case "Pat": //Pattern
          {
            int x = int.parse(args[1]);
            int y = int.parse(args[2]);
            int nx = int.parse(args[3]);
            int ny = int.parse(args[4]);
            var s = args[5];
            for (int iy = 0; iy < ny; iy++) {
              for (int ix = 0; ix < nx; ix++) {
                var c = s[iy * nx + ix];
                var fs = FieldState();
                PuzzleParser.ParseItem(fs, Defs[c] as string);
                var gval = get(y + iy, x + ix);
                if (fs.Color != gval.Color ||
                    fs.Shape != gval.Shape ||
                    gval.SVal != fs.SVal) return false;
              }
            }
            return true;
          }
        case "CC":
        case "ColorCount": // Farbenanzahl
          {
            var col = ParseShapeColor(args[1], true);
            var shape = ParseFieldShape(args[2], true);
            int count = int.parse(args[3]);
            int sum = 0;
            CheckAllCells((cell) {
              if (cell.Color == col && cell.Shape == shape) sum++;
              return true;
            });
            return sum == count;
          }
        case "Nums": // Zahlenbelegung
          {
            int x = 0, y = 0;
            for (int i = 1; i < args.length; i += 3) {
              x = EvalNumString(args[i], x);
              y = EvalNumString(args[i + 1], y);
              int n = int.parse(args[i + 2]);
              var cell = get(y, x);
              if (cell.Num != n) return false;
            }
            return true;
          }
        case "Max":
          {
            int maxVal = 1 << 52;
            return CheckCellMath(args, (n) => maxVal = max(n, maxVal), () => maxVal);
          }
        case "Sum":
          {
            int sum = 0;
            return CheckCellMath(args, (n) => sum += n, () => sum);
          }
        case "MinReadCount": // Minimale Anzahl von Leseoperationen
          int mrc = int.parse(args[1]);
          return this.ReadCount >= mrc;
      }
      // ignore: empty_catches
    } on Exception {}
    return null;
  }

  bool CheckCellMath(
      List<string> args, void Function(int) numberAction, int Function() resultFunc) {
    int idx = 1;
    int c0 = int.parse(args[idx++]);
    int r0 = int.parse(args[idx++]);
    int c1 = int.parse(args[idx++]);
    int r1 = int.parse(args[idx++]);
    int dx = int.parse(args[idx++]);
    int dy = int.parse(args[idx++]);
    var resval = get(dy, dx).Num;
    if (resval is! int) return false;

    for (int iy = r0; iy <= r1; iy++) {
      for (int ix = c0; ix <= c1; ix++) {
        var num = get(dy, dx).Num;
        if (num == null) return false;
        numberAction(num);
      }
    }
    return resval == resultFunc();
  }

  static int EvalNumString(string s, int val) {
    if (s == ".") return val;
    if (s == "+") {
      val++;
      return val;
    }
    if (s == "-") {
      val--;
      return val;
    }
    val = int.parse(s);
    return val;
  }

  bool CheckAllCells(bool Function(FieldState) cellFunc) {
    for (int iy = 0; iy < RowCount; iy++) {
      for (int ix = 0; ix < ColCount; ix++) {
        if (!cellFunc(get(iy, ix))) return false;
      }
    }
    return true;
  }

  bool? CheckWin() {
    if (WinCond.isEmpty) return null;
    var parts = WinCond.splitAndRemoveEmpty(',');
    for (var wc in parts) {
      var b = CheckSingleCondition(wc);
      if (b == null || b == false) return b;
    }
    return true;
  }
}
