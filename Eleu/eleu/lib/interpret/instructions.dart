import 'package:eleu/interpret/stmt_compiler.dart';

import '../ast/ast_expr.dart';
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
  String toString() => "op $op";
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
    if (callee is! IChunkCompilable)
      throw EleuRuntimeError(status, "Can only call functions and classes.");
    if (callee is EleuFunction) {
      var environment = EleuEnvironment(callee.closure);
      for (int i = nArgs - 1; i >= 0; i--) {
        environment.Define(callee.declaration.Paras[i].StringValue, vm.pop());
      }
      vm.enterEnv(environment);
      var frame = CallFrame(callee.compiledChunk, func: callee);
      vm.enterFrame(frame);

      return;
    }
    throw UnsupportedError("message");
    // var function = callee;

    // if (function is! NativeFunction && nArgs != function.Arity)
    //   throw EleuRuntimeError(
    //       status, "Expected ${function.Arity} arguments but got ${nArgs}.");
    // if (vm.callStack.length >= vm.MaxStackDepth)
    //   throw EleuRuntimeError(status, "Zu viele verschachtelte Funktionsaufrufe.");

    // var arguments = <Object>[];
    // for (int i = 0; i < expr.Arguments.length; i++) {
    //   var argument = expr.Arguments[i];
    //   arguments.add(Evaluate(argument));
    // }
    // try {
    //   var csi = CallStackInfo(this, function, environment);
    //   callStack.push(csi);
    //   //Trace.Write($"{callStack.Count} ");		if (callStack.Count % 100 == 0) Trace.WriteLine("");
    //   return function.Call(this, arguments);
    // } finally {
    //   callStack.pop();
    // }
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

// class ReturnInstruction extends Instruction {

//   ReturnInstruction(this.value, InputStatus? status) : super(status);
//   @override
//   void execute(Interpreter vm) {
//     vm.frame = vm.frame.next!;
//     vm.push(value);
//   }
// }

class LookupVarInstruction extends Instruction {
  String name;
  VariableExpr vexp;
  LookupVarInstruction(this.name, this.vexp) : super(vexp.Status);

  @override
  void execute(Interpreter vm) {
    var value = vm.LookUpVariable(name, vexp);
    vm.push(value);
  }
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
  String toString() => "$mode $offset";
}

class AssignInstruction extends Instruction {
  Expr lookup;
  String name;

  AssignInstruction(this.name, this.lookup) : super(lookup.Status);

  @override
  void execute(Interpreter vm) {
    var value = vm.peek();
    var distance = vm.locals[lookup];
    if (distance != null) {
      vm.environment.AssignAt(distance, name, value);
    } else {
      vm.globals.Assign(name, value);
    }
  }
}

class ReturnInstruction extends Instruction {
  ReturnInstruction(InputStatus status) : super(status);
  @override
  void execute(Interpreter vm) {
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
