import 'dart:collection';
import 'eleu.dart';
import 'interpret/interpreter.dart';

const Object NilValue = Object();

abstract class ICallable {
  Object Call(Interpreter interpreter, List<Object> arguments);
  int get Arity => 0;
  String get Name => "";
}

class Number {
  double DVal = 0;

  Number(double d) {
    assert(d.isFinite);
    this.DVal = d;
  }
  static Number? TryParse(String s) {
    var d = double.tryParse(s);
    if (d == null) return null;
    return Number(d);
  }

  // internal Number(long l) { this.DVal = l; }
  // public bool IsDefined => double.IsFinite(DVal);
  // public bool IsZero => DVal == 0;
  int get IntValue => (DVal - 0.5).round();
  bool get IsInt => IntValue == DVal;
  @override
  String toString() => DVal.toString();
  @override
  bool operator ==(Object other) {
    if (other is Number) DVal == other.DVal;
    return false;
  }

  @override
  int get hashCode => DVal.hashCode;

  static int Cmp(Number a, Number b) => a.DVal.compareTo(b.DVal);
  int CompareTo(Number other) => Cmp(this, other);

  Number operator +(Number a) => Number(this.DVal + a.DVal);
  Number operator -(Number a) => Number(this.DVal - a.DVal);
  Number operator -() => Number(-this.DVal);
  Number operator *(Number b) => Number(this.DVal * b.DVal);
  Number operator /(Number b) => Number(this.DVal / b.DVal);
  Number operator %(Number b) => Number(this.DVal % b.DVal);
}

class OTable {
  final Map<String, Object> _map = HashMap();

  void Set(String name, Object val) => _map[name] = val;

  Object Get(String name) {
    var val = _map[name];
    if (val == null) return NilValue;
    return val;
  }

  bool ContainsKey(String key) => _map.containsKey(key);
}

class NativeFunction implements ICallable {
  final NativeFn function;
  final String name;

  NativeFunction(this.name, this.function);

  @override
  int get Arity => -1; //todo function.Method.GetParameters().Length - 1;

  @override
  String get Name => name;

  @override
  Object Call(Interpreter interpreter, List<Object> arguments) {
    return function(arguments);
  }

  @override
  String toString() => "<native function>";
}
