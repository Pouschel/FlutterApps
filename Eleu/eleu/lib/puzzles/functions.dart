
import 'package:hati/hati.dart';

import '../Native.dart';
import '../eleu.dart';
import '../interpret/interpreting.dart';
import '../types.dart';
import 'parser.dart';
import 'puzzle.dart';
import 'types.dart';

class PuzzleFunctions extends NativeFunctionBase {
  late Map funcMap = {
    "move": move,
    "_puzzle": _puzzle,
    "_isSolved": _isSolved,
    "push": push,
    "take": take,
    "drop": drop,
    "turn": turn,
    "paint": paint,
    "setShape": setShape,
    "color": color,
    "seeing": seeing,
    "read": read,
    "readNumber": readNumber,
    "write": write,
    "_energyUsed": _energyUsed
  };

  int get FrameTime => Vm.FrameTimeMs;

  void Animate(Puzzle puzzle) {
//		Stopwatch watch = Stopwatch.StartNew();
    puzzle = puzzle.Copy();
    // const int steps = 10;
    // int aniTime = FrameTime / steps;
    // if (FrameTime > 0)
    // {
    // 	for (int i = 1; i < steps; i++)
    // 	{
    // 		Vm.NotifyPuzzleChange(puzzle, (float)i / steps);
    // 		int remainingTime = FrameTime - (steps - i) * aniTime - (int)watch.ElapsedMilliseconds;
    // 		if (remainingTime > 5)
    // 			Thread.Sleep(remainingTime);
    // 	}
    // }
    Vm.NotifyPuzzleChange(puzzle);
  }

  Puzzle CheckPuzzleActive(string name) {
    var puz = Vm.puzzle;
    if (puz == null)
      throw PException(
          "Die Funktion '${name}' kann nur bei einem aktivem Puzzle verwendet werden.");
    if (!puz.IsFuncAllowed(name))
      throw PException(
          "Die Funktion '${name}' darf bei diesem Puzzle nicht verwendet werden.");
    return puz;
  }

  Directions CheckDirection(string s) {
    var edir = ParseDirections(s, true);
    if (edir == null) throw PException("'${s}' ist keine gültige Richtung");
    return edir;
  }

  object _puzzle(OList args) {
    var s = CheckArgType<string>(0, args, "_puzzle","string");
    int index = 0;
    if (args.length >= 2) index = CheckIntArg(1, args);
    var puzParser = PuzzleParser(s, Vm.currentStatus);
    var bundle = puzParser.Parse();
    if (index >= bundle.Count || index < 0)
      throw PException("Der Test ${index + 1} ist nicht vorhanden.");

    var fn = Vm.currentStatus.FileName;
    if (fn.isNotEmpty) bundle.SetImageNameHints(fn);
    var puzzle = Vm.puzzle = bundle[index].Copy();
    Vm.NotifyPuzzleChange(puzzle);
    puzzle.ImageNameHint = "";
    Animate(puzzle);
    return true;
  }

  object _isSolved(OList _) {
    var puzzle = CheckPuzzleActive("_isSolved");
    bool? b = puzzle.CheckWin();
    if (b == null) return NilValue;
    return b;
  }

  void CheckObstacle(FieldState field) {
    bool obst = false;
    if (field.Object == FieldObjects.Wall) obst = true;
    if (obst)
      throw PException(
          "Die Katze ist gegen ein Hindernis gelaufen (${field.Object.GetObjectName()}).");
  }

  void moveDir(Directions dir, int dist, string funcname) {
    var puzzle = CheckPuzzleActive(funcname);
    var (dx, dy) = dir.GetOffsetForDirection();
    if (dist < 0) {
      dx = -dx;
      dy = -dy;
      dist = -dist;
    }
    var cat = puzzle.cat;
    var col = cat.Col;
    var row = cat.Row;
    for (int i = 1; i <= dist; i++) {
      col += dx;
      row += dy;
      var field = puzzle.get(row, col);
      CheckObstacle(field);
      cat.Row = row;
      cat.Col = col;
      Animate(puzzle);
    }
  }

