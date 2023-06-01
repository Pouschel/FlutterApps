import 'dart:math';

import 'package:hati/hati.dart';

import '../ast/ast_expr.dart';
import '../ast/ast_stmt.dart';
import '../eleu.dart';
import '../native.dart';
import '../puzzles/functions.dart';
import '../puzzles/puzzle.dart';
import '../scanning.dart';
import '../types.dart';
import 'interpreting.dart';
import 'resolver.dart';



class Interpreter implements ExprVisitor<Object>, StmtVisitor<InterpretResult> {
  EleuOptions options;
  InputStatus currentStatus = InputStatus.Empty;
  Puzzle? puzzle;
  void Function(Puzzle?)? PuzzleChanged;

  int FrameTimeMs = 100;
  int InstructionCount = 0;
  final List<Stmt> statements;
  EleuEnvironment globals = EleuEnvironment(null);
  late EleuEnvironment environment;
  Map<Expr, int> locals = Map.identity();
  bool Function(Stmt)? canContinueFunc;
  late InterpretResult Function(Stmt) Execute;

  Stack<CallStackInfo> callStack = Stack();
  final List<Token> orgTokens;
  int MaxStackDepth = 200;

  int ExecutedInstructionCount = 0;

  Interpreter(this.options, this.statements, this.orgTokens) {
    NativeFunctions.DefineAll(this);
    PuzzleFunctions.DefineAll(this);
    this.environment = globals;
    globals.Define("PI", Number(pi));
    Execute = ExecuteRelease;
  }

  void NotifyPuzzleChange(Puzzle? newPuzzle) {
    if (PuzzleChanged != null) PuzzleChanged!(newPuzzle);
  }

  InterpretResult ExecuteRelease(Stmt stmt) {
    return stmt.Accept(this);
  }

  void RuntimeError(String msg) => throw EleuRuntimeError(currentStatus, msg);

  void DefineNative(String name, NativeFn function) {
    var ofun = NativeFunction(name, function);
    globals.Define(name, ofun);
  }

  EEleuResult Interpret() {
    Execute = ExecuteRelease;
    return DoInterpret();
  }

  EEleuResult DoInterpret() {
    EEleuResult result = EEleuResult.Ok;
    try {
      locals = Map.identity();
      callStack = Stack();
      Resolve();
      ExecutedInstructionCount = 0;
      for (var stmt in this.statements) {
        Execute(stmt);
      }
    } on EleuRuntimeError catch (ex) {
      if (options.ThrowOnAssert && ex is EleuAssertionFail) rethrow;
      var stat = ex.Status ?? currentStatus;
      var msg = "${stat.Message}: ${ex.Message}";
      options.Err.WriteLine(msg);
      //print(msg);
      result = EEleuResult.RuntimeError;
    }
    return result;
  }

  void Resolve() {
    var resolver = Resolver(this);
    resolver.ResolveList(this.statements);
  }

  void resolveLocal(Expr expr, int depth) {
    locals[expr] = depth;
  }

  InterpretResult ExecuteBlock(List<Stmt> statements, EleuEnvironment environment) {
    var previous = this.environment;
    InterpretResult result = InterpretResult.NilResult;
    try {
      this.environment = environment;
      for (Stmt statement in statements) {
        result = Execute(statement);
        if (result.Stat != InterpretStatus.Normal) break;
      }
      return result;
    } finally {
      this.environment = previous;
    }
  }

  Object Evaluate(Expr expr) {
    ExecutedInstructionCount++;
    RegisterStatus(expr.Status);
    var evaluated = expr.Accept(this);
    return evaluated;
  }

  object LookUpVariable(string name, Expr expr) {
    var distance = locals[expr];
    if (distance != null) {
      return environment.GetAt(name, distance);
    } else {
      return globals.Lookup(name);
    }
  }

  void RegisterStatus(InputStatus? status) {
    if (status != null) {
      currentStatus = status;
    }
  }

  EleuRuntimeError Error(String message) {
    return EleuRuntimeError(currentStatus, message);
  }

  @override
  InterpretResult VisitAssertStmt(AssertStmt stmt) {
    bool fail = false;
    try {
      var val = Evaluate(stmt.expression);
      if (IsFalsey(val)) fail = true;
    } on EleuRuntimeError catch (ex) {
      if (stmt.isErrorAssert) {
        if (stmt.message == null || stmt.message == ex.Message)
          return InterpretResult.NilResult;
      }
      rethrow;
    }
    var msg = stmt.message ?? "Eine Annahme ist fehlgeschlagen.";
    if (stmt.isErrorAssert) {
      fail = true;
      msg += " Es wurde eine RuntimeException erwartet!";
    }
    if (fail) throw EleuAssertionFail(stmt.expression.Status, msg);
    return InterpretResult.NilResult;
  }

  @override
  Object VisitAssignExpr(AssignExpr expr) {
    var value = Evaluate(expr.Value);
    var distance = locals[expr];
    if (distance != null) {
      environment.AssignAt(distance, expr.Name, value);
    } else {
      globals.Assign(expr.Name, value);
    }
    return value;
  }

