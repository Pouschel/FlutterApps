import '../native.dart';
import '../eleu.dart';
import '../types.dart';

const Object NilValue = Object();

String Stringify(Object val) => StringifyString(val, false);

String StringifyString(Object val, bool quotationMarks) {
  switch (val) {
    case bool b:
      return b ? "true" : "false";
    case double d:
      return d.toString();
    case String s:
      return quotationMarks ? "\"$s\"" : s;
    default:
      return val == NilValue ? "nil" : val.toString();
  }
}

bool IsFalsey(Object value) => !IsTruthy(value);
bool IsTruthy(Object value) {
  if (value is bool) return value;
  throw EleuRuntimeError(null, "${value} ist nicht vom typ boolean");
}

bool ObjEquals(Object a, Object b) {
  if (a == b) return true;
  // if (a is Number  && b is Number ) return da.Equals(db);
  // if (a.Equals(b)) return true;
  return false;
}

int InternalCompare(Object a, Object b) {
  if (ObjEquals(a, b)) return 0;
  if (a is String && b is String) return a.compareTo(b);
  if (a is Number && b is Number) return a.CompareTo(b);
  throw EleuRuntimeError(
      null, "Unterschiedliche Datentypen können nicht verglichen werden.");
}

Number NumberOp(String op, Object a, Object b, double Function(double, double) func) {
  if (a is! Number || b is! Number) {
    throw EleuRuntimeError(null, "Beide Operanden müssen Zahlen sein.");
  }
  var result = func(a.DVal, b.DVal);
  if (result.isInfinite)
    throw EleuNativeError(
        "Das Ergebnis von '${a} {op} ${b}' ist zu groß (oder klein) für den unterstützten Zahlentyp.");
  if (!result.isFinite)
    throw EleuNativeError("Das Ergebnis von '${a} ${op} ${b}' ist nicht definiert.");
  return Number(result);
}

Number NumSubtract(Object lhs, Object rhs) => NumberOp("-", lhs, rhs, (a, b) => a - b);
Object NumStrAdd(Object a0, Object a1) {
  var a0Num = a0 is Number;
  var a1Num = a1 is Number;
  if (a0Num && a1Num) {
    Number a = a0;
    Number b = a1;
    return a + b;
  }
  var s0 = a0 is String ? a0 : (a0Num ? (a0).toString() : null);
  var s1 = a1 is String ? a1 : (a1Num ? (a1).toString() : null);
  if (s0 == null || s1 == null)
    throw EleuRuntimeError(null,
        "Die Operation '${StringifyString(a0, true)} + ${StringifyString(a1, true)}' ist ungültig.");
  return s0 + s1;
}

enum InterpretStatus {
  Normal,
  Break,
  Continue,
  Return,
}

class InterpretResult {
  final Object Value;
  final InterpretStatus Stat;

  InterpretResult(this.Value, this.Stat);

  static final InterpretResult NilResult =
      InterpretResult(NilValue, InterpretStatus.Normal);
  static final InterpretResult BreakResult =
      InterpretResult(NilValue, InterpretStatus.Break);
  static final InterpretResult ContinueResult =
      InterpretResult(NilValue, InterpretStatus.Continue);

  @override
  String toString() => "${Stat}: ${Stringify(Value)}";
}