  object move(OList args) {
    var puzzle = CheckPuzzleActive("move");
    var edir = puzzle.cat.LookAt;
    if (args.isNotEmpty) {
      var dir = CheckArgType<string>(0, args, "move","string");
      edir = CheckDirection(dir);
    }
    var (dx, dy) = edir.GetOffsetForDirection();
    var cat = puzzle.cat;
    var row = cat.Row;
    var col = cat.Col;
    col += dx;
    row += dy;
    var field = puzzle.get(row, col);
    CheckObstacle(field);
    cat.Row = row;
    cat.Col = col;
    var e = 0;
    var delta = (cat.LookAt.index - edir.index).abs();
    switch (delta) {
      case 0:
        e = 1;
        break;
      case 1:
      case 3:
        e = 2;
        break;
      case 2:
        e = 4;
        break;
    }
    int add = 0;
    if (cat.Carrying != FieldObjects.None) add += delta == 0 ? 1 : 2;
    puzzle.EnergyUsed += e + add;
    Animate(puzzle);
    return NilValue;
  }

  object push(OList a) {
    CheckArgLen(a, 0, "push");
    var puzzle = CheckPuzzleActive("push");
    var cat = puzzle.cat;
    var edir = cat.LookAt;
    var (dx, dy) = edir.GetOffsetForDirection();
    var x = cat.Col + dx;
    var y = cat.Row + dy;
    var cell = puzzle.get(y, x);
    if (cell.Object == FieldObjects.None) return move(a);
    if (!cell.Object.CanPush())
      throw PException(
          "Das Objekt (${cell.Object.GetObjectName()}) kann nicht verschoben werden.");
    int ox = x + dx, oy = y + dy;
    var cellDest = puzzle.get(oy, ox);
    if (!(cellDest.Object == FieldObjects.None || cellDest.Object == FieldObjects.Bowl))
      throw PException(
          "Das Objekt kann nur in einen Napf oder auf ein leeres Feld geschoben werden.");
    cellDest.Object =
        cellDest.Object == FieldObjects.Bowl ? FieldObjects.BowlWithMouse : cell.Object;
    cell.Object = FieldObjects.None;
    cat.Col = x;
    cat.Row = y;
    puzzle.set(oy, ox, cellDest);
    puzzle.set(y, x, cell);
    puzzle.EnergyUsed += cat.Carrying == FieldObjects.None ? 6 : 8;
    Animate(puzzle);
    return NilValue;
  }

  object take(OList a) {
    CheckArgLen(a, 0, "take");
    var puzzle = CheckPuzzleActive("take");
    var cat = puzzle.cat;
    var (x, y) = cat.FieldInFront;
    var fstate = puzzle.get(y, x);
    if (cat.Carrying != FieldObjects.None)
      throw PException(
          "Die Katze trägt bereits ein Objekt (${fstate.Object.GetObjectName()}).");
    if (!fstate.Object.CanTake())
      throw PException(
          "Die Katze kann das Objekt (${fstate.Object.GetObjectName()}) nicht aufnehmen.");
    cat.Carrying = fstate.Object;
    fstate.Object = FieldObjects.None;
    puzzle.set(y, x, fstate);
    puzzle.EnergyUsed += 5;
    Animate(puzzle);
    return NilValue;
  }

  object drop(OList a) {
    CheckArgLen(a, 0, "drop");
    var puzzle = CheckPuzzleActive("drop");
    var cat = puzzle.cat;
    var (x, y) = cat.FieldInFront;
    var fstate = puzzle.get(y, x);
    if (cat.Carrying == FieldObjects.None)
      throw PException("Die Katze kann nichts ablegen, da sie kein Objekt trägt.");
    if (cat.Carrying != FieldObjects.Mouse)
      throw PException("Die Katze sollte eine Maus tragen!");
    switch (fstate.Object) {
      case FieldObjects.Bowl:
        fstate.Object = FieldObjects.BowlWithMouse;
        break;
      case FieldObjects.None:
        fstate.Object = cat.Carrying;
        break;
      default:
        throw PException(
            "Die Katze kann das Objekt (${cat.Carrying.GetObjectName()}) hier nicht ablegen.");
    }
    cat.Carrying = FieldObjects.None;
    puzzle.set(y, x, fstate);
    puzzle.EnergyUsed += 2;
    Animate(puzzle);
    return NilValue;
  }

  object turn(OList args) {
    var puzzle = CheckPuzzleActive("turn");
    var sdir = CheckArgType<string>(0, args, "turn","string");
    var turnDir = ParseTurns(sdir, true);
    if (turnDir == null) throw PException("'${sdir}' ist keine gültige Drehrichtung");
    var cat = puzzle.cat;
    int add = turnDir.index + 1 + cat.LookAt.index;
    add %= 4;
    cat.LookAt = Directions.values[add];
    puzzle.EnergyUsed += cat.Carrying != FieldObjects.None ? 2 : 1;
    Animate(puzzle);
    return cat.LookAt.toString();
  }

