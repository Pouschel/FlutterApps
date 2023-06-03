import 'package:eleu/interpret/stmt_compiler.dart';
import 'package:hati/hati.dart';

import '../ast/ast_stmt.dart';
import '../eleu.dart';
import '../scanning.dart';
import '../types.dart';
import 'interpreter.dart';
import 'interpreting.dart';

class CallFrame {
  int ip = 0;
  Chunk chunk;
  ICallable? func;
  CallFrame? next;

  CallFrame(this.chunk, {this.func});

  Instruction? nextInstruction() {
    if (ip >= chunk.code.length) return null;
    return chunk.code[ip++];
  }
}

abstract class Instruction {
  InputStatus? status;
  void execute(Interpreter vm);

  Instruction(this.status);
}

class DefFunInstruction extends Instruction {
  FunctionStmt func;
  DefFunInstruction(this.func) : super(func.Status);

  @override
  void execute(Interpreter vm) {
    EleuFunction function = EleuFunction(func, vm.environment, false);
    vm.environment.Define(func.Name, function);
  }
}

class PushInstruction extends Instruction {
  Object value;
  PushInstruction(this.value, InputStatus? stat) : super(stat);

  @override
  void execute(Interpreter vm) {
    vm.push(value);
  }

  @override
  String toString() => "push $value";
}

class PopInstruction extends Instruction {
  PopInstruction(InputStatus stat) : super(stat);

  @override
  void execute(Interpreter vm) {
    vm.pop();
  }

  @override
  String toString() => "pop";
}

class BinaryOpInstruction extends Instruction {
  TokenType op;

  BinaryOpInstruction(this.op, InputStatus status) : super(status);

  @override
  void execute(Interpreter vm) {
    var rhs = vm.pop();
    var lhs = vm.pop();
    var result = NilValue;
    switch (op) {
      case TokenType.TokenBangEqual:
        result = !ObjEquals(lhs, rhs);
      case TokenType.TokenEqualEqual:
        result = ObjEquals(lhs, rhs);
      case TokenType.TokenGreater:
        result = InternalCompare(lhs, rhs) > 0;
      case TokenType.TokenGreaterEqual:
        result = InternalCompare(lhs, rhs) >= 0;
      case TokenType.TokenLess:
        result = InternalCompare(lhs, rhs) < 0;
      case TokenType.TokenLessEqual:
        result = InternalCompare(lhs, rhs) <= 0;
      case TokenType.TokenPlus:
        result = NumStrAdd(lhs, rhs);
      case TokenType.TokenMinus:
        result = NumSubtract(lhs, rhs);
      case TokenType.TokenStar:
        result = NumberOp("*", lhs, rhs, (a, b) => a * b);
      case TokenType.TokenPercent:
        result = NumberOp("%", lhs, rhs, (a, b) => a % b);
      case TokenType.TokenSlash:
        result = NumberOp("/", lhs, rhs, (a, b) => a / b);
      default:
        throw EleuRuntimeError(status, "Invalid op: ${op}");
    }
    vm.push(result);
  }

  @override
  String toString() => "op ${op.toShortString()}";
}

class UnaryOpInstruction extends Instruction {
  TokenType type;

  UnaryOpInstruction(this.type, InputStatus status) : super(status);
  @override
  void execute(Interpreter vm) {
    var right = vm.pop();
    switch (type) {
      case TokenType.TokenBang:
        if (right is! bool)
          throw EleuRuntimeError(status, "Operand muss vom Typ boolean sein.");
        vm.push(!IsTruthy(right));
        break;
      case TokenType.TokenMinus:
        {
          if (right is! Number)
            throw EleuRuntimeError(status, "Operand muss eine Zahl sein.");
          vm.push(-right);
        }
      default:
        throw throw EleuRuntimeError(status, "Unknown op type: ${type}"); // Unreachable.
    }
  }
}

class LogicalOpInstruction extends Instruction {
  Token op;
  LogicalOpInstruction(this.op, InputStatus status) : super(status);

  @override
  void execute(Interpreter vm) {
    var right = vm.pop();
    if (right is! bool)
      throw EleuRuntimeError(status,
          "Der Operator '${op.Type}' kann nicht auf '${right}' angewendet werden.");
    var left = vm.pop();
    if (left is! bool)
      throw EleuRuntimeError(status,
          "Der Operator '${op.Type}' kann nicht auf '${left}' angewendet werden.");
    if (op.Type == TokenType.TokenOr) {
      if (IsTruthy(left)) {
        vm.push(left);
        return;
      }
    } else {
      if (IsFalsey(left)) {
        vm.push(left);
        return;
      }
    }
    vm.push(right);
  }
}

