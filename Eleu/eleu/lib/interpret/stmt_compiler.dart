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
  int scopeDepth = 0;

  Chunk compile(List<Stmt> stmts) {
    for (var stmt in stmts) {
      stmt.Accept(this);
    }
    return chunk;
  }

  void emit(Instruction ins) => chunk.add(ins);

  @override
  void VisitAssertStmt(AssertStmt stmt) {
    if (!stmt.isErrorAssert) {
      stmt.expression.Accept(this);
      emit(AssertInstruction(stmt.Status));
    }

    // TODO: assert break
  }

  @override
  void VisitBlockStmt(BlockStmt stmt) {
    emit(ScopeInstruction(true));
    scopeDepth++;
    for (var s in stmt.Statements) {
      s.Accept(this);
    }
    scopeDepth--;
    emit(ScopeInstruction(false));
  }

  @override
  void VisitBreakContinueStmt(BreakContinueStmt stmt) {
    var jump = JumpInstruction(
        stmt.IsBreak ? JumpMode.jmp_true : JumpMode.jmp_false, stmt.Status);
    breakContinues.add(jump);
    jump.leaveScopes = scopeDepth;
    emit(jump);
  }

  @override
  void VisitClassStmt(ClassStmt stmt) {
    if (stmt.Superclass != null) {
      stmt.Superclass!.Accept(this);
    } else
      emit(PushInstruction(NilValue, stmt.Status));
    emit(ClassInstruction(stmt.Name, stmt.Methods, stmt.Status));
  }

  @override
  void VisitExpressionStmt(ExpressionStmt stmt) {
    stmt.expression.Accept(this);
    emit(PopInstruction(stmt.expression.Status));
  }

  @override
  void VisitFunctionStmt(FunctionStmt stmt) {
    emit(DefFunInstruction(stmt));
  }

  @override
  void VisitIfStmt(IfStmt stmt) {
    stmt.Condition.Accept(this);
    var thenJump = JumpInstruction(JumpMode.jmp_false, stmt.Condition.Status);
    emit(thenJump);
    emit(PopInstruction(stmt.Condition.Status));
    stmt.ThenBranch.Accept(this);
    var elseJump = JumpInstruction(JumpMode.jmp, stmt.ThenBranch.Status);
    emit(elseJump);
    thenJump.offset = chunk.length;
    emit(PopInstruction(stmt.ThenBranch.Status));
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
    emit(endJump);
    stmt.Body.Accept(this);
    int incrPos = chunk.length;
    emit(PushInstruction(Number(1), stmt.Count.Status));
    emit(BinaryOpInstruction(TokenType.TokenMinus, stmt.Count.Status));
    emit(JumpInstruction(JumpMode.jmp, stmt.Count.Status)..offset = repeatIndex);
    endJump.offset = chunk.length;
    emit(PopInstruction(stmt.Status));
    patchBreakContinues(endJump.offset, incrPos);
    breakContinues = oldBreaks;
  }

  void patchBreakContinues(int breakOfs, int continueOfs) {
    for (var jmp in breakContinues) {
      jmp.leaveScopes -= this.scopeDepth;
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
      emit(PushInstruction(NilValue, stmt.Keyword.Status));
    emit(ReturnInstruction(this.scopeDepth, stmt.Status));
  }

  @override
  void VisitVarStmt(VarStmt stmt) {
    if (stmt.Initializer != null)
      stmt.Initializer!.Accept(this);
    else
      emit(PushInstruction(NilValue, stmt.Status));
    emit(VarDefInstruction(stmt.Name, stmt.Status));
  }

  @override
  void VisitWhileStmt(WhileStmt stmt) {
    var oldBreaks = breakContinues;
    breakContinues = [];
    int loopStart = chunk.length;
    stmt.Condition.Accept(this);
    var exitJump = JumpInstruction(JumpMode.jmp_false, stmt.Condition.Status);
    emit(exitJump);
    emit(PopInstruction(stmt.Condition.Status));
    stmt.Body.Accept(this);
    int incrementOfs = chunk.length;
    if (stmt.Increment != null) {
      stmt.Increment!.Accept(this);
      emit(PopInstruction(stmt.Increment!.Status));
    }
    emit(JumpInstruction(JumpMode.jmp, stmt.Condition.Status)..offset = loopStart);
    exitJump.offset = chunk.length;

    patchBreakContinues(exitJump.offset, incrementOfs);
    breakContinues = oldBreaks;
  }

  @override
  void VisitAssignExpr(AssignExpr expr) {
    expr.Value.Accept(this);
    emit(AssignInstruction(expr.Name, expr.localDistance, expr.Status));
  }

  @override
  void VisitBinaryExpr(BinaryExpr expr) {
    expr.Left.Accept(this);
    expr.Right.Accept(this);
    emit(BinaryOpInstruction(expr.Op.Type, expr.Status));
  }

  @override
  void VisitCallExpr(CallExpr expr) {
    for (int i = 0; i < expr.Arguments.length; i++) {
      var argument = expr.Arguments[i];
      argument.Accept(this);
    }
    expr.Callee.Accept(this);
    emit(CallInstruction(expr.Arguments.length, expr.Status));
  }

  @override
  void VisitGetExpr(GetExpr expr) {
    // TODO: implement VisitGetExpr
  }

  @override
  void VisitGroupingExpr(GroupingExpr expr) {
    expr.Expression.Accept(this);
  }

  @override
  void VisitLiteralExpr(LiteralExpr expr) {
    var value = expr.Value ?? NilValue;
    emit(PushInstruction(value, expr.Status));
  }

  @override
  void VisitLogicalExpr(LogicalExpr expr) {
    expr.Left.Accept(this);
    expr.Right.Accept(this);
    emit(LogicalOpInstruction(expr.Op, expr.Status));
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
    expr.Right.Accept(this);
    emit(UnaryOpInstruction(expr.Op.Type, expr.Status));
  }

  @override
  void VisitVariableExpr(VariableExpr expr) {
    emit(LookupVarInstruction(expr.Name, expr.localDistance, expr.Status));
  }
}
