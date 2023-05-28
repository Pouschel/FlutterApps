import 'dart:math';

import '../ast/ast_expr.dart';
import '../ast/ast_stmt.dart';
import '../eleu.dart';
import '../scanning.dart';
import '../types.dart';
import 'interpreting.dart';

class Stack<E> {
  final _list = <E>[];

  void push(E value) => _list.add(value);

  E pop() => _list.removeLast();

  E get peek => _list.last;

  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;

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
	EEleuResult DoInterpret()
	{
		EEleuResult result = EEleuResult.Ok;
		try
		{
			locals = Map.identity();
			callStack = Stack();
			//TODO var resolver = Resolver(this);
			// resolver.Resolve(this.statements);
			// resolver = null;
			// ExecutedInstructionCount = 0;
			// for (var stmt in this.statements)
			// {
			// 	Execute(stmt);
			// }
		}
		on EleuRuntimeError catch (ex)
		{
			if (options.ThrowOnAssert && ex is EleuAssertionFail) rethrow;
			var stat = ex.Status ?? currentStatus;
			var msg = "${stat.Message}: {ex.Message}";
			options.Err.WriteLine(msg);
			print(msg);
			result = EEleuResult.RuntimeError;
		}
		return result;
	}
  @override
  InterpretResult VisitAssertStmt(AssertStmt stmt) {
    // TODO: implement VisitAssertStmt
    throw UnimplementedError();
  }

  @override
  Object VisitAssignExpr(AssignExpr expr) {
    // TODO: implement VisitAssignExpr
    throw UnimplementedError();
  }

  @override
  Object VisitBinaryExpr(BinaryExpr expr) {
    // TODO: implement VisitBinaryExpr
    throw UnimplementedError();
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
    // TODO: implement VisitCallExpr
    throw UnimplementedError();
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
    // TODO: implement VisitGetExpr
    throw UnimplementedError();
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
