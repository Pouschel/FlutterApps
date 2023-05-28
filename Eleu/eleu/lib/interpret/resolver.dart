import '../scanning.dart';
import '../ast/ast_expr.dart';
import '../ast/ast_stmt.dart';
import '../eleu.dart';
import '../types.dart';
import 'interpreter.dart';

enum ClassType { NONE, CLASS, SUBCLASS }

class Resolver implements ExprVisitor<Object?>, StmtVisitor<Object?> {
  Interpreter interpreter;
  List<Map<String, bool>> scopes = [{}];
  int stackLen = 0;
  FunctionType currentFunction = FunctionType.FunTypeScript;
  ClassType currentClass = ClassType.NONE;
  int loopLevel = 0;

  Resolver(this.interpreter);

  void ResolveList(List<Stmt> statements) {
    for (Stmt statement in statements) {
      ResolveStmt(statement);
    }
  }

  void Push(Map<String, bool> d) {
    if (stackLen < scopes.length)
      scopes[stackLen] = d;
    else
      scopes.add(d);
    stackLen++;
  }

  void Pop() => stackLen--;
  Map<String, bool>? Peek() => stackLen > 0 ? scopes[stackLen - 1] : null;

  Object? ResolveStmt(Stmt stmt) {
    interpreter.RegisterStatus(stmt.Status);
    return stmt.Accept(this);
  }

  Object? ResolveExpr(Expr? expr) {
    interpreter.RegisterStatus(expr?.Status);
    return expr?.Accept(this);
  }

  void ResolveFunction(FunctionStmt function, FunctionType type) {
    FunctionType enclosingFunction = currentFunction;
    currentFunction = type;
    BeginScope();
    for (var param in function.Paras) {
      Declare(param.StringValue);
      define(param.StringValue);
    }
    Resolve(function.Body);
    EndScope();
    currentFunction = enclosingFunction;
  }

  Object? ResolveLocal(Expr expr, String name) {
    for (int i = stackLen - 1; i >= 0; i--) {
      if (scopes[i].containsKey(name)) {
        interpreter.resolveLocal(expr, stackLen - 1 - i);
        return null;
      }
    }
    return null;
  }

  Object? Resolve(Object? o) {
    if (o is Expr) return ResolveExpr(o);
    if (o is Stmt) return ResolveStmt(o);
    throw EleuResolverError(interpreter.currentStatus, "null resolving");
  }

  void Declare(String name) {
    var scope = Peek();
    if (scope == null) return;
    if (scope.containsKey(name)) {
      Error(null,
          "Eine Variable mit dem Namen '${name}' existiert in diesem Geltungsbereich schon!");
    }
    scope[name] = false;
  }

  void define(String name) {
    var scope = Peek();
    if (scope == null) return;
    scope[name] = true;
  }

  void BeginScope() => Push({});
  void EndScope() => Pop();
  Error(InputStatus? status, String msg) {
    status ??= interpreter.currentStatus;
    throw EleuResolverError(status, "Cerr: $msg");
  }

  static bool IsEmptyBody(Stmt body) {
    if (body is! ExpressionStmt) return false;
    var lit = body.expression;
    if (lit is! LiteralExpr) return false;
    if (lit.Value == null || lit.Value == NilValue) return true;
    return false;
  }

  void CheckEmptyBody(Stmt body) {
    if (IsEmptyBody(body)) Error(body.Status, "Eine Anweisung oder { wurde erwartet.");
  }

  @override
  Object? VisitAssertStmt(AssertStmt stmt) => Resolve(stmt.expression);

  @override
  Object? VisitAssignExpr(AssignExpr expr) {
		Resolve(expr.Value);
		ResolveLocal(expr, expr.Name);
		return null;
  }

  @override
  Object? VisitBinaryExpr(BinaryExpr expr) {
		Resolve(expr.Left);
		Resolve(expr.Right);
		return null;
  }

  @override
  Object? VisitBlockStmt(BlockStmt stmt) {
		BeginScope();
		Resolve(stmt.Statements);
		EndScope();
		return null;
  }

  @override
  Object? VisitBreakContinueStmt(BreakContinueStmt stmt) {
		if (loopLevel == 0)
		{
			var s = stmt.IsBreak ? "break" : "continue";
			Error(stmt.Status, "'${s}' ist hier nicht erlaubt.");
		}
		return null;
  }

  @override
  Object? VisitCallExpr(CallExpr expr) {
    Resolve(expr.Callee);
    for (Expr argument in expr.Arguments) {
      ResolveExpr(argument);
    }
    return null;
  }