  @override
  Object VisitBinaryExpr(BinaryExpr expr) {
    var lhs = Evaluate(expr.Left);
    var rhs = Evaluate(expr.Right);
    switch (expr.Op.Type) {
      case TokenType.TokenBangEqual:
        return !ObjEquals(lhs, rhs);
      case TokenType.TokenEqualEqual:
        return ObjEquals(lhs, rhs);
      case TokenType.TokenGreater:
        return InternalCompare(lhs, rhs) > 0;
      case TokenType.TokenGreaterEqual:
        return InternalCompare(lhs, rhs) >= 0;
      case TokenType.TokenLess:
        return InternalCompare(lhs, rhs) < 0;
      case TokenType.TokenLessEqual:
        return InternalCompare(lhs, rhs) <= 0;
      case TokenType.TokenPlus:
        return NumStrAdd(lhs, rhs);
      case TokenType.TokenMinus:
        return NumSubtract(lhs, rhs);
      case TokenType.TokenStar:
        return NumberOp("*", lhs, rhs, (a, b) => a * b);
      case TokenType.TokenPercent:
        return NumberOp("%", lhs, rhs, (a, b) => a % b);
      case TokenType.TokenSlash:
        return NumberOp("/", lhs, rhs, (a, b) => a / b);
      default:
        throw Error("Invalid op: ${expr.Op.Type}");
    }
  }

  @override
  InterpretResult VisitBlockStmt(BlockStmt stmt) =>
      ExecuteBlock(stmt.Statements, EleuEnvironment(environment));

  @override
  InterpretResult VisitBreakContinueStmt(BreakContinueStmt stmt) {
    return stmt.IsBreak ? InterpretResult.BreakResult : InterpretResult.ContinueResult;
  }

  @override
  Object VisitCallExpr(CallExpr expr) {
    var callee = Evaluate(expr.Callee);
    if (callee is! ICallable) {
      RuntimeError("Can only call functions and classes.");
      return expr;
    }
    var function = callee;
    if (function is! NativeFunction && expr.Arguments.length != function.Arity)
      RuntimeError(
          "Expected ${function.Arity} arguments but got ${expr.Arguments.length}.");
    if (callStack.length >= MaxStackDepth)
      RuntimeError("Zu viele verschachtelte Funktionsaufrufe.");
    var arguments = <Object>[];
    for (int i = 0; i < expr.Arguments.length; i++) {
      var argument = expr.Arguments[i];
      arguments.add(Evaluate(argument));
    }
    try {
      var csi = CallStackInfo(this, function, environment);
      callStack.push(csi);
      //Trace.Write($"{callStack.Count} ");		if (callStack.Count % 100 == 0) Trace.WriteLine("");
      return function.Call(this, arguments);
    } finally {
      callStack.pop();
    }
  }

  @override
  InterpretResult VisitClassStmt(ClassStmt stmt) {
    EleuClass? superclass;
    if (stmt.Superclass != null) {
      var superclassV = Evaluate(stmt.Superclass!);
      if (superclassV is! EleuClass) {
        throw Error("Superclass must be a class.");
      }
      superclass = superclassV;
    }
    var klass = environment.GetAtDistance0(stmt.Name);
    if (klass is! EleuClass) {
      environment.Define(stmt.Name, NilValue);
      klass = EleuClass(stmt.Name, superclass);
    } else {
      if (klass.Superclass != null && klass.Superclass != superclass)
        throw EleuRuntimeError(stmt.Status,
            "Super class must be the same (${klass.Superclass?.Name} vs. ${superclass?.Name})");
    }
    if (superclass != null) {
      environment = EleuEnvironment(environment);
      environment.Define("super", superclass);
    }

    //klass = new EleuClass(stmt.Name, superclass);
    for (FunctionStmt method in stmt.Methods) {
      EleuFunction function = EleuFunction(method, environment, method.Name == "init");
      klass.Methods.Set(method.Name, function);
    }
    var kval = klass;
    if (superclass != null) {
      environment = environment.enclosing!;
    }
    environment.Assign(stmt.Name, kval);
    return InterpretResult(kval, InterpretStatus.Normal);
  }

  @override
  InterpretResult VisitExpressionStmt(ExpressionStmt stmt) {
    var evRes = Evaluate(stmt.expression);
    if (evRes is ICallable && stmt.expression is VariableExpr)
      throw Error("Die Funktion '${evRes.Name}' muss mit () aufgerufen werden");
    return InterpretResult(evRes, InterpretStatus.Normal);
  }

  @override
  InterpretResult VisitFunctionStmt(FunctionStmt stmt) {
    EleuFunction function = EleuFunction(stmt, environment, false);
    environment.Define(stmt.Name, function);
    return InterpretResult(function, InterpretStatus.Normal);
  }

  @override
  Object VisitGetExpr(GetExpr expr) {
    var obj = Evaluate(expr.Obj);
    if (obj is EleuInstance) {
      return obj.Get(expr.Name);
    }
    throw Error("Only instances have properties.");
  }