  void SetColor(Puzzle puzzle, string sdir) {
    var color = ParseShapeColor(sdir, true);
    if (color == null) throw PException("'${sdir}' ist keine gültige Farbe");
    var cat = puzzle.cat;
    var cell = puzzle.get(cat.Row, cat.Col);
    if (cell.Shape == FieldShapes.None && color != ShapeColors.None)
      throw PException("Das Feld (${cat.Col}|{cat.Row}) enthält kein Muster.");
    cell.Color = color;
  }

  void SetShape(Puzzle puzzle, string sShape) {
    var shape = ParseFieldShape(sShape, true);
    if (shape == null) throw PException("'${sShape}' ist kein gültiges Muster");
    var cat = puzzle.cat;
    var cell = puzzle.get(cat.Row, cat.Col);
    cell.Shape = shape;
    if (shape == FieldShapes.None) cell.Color = ShapeColors.None;
  }

  object paint(OList args) {
    var puzzle = CheckPuzzleActive("paint");
    var sdir = CheckArgType<string>(0, args, "paint","string");
    SetColor(puzzle, sdir);
    int add = puzzle.cat.Carrying != FieldObjects.None ? 2 : 1;
    puzzle.EnergyUsed += add;
    Animate(puzzle);
    return NilValue;
  }

  object setShape(OList args) {
    var puzzle = CheckPuzzleActive("setShape");
    var sColor = CheckArgType<string>(0, args, "setShape","string");
    var sShape = FieldShapes.Square.toString();
    if (args.length > 1) sShape = CheckArgType<string>(1, args, "setShape","string");
    SetShape(puzzle, sShape);
    SetColor(puzzle, sColor);
    int add = puzzle.cat.Carrying != FieldObjects.None ? 4 : 2;
    puzzle.EnergyUsed += add;
    Animate(puzzle);
    return NilValue;
  }

  object color(OList _) {
    CheckArgLen(_, 0, "color");
    var puzzle = CheckPuzzleActive("color");
    var cat = puzzle.cat;
    var cell = puzzle.get(cat.Row, cat.Col);
    puzzle.EnergyUsed++;
    return cell.Color.toShortString();
  }

  object seeing(OList _) {
    CheckArgLen(_, 0, "seeing");
    var puzzle = CheckPuzzleActive("seeing");
    var cell = puzzle.FieldInFrontOfCat;
    puzzle.EnergyUsed++;
    return cell.Object.toShortString();
  }

  object read(OList _) {
    CheckArgLen(_, 0, "read");
    var puzzle = CheckPuzzleActive("read");
    var cell = puzzle.FieldInFrontOfCat;
    puzzle.EnergyUsed++;
    puzzle.ReadCount++;
    if (cell.Object != FieldObjects.Wall) {
      Animate(puzzle);
      return cell.SVal;
    }
    var (x, y) = puzzle.cat.FieldInFront;
    throw EleuNativeError(
        "Das Feld mit den Koordinaten (${x}|${y}) enthält keinen Text.");
  }

  object readNumber(OList _) {
    CheckArgLen(_, 0, "readNumber");
    var puzzle = CheckPuzzleActive("read");
    var res = read(_) as string;
    var (x, y) = puzzle.cat.FieldInFront;
    var num = Number.TryParse(res);
    if (num == null)
      throw EleuNativeError(
          "Der Inhalt der Feldes (${x}|${y}): '${res}' kann nicht in eine Zahl umgewandelt werden.");
    return num;
  }

  object write(OList args) {
    CheckArgLen(args, 1, "write");
    var puzzle = CheckPuzzleActive("write");
    var (x, y) = puzzle.cat.FieldInFront;
    var cell = puzzle.get(y, x);
    if (cell.Object == FieldObjects.Wall)
      throw PException("Mauern können nicht beschriftet werden!");
    var wcell = puzzle.get(y, x);
    string sval = "";
    if (args[0] != NilValue) sval = Stringify(args[0]);
    puzzle.EnergyUsed += sval.isEmpty ? 1 : 2;
    wcell.SVal = sval;
    Animate(puzzle);
    return NilValue;
  }

  object _energyUsed(OList _) {
    var puzzle = CheckPuzzleActive("_energyUsed");
    return Number(puzzle.EnergyUsed.toDouble());
  }

  static void DefineAll(IInterpreter vm) {
    var funcClass = PuzzleFunctions();
    funcClass.vm = vm;
    funcClass.funcMap.forEach((name, value) {
      vm.DefineNative(name, value);
    });
  }
}
