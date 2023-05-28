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
//implements ExprVisitor<Object>, StmtVisitor<InterpretResult>
{
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
    //TODO return stmt.Accept(this);
    return InterpretResult.NilResult;
  }

  @override
  void RuntimeError(String msg) => throw EleuRuntimeError(currentStatus, msg);

  @override
  void DefineNative(String name, NativeFn function) {
    var ofun = NativeFunction(name,  function);
    globals.Define(name, ofun);
  }

  @override
  EEleuResult Interpret() {
    throw UnimplementedError();
  }
}