  @override
  Object VisitGroupingExpr(GroupingExpr expr) => Evaluate(expr.Expression);

  @override
  InterpretResult VisitIfStmt(IfStmt stmt) {
    var cond = Evaluate(stmt.Condition);
    if (cond is! bool)
      throw Error("Die if-Bedingung '${cond}' ist nicht vom Typ boolean");
    if (IsTruthy(cond))
      return Execute(stmt.ThenBranch);
    else if (stmt.ElseBranch != null) return Execute(stmt.ElseBranch!);
    return InterpretResult.NilResult;
  }

  @override
  Object VisitLiteralExpr(LiteralExpr expr) {
    if (expr.Value == null) return NilValue;
    return expr.Value!;
  }

  @override
  Object VisitLogicalExpr(LogicalExpr expr) {
    var left = Evaluate(expr.Left);
    if (left is! bool)
      throw Error(
          "Der Operator '${expr.Op.StringValue}' kann nicht auf '${left}' angewendet werden.");
    var right = Evaluate(expr.Right);
    if (right is! bool)
      throw Error(
          "Der Operator '${expr.Op.StringValue}' kann nicht auf '${right}' angewendet werden.");
    if (expr.Op.Type == TokenType.TokenOr) {
      if (IsTruthy(left)) return left;
    } else {
      if (IsFalsey(left)) return left;
    }
    return right;
  }

  @override
  InterpretResult VisitRepeatStmt(RepeatStmt stmt) {
    var result = InterpretResult.NilResult;
    int? GetCount() {
      var count = Evaluate(stmt.Count);
      if (count is! Number) return null;
      if (!count.IsInt) return null;
      return count.IntValue;
    }

    var count = GetCount();
    if (count is! int)
      throw EleuRuntimeError(stmt.Count.Status, "Es wird eine natürliche Zahl erwartet.");

    for (int i = 0; i < count; i++) {
      result = Execute(stmt.Body);
      if (result.Stat == InterpretStatus.Continue) {
        continue;
      }
      if (result.Stat == InterpretStatus.Break) {
        result = InterpretResult.NilResult;
        break;
      }
      if (result.Stat != InterpretStatus.Normal) break;
    }
    return result;
  }

  @override
  InterpretResult VisitReturnStmt(ReturnStmt stmt) {
    var val = NilValue;
    if (stmt.Value != null) val = Evaluate(stmt.Value!);
    return InterpretResult(val, InterpretStatus.Return);
  }

  @override
  Object VisitSetExpr(SetExpr expr) {
    var obj = Evaluate(expr.Obj);
    if (obj is! EleuInstance) {
      throw Error("Only instances have fields.");
    }
    var value = Evaluate(expr.Value);
    obj.Set(expr.Name, value);
    return value;
  }

  @override
  Object VisitSuperExpr(SuperExpr expr) {
    int distance = locals[expr] ?? 0;
    EleuClass superclass = environment.GetAt("super", distance) as EleuClass;
    EleuInstance obj = environment.GetAt("this", distance - 1) as EleuInstance;
    var method = superclass.FindMethod(expr.Method);
    if (method == NilValue) {
      throw Error("Undefined property '${expr.Method}'.");
    }
    return (method as EleuFunction).bind(obj);
  }

  @override
  Object VisitThisExpr(ThisExpr expr) {
    return LookUpVariable(expr.Keyword, expr);
  }

  @override
  Object VisitUnaryExpr(UnaryExpr expr) {
    var right = Evaluate(expr.Right);
    switch (expr.Op.Type) {
      case TokenType.TokenBang:
        if (right is! bool) throw Error("Operand muss vom Typ boolean sein.");
        return !IsTruthy(right);
      case TokenType.TokenMinus:
        {
          if (right is! Number) throw Error("Operand muss eine Zahl sein.");
          return -right;
        }
      default:
        throw Error("Unknown op type: ${expr.Op.Type}"); // Unreachable.
    }
  }

  @override
  InterpretResult VisitVarStmt(VarStmt stmt) {
    var value = NilValue;
    if (stmt.Initializer != null) {
      value = Evaluate(stmt.Initializer!);
    }
    if (environment.ContainsAtDistance0(stmt.Name))
      throw Error("Mehrfache var-Anweisung: '${stmt.Name}' wurde bereits deklariert!");
    environment.Define(stmt.Name, value);
    return InterpretResult(value, InterpretStatus.Normal);
  }

  @override
  Object VisitVariableExpr(VariableExpr expr) => LookUpVariable(expr.Name, expr);

  @override
  InterpretResult VisitWhileStmt(WhileStmt stmt) {
    var result = InterpretResult.NilResult;
    while (IsTruthy(Evaluate(stmt.Condition))) {
      result = Execute(stmt.Body);
      if (result.Stat == InterpretStatus.Continue) {
        if (stmt.Increment != null) Evaluate(stmt.Increment!);
        continue;
      }
      if (result.Stat == InterpretStatus.Break) {
        result = InterpretResult.NilResult;
        break;
      }
      if (result.Stat != InterpretStatus.Normal) break;
    }
    return result;
  }
}
