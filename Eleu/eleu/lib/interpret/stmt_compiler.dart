import 'package:eleu/interpret/interpreter.dart';
import 'package:eleu/scanning.dart';

import '../ast/ast_expr.dart';
import '../ast/ast_stmt.dart';

class Chunk {
  List<Instruction> code = [];
}

abstract class Instruction {
  InputStatus status;
  void execute(Interpreter vm);

  Instruction(this.status);
}

class EvalInstruction extends Instruction {
  Expr expr;

  EvalInstruction(this.expr): super(expr.Status);

  @override
  void execute(Interpreter vm) {
    vm.lastValue = vm.Evaluate(expr);
  }
}

class StmtCompiler implements StmtVisitor<void> {
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
  void VisitExpressionStmt(ExpressionStmt stmt) {}

  @override
  void VisitFunctionStmt(FunctionStmt stmt) {
    // TODO: implement VisitFunctionStmt
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
}
