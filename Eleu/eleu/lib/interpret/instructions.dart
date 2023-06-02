import 'package:eleu/interpret/stmt_compiler.dart';
import 'package:hati/hati.dart';

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
