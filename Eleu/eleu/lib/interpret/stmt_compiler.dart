import 'package:eleu/scanning.dart';

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
  List<JumpInstruction> breakContinues = [];

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
  }

  @override
  void VisitBreakContinueStmt(BreakContinueStmt stmt) {
    var jump = JumpInstruction(
        stmt.IsBreak ? JumpMode.jmp_true : JumpMode.jmp_false, stmt.Status);
    breakContinues.add(jump);
    chunk.add(jump);
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
    var oldBreaks = breakContinues;
    breakContinues = [];
    stmt.Count.Accept(this);
    int repeatIndex = chunk.length;
    var endJump = JumpInstruction(JumpMode.jmp_le_zero, stmt.Count.Status);
    chunk.add(endJump);
    stmt.Body.Accept(this);
    int incrPos = chunk.length;
    chunk.add(PushInstruction(Number(1), stmt.Count.Status));
    chunk.add(BinaryOpInstruction(TokenType.TokenMinus, stmt.Count.Status));
    chunk.add(JumpInstruction(JumpMode.jmp, stmt.Count.Status)..offset = repeatIndex);
    endJump.offset = chunk.length;
    patchBreakContinues(endJump.offset, incrPos);
    breakContinues = oldBreaks;
  }

  void patchBreakContinues(int breakOfs, int continueOfs) {
    for (var jmp in breakContinues) {
      if (jmp.mode == JumpMode.jmp_true)
        jmp.offset = breakOfs;
      else
        jmp.offset = continueOfs;
      jmp.mode = JumpMode.jmp;
    }
  }

  @override
  void VisitReturnStmt(ReturnStmt stmt) {
    if (stmt.Value != null)
      stmt.Value!.Accept(this);
    else
      chunk.add(PushInstruction(NilValue, stmt.Keyword.Status));
    chunk.add(ReturnInstruction(stmt.Status));
  }

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
    var oldBreaks = breakContinues;
    breakContinues = [];
    int loopStart = chunk.length;
    stmt.Condition.Accept(this);
    var exitJump = JumpInstruction(JumpMode.jmp_false, stmt.Condition.Status);
    chunk.add(exitJump);
    chunk.add(PopInstruction(stmt.Condition.Status));
    stmt.Body.Accept(this);
    int incrementOfs = chunk.length;
    if (stmt.Increment != null) {
      stmt.Increment!.Accept(this);
      chunk.add(PopInstruction(stmt.Increment!.Status));
    }
    chunk.add(JumpInstruction(JumpMode.jmp, stmt.Condition.Status)..offset = loopStart);
    exitJump.offset = chunk.length;

    patchBreakContinues(exitJump.offset, incrementOfs);
    breakContinues = oldBreaks;
  }

  @override
  void VisitAssignExpr(AssignExpr expr) {
    expr.Value.Accept(this);
    chunk.add(AssignInstruction(expr.Name, expr));
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
