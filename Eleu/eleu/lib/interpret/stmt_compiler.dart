import 'package:eleu/eleu.dart';
import 'package:eleu/interpret/interpreter.dart';
import 'package:eleu/interpret/interpreting.dart';
import 'package:eleu/scanning.dart';

import '../ast/ast_expr.dart';
import '../ast/ast_stmt.dart';
import '../types.dart';
import 'instructions.dart';

class Chunk {
  List<Instruction> code = [];

  void add(Instruction ins) => code.add(ins);
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
    // TODO: implement VisitIfStmt
  }

  @override
  void VisitRepeatStmt(RepeatStmt stmt) {
    // TODO: implement VisitRepeatStmt
  }

  @override
  void VisitReturnStmt(ReturnStmt stmt) {}

  @override
  void VisitVarStmt(VarStmt stmt) {
    // TODO: implement VisitVarStmt
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