class CallInstruction extends Instruction {
  int nArgs;
  CallInstruction(this.nArgs, InputStatus status) : super(status);

  @override
  void execute(Interpreter vm) {
    var callee = vm.pop();
    if (callee is NativeFunction) {
      executeNative(vm, callee);
      return;
    }
    if (callee is! ICallable) throw vm.Error("Can only call functions and classes.");
    var function = callee;
    if (nArgs != function.Arity)
      throw vm.Error("Expected ${function.Arity} arguments but got ${nArgs}.");
    if (callee is EleuFunction) {
      var environment = EleuEnvironment(callee.closure);
      doCall(vm, environment, callee);
      return;
    }
    if (callee is EleuClass) {
      var cls = callee;
      var instance = EleuInstance(cls);
      var initializer = cls.FindMethod("init");
      if (initializer is! EleuFunction) {
        vm.push(instance);
        return;
      }
      initializer = initializer.bind(instance, true);

      var environment = EleuEnvironment(initializer.closure);
      // environment.Define("this", instance);
      doCall(vm, environment, initializer);
      return;
    }
    throw UnsupportedError("message");
  }

  void doCall(Interpreter vm, EleuEnvironment environment, EleuFunction callee) {
    for (int i = nArgs - 1; i >= 0; i--) {
      environment.Define(callee.declaration.Paras[i].StringValue, vm.pop());
    }
    vm.enterEnv(environment);
    var frame = CallFrame(callee.compiledChunk, func: callee);
    vm.enterFrame(frame);
  }

  void executeNative(Interpreter vm, NativeFunction callee) {
    var arguments = <Object>[];
    for (int i = 0; i < nArgs; i++) {
      var argument = vm.pop();
      arguments.add(argument);
    }
    var res = callee.Call(vm, arguments.reversed.toList());
    vm.push(res);
  }

  @override
  String toString() => "call/$nArgs";
}

class LookupVarInstruction extends Instruction {
  String name;
  int distance;
  LookupVarInstruction(this.name, this.distance, InputStatus? status) : super(status);

  @override
  void execute(Interpreter vm) {
    var value = vm.LookUpVariable(name, distance);
    vm.push(value);
  }

  @override
  String toString() => "get_value '$name' at $distance";
}

class LookupInClosure extends Instruction {
  EleuEnvironment closure;
  String name;
  LookupInClosure(this.closure, this.name) : super(null);
  @override
  void execute(Interpreter vm) {
    vm.push(closure.GetAt(name, 0));
  }
}

class VarDefInstruction extends Instruction {
  String name;
  VarDefInstruction(this.name, InputStatus status) : super(status);
  @override
  void execute(Interpreter vm) {
    if (vm.environment.ContainsAtDistance0(name))
      throw EleuRuntimeError(
          status, "Mehrfache var-Anweisung: '${name}' wurde bereits deklariert!");
    var value = vm.pop();
    vm.environment.Define(name, value);
  }
}

class ScopeInstruction extends Instruction {
  bool begin;
  ScopeInstruction(this.begin) : super(null);
  @override
  void execute(Interpreter vm) {
    if (begin) {
      var env = EleuEnvironment(vm.environment);
      vm.enterEnv(env);
    } else
      vm.leaveEnv();
  }

  @override
  String toString() {
    return begin ? "enter_scope" : "leave_scope";
  }
}

enum JumpMode {
  jmp,
  jmp_true,
  jmp_false,
  jmp_le_zero,
}

class JumpInstruction extends Instruction {
  late int offset;
  JumpMode mode = JumpMode.jmp;
  int leaveScopes = 0;

