import 'dart:math';
import 'dart:convert';
import 'package:archive/archive.dart';

import '../types.dart';

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
    if (SVal != null) {
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
}

extension on FieldObjects {
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

extension on Directions {
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

	// string EncodePuzzle(string text)
	// {
	// 	var s = FileUtils.CompressBase64(text);
	// 	const int split = 44;
	// 	var sb = StringBuffer();
	// 	s = EncodingStart + s;
	// 	while (s.Length > 0)
	// 	{
	// 		var n = min(split, s.Length);
	// 		sb.write(s[..n]);
	// 		s = s[n..];
	// 		while (s.StartsWith('+'))
	// 		{
	// 			sb.Append('+');
	// 			s = s[1..];
	// 		}
	// 		sb.AppendLine();
	// 	}
	// 	return sb.ToString();
	// }

	string getRawPuzzleCode(string code)
  {
		code = code.trim();
		if (code.startsWith(EncodingStart))
		{
			code = code.substring(EncodingStart.length);
			code = code.replaceAll("\r", "");
			code = code.replaceAll("\n", "");
			code = code.trim();
			code = DecompressBase64(code);
		}
    return code;
  }

  // PuzzleBundle ParseBundle(string code)
	// {
	// 	code=getRawPuzzleCode(code);
  //   var puzParser = PuzzleParser(code, null);
	// 	return puzParser.Parse();
	// }