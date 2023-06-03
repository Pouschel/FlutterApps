// ignore_for_file: camel_case_types

import 'dart:collection';
import 'package:eleu/ast/ast_stmt.dart';
import 'package:eleu/interpret/instructions.dart';
import 'package:hati/hati.dart';
import 'package:intl/intl.dart';

import 'eleu.dart';
import 'interpret/interpreter.dart';
import 'interpret/interpreting.dart';
import 'interpret/stmt_compiler.dart';

typedef OList = List<Object>;

class NilClass {
  @override
  String toString() => "nil";
}

Object NilValue = NilClass();

abstract class ICallable {
  Object Call(Interpreter interpreter, List<Object> arguments);
  int get Arity => 0;
  String get Name => "";
}

abstract class IChunkCompilable {
  Chunk get compiledChunk;
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
  int get IntValue => DVal.floor();
  bool get IsInt => IntValue == DVal;
  @override
  String toString() {
    if (IsInt) return NumberFormat("0", "en_US").format(DVal);
    return DVal.toString();
  }

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

class OTable2 {
  final List<string> names = [];
  final List<Object> values = [];

  void Set(String name, Object val) {
    var index = names.indexOf(name);
    if (index >= 0)
      values[index] = val;
    else {
      names.add(name);
      values.add(val);
    }
  }

  Object Get(String name) {
    var index = names.indexOf(name);
    if (index < 0) return NilValue;
    return values[index];
  }

  bool ContainsKey(String key) => names.contains(key);
}

class NativeFunction implements ICallable {
  final NativeFn function;
  final String name;

  NativeFunction(this.name, this.function);

  @override
  int get Arity => -1;

  @override
  String get Name => name;

  @override
  Object Call(Interpreter interpreter, List<Object> arguments) {
    return function(arguments);
  }

  @override
  String toString() => "<native function>";
}

class EleuFunction implements ICallable, IChunkCompilable {
  final FunctionStmt declaration;
  final EleuEnvironment closure;
  final bool isInitializer;
  Chunk? _chunk;

  EleuFunction(this.declaration, this.closure, this.isInitializer);

  @override
  int get Arity => declaration.Paras.length;
  @override
  String get Name => declaration.Name;

  @override
  Object Call(Interpreter interpreter, List<Object> arguments) {
    var environment = EleuEnvironment(closure);
    for (int i = 0; i < declaration.Paras.length; i++) {
      environment.Define(declaration.Paras[i].StringValue, arguments[i]);
    }
    var retVal = interpreter.ExecuteBlock(declaration.Body, environment).Value;
    if (isInitializer) return closure.GetAt("this", 0);
    return retVal;
  }

  @override
  String toString() => "<function ${declaration.Name}>";

  EleuFunction bind(EleuInstance instance, bool copyInstructions) {
    var environment = EleuEnvironment(closure);
    environment.Define("this", instance);
    var func = EleuFunction(declaration, environment, isInitializer);
    if (copyInstructions) func._chunk = this.compiledChunk;
    return func;
  }

  @override
  Chunk get compiledChunk {
    if (_chunk == null) {
      var compiler = StmtCompiler();
      compiler.isInitializer = this.isInitializer;
      var chunk = compiler.compile(declaration.Body);
      if (!isInitializer)
        chunk.add(PushInstruction(NilValue, null));
      else
        chunk.add(LookupVarInstruction("this", 1, null));
      _chunk = chunk;
    }
    return _chunk!;
  }
}

class EleuClass implements ICallable {
  final String _name;
  @override
  String get Name => _name;
  OTable Methods = OTable();
  EleuClass? Superclass;

  EleuClass(this._name, this.Superclass);

  @override
  int get Arity {
    var initializer = FindMethod("init");
    if (initializer is! EleuFunction) return 0;
    return initializer.Arity;
  }

  @override
  Object Call(Interpreter interpreter, OList arguments) {
    var instance = EleuInstance(this);
    var initializer = FindMethod("init");
    if (initializer is EleuFunction) {
      initializer.bind(instance, false).Call(interpreter, arguments);
    }
    return instance;
  }

  Object FindMethod(String name) {
    var mth = Methods.Get(name);
    if (mth != NilValue) return mth;
    if (Superclass != null) {
      return Superclass!.FindMethod(name);
    }
    return NilValue;
  }

  @override
  String toString() => Name;
}

class EleuInstance {
  final EleuClass klass;
  final OTable fields = OTable();

  EleuInstance(this.klass);

  object Get(string name, bool bindInstructions) {
    var val = fields.Get(name);
    if (val == NilValue) {
      var method = klass.FindMethod(name);
      if (method == NilValue) throw EleuRuntimeError(null, "Undefined property '$name'.");
      var func = method as EleuFunction;
      return func.bind(this, bindInstructions);
    }
    return val;
  }

  void Set(string name, object value) => fields.Set(name, value);

  @override
  string toString() => "${klass.Name} instance";
}
