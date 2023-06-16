import 'dart:convert';
import 'dart:math';
import 'package:archive/archive.dart';
import 'package:hati/hati.dart';

import '../eleu.dart';
import '../scanning.dart';
import 'parser.dart';
import 'puzzle.dart';

enum ShapeColors {
  None,
  Blue,
  Green,
  Red,
  Yellow,
  Cyan,
  Magenta,
  Black,
}

enum FieldShapes {
  None,
  Square,
  Circle,
  Diamond,
}

enum FieldObjects {
  None,
  Wall,
  Mouse,
  Bowl,
  BowlWithMouse,
}

enum Directions {
  E,
  N,
  W,
  S,
}

extension DirectionsExtension on Directions {
  (int dx, int dy) GetOffsetForDirection() {
    int dx = 0, dy = 0;
    switch (this) {
      case Directions.E:
        dx = 1;
        break;
      case Directions.N:
        dy = -1;
        break;
      case Directions.W:
        dx = -1;
        break;
      case Directions.S:
        dy = 1;
        break;
    }
    return (dx, dy);
  }
}

enum Turns {
  Left,
  Around,
  Right,
}

class FieldState {
  ShapeColors Color = ShapeColors.None;
  FieldShapes Shape = FieldShapes.None;
  FieldObjects Object = FieldObjects.None;
  string SVal = "";
  // Zahl auf dem Feld
  int? get Num {
    if (SVal.isEmpty) return null;
    var ival = int.tryParse(SVal);
    return ival;
  }

  void FixColor() {
    if (Color == ShapeColors.None) return;
    if (Object != FieldObjects.None || Shape != FieldShapes.None || SVal.isNotEmpty)
      return;
    // put a square on the field, so that it ist visible
    Shape = FieldShapes.Square;
  }

  @override
  string toString() {
    var sb = StringBuffer();
    if (Object != FieldObjects.None) sb.write(Object);
    if (SVal.isNotEmpty) {
      if (sb.length > 0) sb.write(", ");
      sb.write(SVal);
    }
    if (Shape != FieldShapes.None) {
      if (sb.length > 0) sb.write(", ");
      sb.write("${Color} ${Shape}");
    }
    if (sb.length == 0) return "Empty";
    return sb.toString();
  }

  static FieldState RedWall = FieldState()
    ..Color = ShapeColors.Red
    ..Object = FieldObjects.Wall;

  FieldState Copy() => FieldState()
    ..Color = Color
    ..Shape = Shape
    ..Object = Object
    ..SVal = SVal;

  Map<string, dynamic> toJson() => {
        'color': Color.toShortString(),
        'shape': Shape.toShortString(),
        'sval': SVal,
        'object': Object.toShortString(),
      };
}

class Cat {
  int Row = 0, Col = 0;
  Directions LookAt = Directions.E;
  FieldObjects Carrying = FieldObjects.None;

  Cat Copy() => Cat()
    ..Row = Row
    ..Col = Col
    ..LookAt = LookAt
    ..Carrying = Carrying;

  @override
  string toString() => "(${Col}|${Row})->${LookAt} ${Carrying}";

  (int x, int y) get FieldInFront {
    var (dx, dy) = this.LookAt.GetOffsetForDirection();
    return (this.Col + dx, this.Row + dy);
  }

  toJson() {}
}

extension FieldObjectExtension on FieldObjects {
  string GetObjectName() {
    switch (this) {
      case FieldObjects.None:
        return "leeres Feld";
      case FieldObjects.Bowl:
        return "Napf";
      case FieldObjects.Mouse:
        return "Maus";
      case FieldObjects.Wall:
        return "Wand";
      case FieldObjects.BowlWithMouse:
        return "Napf mit Maus";
      default:
        return "Unbekanntes Objekt";
    }
  }

  bool CanTake() => this == FieldObjects.Mouse;
  bool CanPush() => this == FieldObjects.Mouse;
}

string CompressBase64(string s) {
  var stringBytes = utf8.encode(s);
  var gzipBytes = GZipEncoder().encode(stringBytes);
  var compressedString = base64.encode(gzipBytes!);
  return compressedString;
}

string DecompressBase64(string s) {
  var decodedString = base64.decode(s);
  var decompressed = GZipDecoder().decodeBytes(decodedString);
  var result = utf8.decode(decompressed);
  return result;
}

const string EncodingStart = ">:)";

string EncodePuzzle(string text) {
  var s = CompressBase64(text);
  const int split = 44;
  var sb = StringBuffer();
  s = EncodingStart + s;
  while (s.isNotEmpty) {
    var n = min(split, s.length);
    sb.write(s.substring(0, n));
    s = s.substring(n);
    // avoid markdown problems showing the puzzles
    while (s.startsWith('+')) {
      sb.write('+');
      s = s.substring(1);
    }
    sb.writeln();
  }
  return sb.toString();
}

string getRawPuzzleCode(string code) {
  code = code.trim();
  if (code.startsWith(EncodingStart)) {
    code = code.substring(EncodingStart.length);
    code = code.replaceAll("\r", "");
    code = code.replaceAll("\n", "");
    code = code.trim();
    code = DecompressBase64(code);
  }
  return code;
}

class PuzzleParseException extends EleuRuntimeError {
  PuzzleParseException(InputStatus? status, string msg) : super(status, msg);
}

class PException extends EleuRuntimeError {
  PException(string msg) : super(null, msg);
}

PuzzleBundle ParseBundle(string code) {
  code = getRawPuzzleCode(code);
  var puzParser = PuzzleParser(code, null);
  return puzParser.Parse();
}

T? enumFromString<T>(Iterable<T> values, String value, bool ignoreCase) {
  if (ignoreCase) value = value.toLowerCase();
  for (var type in values) {
    var enType = type.toString().split(".").last;
    if (ignoreCase) enType = enType.toLowerCase();
    if (enType == value) return type;
  }
  return null;
}

ShapeColors? ParseShapeColor(string s, bool ignoreCase) =>
    enumFromString(ShapeColors.values, s, ignoreCase);
FieldShapes? ParseFieldShape(string s, bool ignoreCase) =>
    enumFromString(FieldShapes.values, s, ignoreCase);
FieldObjects? ParseFieldObjects(string s, bool ignoreCase) =>
    enumFromString(FieldObjects.values, s, ignoreCase);
Directions? ParseDirections(string s, bool ignoreCase) =>
    enumFromString(Directions.values, s, ignoreCase);
Turns? ParseTurns(string s, bool ignoreCase) =>
    enumFromString(Turns.values, s, ignoreCase);

class PuzzleBundle {
  List<Puzzle> puzzles = [];
  string Code = "";
  string get Name => puzzles.isNotEmpty ? puzzles[0].Name : "";

  PuzzleBundle(this.Code);

  void AddPuzzle(Puzzle puzzle) {
    puzzle.BundleIndex = puzzles.length;
    puzzles.add(puzzle);
  }

  int get Count => puzzles.length;

  void SetImageNameHints(string eleuName) {
    if (puzzles.isEmpty) return;
    var fn = eleuName; // FileUtils.GetFullNameWithoutExtension(eleuName);
    puzzles[0].ImageNameHint = "$fn.png";
    for (int i = 1; i < puzzles.length; i++) {
      var puz = puzzles[i];
      puz.ImageNameHint = "${fn}_${i + 1}.png";
    }
  }

  Puzzle operator [](int index) => puzzles[index];
}
