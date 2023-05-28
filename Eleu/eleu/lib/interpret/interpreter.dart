import 'dart:math';

import '../ast/ast_expr.dart';
import '../ast/ast_stmt.dart';
import '../eleu.dart';
import '../scanning.dart';
import '../types.dart';
import 'interpreting.dart';
import 'resolver.dart';

class Stack<E> {
  final _list = <E>[];

  void push(E value) => _list.add(value);

  E pop() => _list.removeLast();

  E get peek => _list.last;

  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;
  int get length => _list.length;

  @override
  String toString() => _list.toString();
}

class Interpreter extends IInterpreter
    implements ExprVisitor<Object>, StmtVisitor<InterpretResult> {
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

  Interpreter(EleuOptions options, this.statements, this.orgTokens) : super(options) {
    this.environment = globals;
    globals.Define("PI", Number(pi));
    Execute = ExecuteRelease;
  }

  InterpretResult ExecuteRelease(Stmt stmt) {
    return stmt.Accept(this);
  }

  @override
  void RuntimeError(String msg) => throw EleuRuntimeError(currentStatus, msg);

  @override
  void DefineNative(String name, NativeFn function) {
    var ofun = NativeFunction(name, function);
    globals.Define(name, ofun);
  }

  @override
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
      print(msg);
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
	
  InterpretResult ExecuteBlock(List<Stmt> statements, EleuEnvironment environment)
	{
		var previous = this.environment;
		InterpretResult result = InterpretResult.NilResult;
		try
		{
			this.environment = environment;
			for (Stmt statement in statements)
			{
				result = Execute(statement);
				if (result.Stat != InterpretStatus.Normal)
					break;
			}
			return result;
		}
		finally
		{
			this.environment = previous;
		}
	}
  Object Evaluate(Expr expr) {
    ExecutedInstructionCount++;
    RegisterStatus(expr.Status);
    var evaluated = expr.Accept(this);
    return evaluated;
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
    // TODO: implement VisitAssertStmt
    throw UnimplementedError();
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
  InterpretResult VisitBlockStmt(BlockStmt stmt) {
    // TODO: implement VisitBlockStmt
    throw UnimplementedError();
  }

  @override
  InterpretResult VisitBreakContinueStmt(BreakContinueStmt stmt) {
    // TODO: implement VisitBreakContinueStmt
    throw UnimplementedError();
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
    // TODO: implement VisitClassStmt
    throw UnimplementedError();
  }

  @override
  InterpretResult VisitExpressionStmt(ExpressionStmt stmt) {
    // TODO: implement VisitExpressionStmt
    throw UnimplementedError();
  }

  @override
  InterpretResult VisitFunctionStmt(FunctionStmt stmt) {
    // TODO: implement VisitFunctionStmt
    throw UnimplementedError();
  }

  @override
  Object VisitGetExpr(GetExpr expr) {
		var obj = Evaluate(expr.Obj);
		if (obj is EleuInstance )
		{
			return obj.Get(expr.Name);
		}
		throw Error("Only instances have properties.");
  }

  @override
  Object VisitGroupingExpr(GroupingExpr expr) {
    // TODO: implement VisitGroupingExpr
    throw UnimplementedError();
  }

  @override
  InterpretResult VisitIfStmt(IfStmt stmt) {
    // TODO: implement VisitIfStmt
    throw UnimplementedError();
  }

  @override
  Object VisitLiteralExpr(LiteralExpr expr) {
    // TODO: implement VisitLiteralExpr
    throw UnimplementedError();
  }

  @override
  Object VisitLogicalExpr(LogicalExpr expr) {
    // TODO: implement VisitLogicalExpr
    throw UnimplementedError();
  }

  @override
  InterpretResult VisitRepeatStmt(RepeatStmt stmt) {
    // TODO: implement VisitRepeatStmt
    throw UnimplementedError();
  }

  @override
  InterpretResult VisitReturnStmt(ReturnStmt stmt) {
    // TODO: implement VisitReturnStmt
    throw UnimplementedError();
  }

  @override
  Object VisitSetExpr(SetExpr expr) {
    // TODO: implement VisitSetExpr
    throw UnimplementedError();
  }

  @override
  Object VisitSuperExpr(SuperExpr expr) {
    // TODO: implement VisitSuperExpr
    throw UnimplementedError();
  }

  @override
  Object VisitThisExpr(ThisExpr expr) {
    // TODO: implement VisitThisExpr
    throw UnimplementedError();
  }

  @override
  Object VisitUnaryExpr(UnaryExpr expr) {
    // TODO: implement VisitUnaryExpr
    throw UnimplementedError();
  }

  @override
  InterpretResult VisitVarStmt(VarStmt stmt) {
    // TODO: implement VisitVarStmt
    throw UnimplementedError();
  }

  @override
  Object VisitVariableExpr(VariableExpr expr) {
    // TODO: implement VisitVariableExpr
    throw UnimplementedError();
  }

  @override
  InterpretResult VisitWhileStmt(WhileStmt stmt) {
    // TODO: implement VisitWhileStmt
    throw UnimplementedError();
  }
}