  @override
  Object? VisitClassStmt(ClassStmt stmt) {
    ClassType enclosingClass = currentClass;
    currentClass = ClassType.CLASS;
    Declare(stmt.Name);
    define(stmt.Name);
    if (stmt.Superclass != null && stmt.Name == stmt.Superclass!.Name) {
      Error(stmt.Status, "A class can't inherit from itself.");
    }
    if (stmt.Superclass != null) {
      currentClass = ClassType.SUBCLASS;
      Resolve(stmt.Superclass);
    }
    if (stmt.Superclass != null) {
      BeginScope();
      Peek()!["super"] = true;
    }
    BeginScope();
    Peek()!["this"] = true;
    for (FunctionStmt method in stmt.Methods) {
      FunctionType declaration = FunctionType.FunTypeMethod;
      if (method.Name == "init") declaration = FunctionType.FunTypeInitializer;
      ResolveFunction(method, declaration);
    }
    EndScope();
    if (stmt.Superclass != null) EndScope();
    currentClass = enclosingClass;
    return null;
  }

  @override
  Object? VisitExpressionStmt(ExpressionStmt stmt) => Resolve(stmt.expression);

  @override
  Object? VisitFunctionStmt(FunctionStmt stmt) {
    Declare(stmt.Name);
    define(stmt.Name);
    ResolveFunction(stmt, FunctionType.FunTypeFunction);
    return null;
  }

  @override
  Object? VisitGetExpr(GetExpr expr) => Resolve(expr.Obj);

  @override
  Object? VisitGroupingExpr(GroupingExpr expr) => Resolve(expr.Expression);

  @override
  Object? VisitIfStmt(IfStmt stmt) {
    Resolve(stmt.Condition);
    Resolve(stmt.ThenBranch);
    if (stmt.ElseBranch != null) Resolve(stmt.ElseBranch);
    return null;
  }

  @override
  Object? VisitLiteralExpr(LiteralExpr expr) => null;

  @override
  Object? VisitLogicalExpr(LogicalExpr expr) {
    Resolve(expr.Left);
    Resolve(expr.Right);
    return null;
  }

  @override
  Object? VisitRepeatStmt(RepeatStmt stmt) {
		Resolve(stmt.Count);
		loopLevel++;
		CheckEmptyBody(stmt.Body);
		Resolve(stmt.Body);
		loopLevel--;
		return null;
  }

  @override
  Object? VisitReturnStmt(ReturnStmt stmt) {
    if (currentFunction == FunctionType.FunTypeScript) {
      Error(stmt.Status, "Can't return from top-level code.");
    }
    if (currentFunction == FunctionType.FunTypeInitializer && stmt.Value != null)
      Error(stmt.Status, "Can't return a value from an initializer.");
    return Resolve(stmt.Value);
  }

  @override
  Object? VisitSetExpr(SetExpr expr) {
    Resolve(expr.Value);
    Resolve(expr.Obj);
    return null;
  }

  @override
  Object? VisitSuperExpr(SuperExpr expr) {
    if (currentClass == ClassType.NONE) {
      Error(expr.Status, "Can't use 'super' outside of a class.");
    } else if (currentClass != ClassType.SUBCLASS) {
      Error(expr.Status, "Can't use 'super' in a class with no superclass.");
    }
    return ResolveLocal(expr, expr.Keyword);
  }

  @override
  Object? VisitThisExpr(ThisExpr expr) {
    if (currentClass == ClassType.NONE) {
      Error(expr.Status, "Can't use 'this' outside of a class.");
      return null;
    }
    return ResolveLocal(expr, expr.Keyword);
  }

  @override
  Object? VisitUnaryExpr(UnaryExpr expr) => Resolve(expr.Right);

  @override
  Object? VisitVarStmt(VarStmt stmt) {
    Declare(stmt.Name);
    if (stmt.Initializer != null) {
      Resolve(stmt.Initializer);
    }
    define(stmt.Name);
    return null;
  }

  @override
  Object? VisitVariableExpr(VariableExpr expr) {
		var scope = Peek();
    //scope != null && scope.TryGetValue(expr.Name, out bool b) && !b
		if (scope!=null)
		{
      if (scope[expr.Name] ?? false)
        Error(expr.Status, "Can't read local variable in its own initializer.");
		}
		ResolveLocal(expr, expr.Name);
		return null;
  }

  @override
  Object? VisitWhileStmt(WhileStmt stmt) {
    Resolve(stmt.Condition);
    loopLevel++;
    CheckEmptyBody(stmt.Body);
    Resolve(stmt.Body);
    loopLevel--;
    return null;
  }
}
