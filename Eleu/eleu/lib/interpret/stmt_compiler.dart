import '../ast/ast_expr.dart';
import '../ast/ast_stmt.dart';
import '../types.dart';
import 'instructions.dart';

class Chunk {
  List<Instruction> code = [];

  void add(Instruction ins) => code.add(ins);
  int get length => code.length;
}

class StmtCompiler implements StmtVisitor<void>, ExprVisitor<void> {
  Chunk chunk = Chunk();

  Chunk compile(List<Stmt> stmts) {
    for (var stmt in stmts) {
      stmt.Accept(this);
    }
    return chunk;
  }

  @override
  void VisitAssertStmt(AssertStmt stmt) {
    // TODO: implement VisitAssertStmt
  }

  @override
  void VisitBlockStmt(BlockStmt stmt) {
    chunk.add(ScopeInstruction(true));
    for (var s in stmt.Statements) {
      s.Accept(this);
    }
    chunk.add(ScopeInstruction(false));
    // TODO: implement VisitBlockStmt
  }

  @override
  void VisitBreakContinueStmt(BreakContinueStmt stmt) {
    // TODO: implement VisitBreakContinueStmt
  }

  @override
  void VisitClassStmt(ClassStmt stmt) {
    // TODO: implement VisitClassStmt
  }

  @override
  void VisitExpressionStmt(ExpressionStmt stmt) {
    stmt.expression.Accept(this);
    chunk.add(PopInstruction(stmt.expression.Status));
  }

  @override
  void VisitFunctionStmt(FunctionStmt stmt) {
    chunk.add(DefFunInstruction(stmt));
  }

  @override
  void VisitIfStmt(IfStmt stmt) {
    stmt.Condition.Accept(this);
    var thenJump = JumpInstruction(JumpMode.jmp_false, stmt.Condition.Status);
    chunk.add(thenJump);
    chunk.add(PopInstruction(stmt.Condition.Status));
    stmt.ThenBranch.Accept(this);
    var elseJump = JumpInstruction(JumpMode.jmp, stmt.ThenBranch.Status);
    chunk.add(elseJump);
    thenJump.offset = chunk.length;
    chunk.add(PopInstruction(stmt.ThenBranch.Status));
    if (stmt.ElseBranch != null) stmt.ElseBranch!.Accept(this);
    elseJump.offset = chunk.length;
  }

  @override
  void VisitRepeatStmt(RepeatStmt stmt) {
    //stmt.Accept(this);
  }

  @override
  void VisitReturnStmt(ReturnStmt stmt) {}

  @override
  void VisitVarStmt(VarStmt stmt) {
    if (stmt.Initializer != null)
      stmt.Initializer!.Accept(this);
    else
      chunk.add(PushInstruction(NilValue, stmt.Status));
    chunk.add(VarDefInstruction(stmt.Name, stmt.Status));
  }

  @override
  void VisitWhileStmt(WhileStmt stmt) {
    // TODO: implement VisitWhileStmt
  }

  @override
  void VisitAssignExpr(AssignExpr expr) {
    // TODO: implement VisitAssignExpr
  }

  @override
  void VisitBinaryExpr(BinaryExpr expr) {
    expr.Left.Accept(this);
    expr.Right.Accept(this);
    chunk.add(BinaryOpInstruction(expr.Op.Type, expr.Status));
  }

  @override
  void VisitCallExpr(CallExpr expr) {
    for (int i = 0; i < expr.Arguments.length; i++) {
      var argument = expr.Arguments[i];
      argument.Accept(this);
    }
    expr.Callee.Accept(this);
    chunk.add(CallInstruction(expr.Arguments.length, expr.Status));
  }

  @override
  void VisitGetExpr(GetExpr expr) {
    // TODO: implement VisitGetExpr
  }

  @override
  void VisitGroupingExpr(GroupingExpr expr) {
    // TODO: implement VisitGroupingExpr
  }

  @override
  void VisitLiteralExpr(LiteralExpr expr) {
    var value = expr.Value ?? NilValue;
    chunk.add(PushInstruction(value, expr.Status));
  }

  @override
  void VisitLogicalExpr(LogicalExpr expr) {
    // TODO: implement VisitLogicalExpr
  }

  @override
  void VisitSetExpr(SetExpr expr) {
    // TODO: implement VisitSetExpr
  }

  @override
  void VisitSuperExpr(SuperExpr expr) {
    // TODO: implement VisitSuperExpr
  }

  @override
  void VisitThisExpr(ThisExpr expr) {
    // TODO: implement VisitThisExpr
  }

  @override
  void VisitUnaryExpr(UnaryExpr expr) {
    // TODO: implement VisitUnaryExpr
  }

  @override
  void VisitVariableExpr(VariableExpr expr) {
    chunk.add(LookupVarInstruction(expr.Name, expr));
  }
}
