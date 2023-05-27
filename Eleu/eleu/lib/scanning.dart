import 'dart:math';

class InputStatus {
  String FileName = "";

  int LineStart = 1, LineEnd = 1;

  int ColStart = 1, ColEnd = 1;

  InputStatus({
    this.FileName = "",
    this.LineStart = 1,
    this.LineEnd = 1,
    this.ColStart = 1,
    this.ColEnd = 1,
  });

  bool get IsEmpty {
    return LineStart == LineEnd && ColStart == ColEnd;
  }

  void NextLine() {
    this.LineStart++;
    this.LineEnd++;
    this.ColStart = this.ColEnd = 1;
  }

  void NextChar() {
    this.ColStart++;
    this.ColEnd++;
  }

  InputStatus Union(InputStatus other) {
    var result = this;
    if (result.FileName != this.FileName) return InputStatus();
    if (other.LineStart < this.LineStart) {
      result.LineStart = other.LineStart;
      result.ColStart = other.ColStart;
    } else if (other.LineStart == this.LineStart) result.ColStart = min(this.ColStart, other.ColStart);
    if (other.LineEnd > this.LineEnd) {
      result.LineEnd = other.LineEnd;
      result.ColEnd = other.ColEnd;
    } else if (other.LineEnd == this.LineEnd) result.ColEnd = max(this.ColEnd, other.ColEnd);
    return result;
  }

  String get Message => "${FileName}(${LineStart},${ColStart},${LineEnd},${ColEnd})";

  String ToString() => Message;

  // String ReadPartialText()
  // {
  // 	var lines= File.ReadAllLines(FileName);
  // 	var sb = new StringBuilder();
  // 	for (int i = LineStart; i <= LineEnd; i++)
  // 	{
  // 		if (i <= 0 || i > lines.Length) continue;
  // 		var line = lines[i-1];
  // 		if (LineStart == LineEnd)
  // 			sb.Append(line[(ColStart - 1)..(ColEnd - ColStart +1)]);
  // 		else if (i == LineStart)
  // 			sb.Append(lines[(ColStart - 1)..]);
  // 		else if (i == LineEnd)
  // 			sb.Append(lines[..(ColEnd -1)]);
  // 		else
  // 			sb.AppendLine(line);
  // 	}
  // 	return sb.ToString();
  // }

  static final InputStatus Empty = InputStatus();

  static InputStatus Parse(String hint) {
    int idx = hint.indexOf("): ");
    if (idx < 0) return Empty;
    int idx0 = hint.lastIndexOf('(', idx);
    if (idx0 < 0) return Empty;
    var fileName = hint.substring(0, idx0);
    var numbers = hint.substring((idx0 + 1), idx).split(',').map((s) => int.parse(s)).toList();
    return InputStatus(
      FileName: fileName,
      LineStart: numbers[0],
      ColStart: numbers[1],
      LineEnd: numbers[2],
      ColEnd: numbers[3],
    );
  }
}