  JumpInstruction(this.mode, InputStatus status) : super(status);
  @override
  void execute(Interpreter vm) {
    for (var i = 0; i < leaveScopes; i++) {
      vm.leaveEnv();
    }
    if (mode == JumpMode.jmp) {
      vm.frame.ip = offset;
      return;
    }
    var val = vm.peek();

    int? GetCount() {
      if (val is! Number) return null;
      if (!val.IsInt) return null;
      return val.IntValue;
    }

    switch (mode) {
      case JumpMode.jmp_true:
        if (!IsTruthy(val)) return;
      case JumpMode.jmp_false:
        if (!IsFalsey(val)) return;
      case JumpMode.jmp_le_zero:
        var count = GetCount();
        if (count is! int)
          throw EleuRuntimeError(status, "Es wird eine natürliche Zahl erwartet.");
        if (count > 0) return;
      default:
        throw UnsupportedError("invalid jump code");
    }
    vm.frame.ip = offset;
  }

  @override
  String toString() => "${mode.toShortString()} $offset";
}

class AssignInstruction extends Instruction {
  String name;
  int distance;

  AssignInstruction(this.name, this.distance, InputStatus status) : super(status);

  @override
  void execute(Interpreter vm) {
    var value = vm.peek();
    vm.assignAtDistance(name, distance, value);
  }

  @override
  String toString() => "assign ${name} ${distance}";
}

class ReturnInstruction extends Instruction {
  int scopeDepth = 0;
  ReturnInstruction(this.scopeDepth, InputStatus status) : super(status);
  @override
  void execute(Interpreter vm) {
    for (var i = 0; i < scopeDepth; i++) {
      vm.leaveEnv();
    }
    vm.leaveFrame();
  }
}

class AssertInstruction extends Instruction {
  AssertInstruction(InputStatus status) : super(status);

  @override
  void execute(Interpreter vm) {
    var val = vm.pop();
    if (IsFalsey(val))
      throw EleuAssertionFail(status, "Eine Annahme ist fehlgeschlagen.");
  }
}

class ClassInstruction extends Instruction {
  string clsName;
  List<FunctionStmt> methods;
  ClassInstruction(this.clsName, this.methods, InputStatus status) : super(status);

  @override
  void execute(Interpreter vm) {
    var hasSuper = vm.pop() as bool;
    EleuClass? superclass;
    if (hasSuper) {
      var superclassV = vm.pop();
      if (superclassV is! EleuClass) {
        throw vm.Error("Superclass must be a class.");
      }
      superclass = superclassV;
    }
    var klass = vm.environment.GetAtDistance0(clsName);
    if (klass is! EleuClass) {
      vm.environment.Define(clsName, NilValue);
      klass = EleuClass(clsName, superclass);
    } else {
      if (klass.Superclass != null && klass.Superclass != superclass)
        throw EleuRuntimeError(status,
            "Super class must be the same (${klass.Superclass?.Name} vs. ${superclass?.Name})");
    }
    if (superclass != null) {
      vm.environment = EleuEnvironment(vm.environment);
      vm.environment.Define("super", superclass);
    }
    for (FunctionStmt method in methods) {
      EleuFunction function = EleuFunction(method, vm.environment, method.Name == "init");
      klass.Methods.Set(method.Name, function);
    }
    var kval = klass;
    if (superclass != null) {
      vm.environment = vm.environment.enclosing!;
    }
    vm.environment.Assign(clsName, kval);
  }
}

class GetInstruction extends Instruction {
  String name;
  GetInstruction(this.name, InputStatus status) : super(status);
  @override
  void execute(Interpreter vm) {
    var obj = vm.pop();
    if (obj is EleuInstance) {
      var val = obj.Get(name, true);
      vm.push(val);
      return;
    }
    throw vm.Error("Only instances have properties.");
  }
}

class SetInstruction extends Instruction {
  String name;
  SetInstruction(this.name, InputStatus status) : super(status);
  @override
  void execute(Interpreter vm) {
    var value = vm.pop();
    var obj = vm.pop();
    if (obj is! EleuInstance) {
      throw vm.Error("Only instances have fields.");
    }
    obj.Set(name, value);
    vm.push(value);
  }
}

class SuperInstruction extends Instruction {
  int distance;
  string name;

  SuperInstruction(this.name, this.distance, InputStatus status) : super(status);
  @override
  void execute(Interpreter vm) {
    EleuClass superclass = vm.environment.GetAt("super", distance) as EleuClass;
    EleuInstance obj = vm.environment.GetAt("this", distance - 1) as EleuInstance;
    var method = superclass.FindMethod(name);
    if (method is! EleuFunction) {
      throw vm.Error("Undefined property '${name}'.");
    }
    vm.push(method.bind(obj, true));
  }
}
