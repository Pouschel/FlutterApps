// This file was generated by a tool. Do not edit!
// AST classes for stmt
// ignore_for_file: prefer_initializing_formals
import '../scanning.dart';
import 'ast_parser.dart';
import 'ast_expr.dart';
import '../eleu.dart';

abstract class StmtVisitor<R> {
    R VisitBlockStmt(BlockStmt stmt);
    R VisitClassStmt(ClassStmt stmt);
    R VisitExpressionStmt(ExpressionStmt stmt);
    R VisitFunctionStmt(FunctionStmt stmt);
    R VisitIfStmt(IfStmt stmt);
    R VisitAssertStmt(AssertStmt stmt);
    R VisitReturnStmt(ReturnStmt stmt);
    R VisitBreakContinueStmt(BreakContinueStmt stmt);
    R VisitVarStmt(VarStmt stmt);
    R VisitWhileStmt(WhileStmt stmt);
    R VisitRepeatStmt(RepeatStmt stmt);
  }

abstract class Stmt extends ExprStmtBase {
  R Accept<R>(StmtVisitor<R> visitor);

  static BlockStmt Block(List<Stmt> Statements) => BlockStmt(Statements);
  static ClassStmt Class(String Name, VariableExpr? Superclass, List<FunctionStmt> Methods) => ClassStmt(Name, Superclass, Methods);
  static ExpressionStmt Expression(Expr expression) => ExpressionStmt(expression);
  static FunctionStmt Function(FunctionType Type, String Name, List<Token> Paras, List<Stmt> Body) => FunctionStmt(Type, Name, Paras, Body);
  static IfStmt If(Expr Condition, Stmt ThenBranch, Stmt? ElseBranch) => IfStmt(Condition, ThenBranch, ElseBranch);
  static AssertStmt Assert(Expr expression, String? message, bool isErrorAssert) => AssertStmt(expression, message, isErrorAssert);
  static ReturnStmt Return(Token Keyword, Expr? Value) => ReturnStmt(Keyword, Value);
  static BreakContinueStmt BreakContinue(bool IsBreak) => BreakContinueStmt(IsBreak);
  static VarStmt Var(String Name, Expr? Initializer) => VarStmt(Name, Initializer);
  static WhileStmt While(Expr Condition, Stmt Body, Expr? Increment) => WhileStmt(Condition, Body, Increment);
  static RepeatStmt Repeat(Expr Count, Stmt Body) => RepeatStmt(Count, Body);
}

  // Nested Stmt classes here...
  // stmt-block
  class BlockStmt extends Stmt {
    late List<Stmt> Statements;

    BlockStmt(List<Stmt> Statements) {
      this.Statements = Statements;
    }

    @override
    R Accept<R>(StmtVisitor<R> visitor) {
      return visitor.VisitBlockStmt(this);
    }
  }
  // stmt-class
  class ClassStmt extends Stmt {
    late String Name;
    late VariableExpr? Superclass;
    late List<FunctionStmt> Methods;

    ClassStmt(String Name,
          VariableExpr? Superclass,
          List<FunctionStmt> Methods) {
      this.Name = Name;
      this.Superclass = Superclass;
      this.Methods = Methods;
    }

    @override
    R Accept<R>(StmtVisitor<R> visitor) {
      return visitor.VisitClassStmt(this);
    }
  }
  // stmt-expression
  class ExpressionStmt extends Stmt {
    late Expr expression;

    ExpressionStmt(Expr expression) {
      this.expression = expression;
    }

    @override
    R Accept<R>(StmtVisitor<R> visitor) {
      return visitor.VisitExpressionStmt(this);
    }
  }
  // stmt-function
  class FunctionStmt extends Stmt {
    late FunctionType Type;
    late String Name;
    late List<Token> Paras;
    late List<Stmt> Body;

    FunctionStmt(FunctionType Type,
          String Name,
          List<Token> Paras,
          List<Stmt> Body) {
      this.Type = Type;
      this.Name = Name;
      this.Paras = Paras;
      this.Body = Body;
    }

    @override
    R Accept<R>(StmtVisitor<R> visitor) {
      return visitor.VisitFunctionStmt(this);
    }
  }
  // stmt-if
  class IfStmt extends Stmt {
    late Expr Condition;
    late Stmt ThenBranch;
    late Stmt? ElseBranch;

    IfStmt(Expr Condition, Stmt ThenBranch, Stmt? ElseBranch) {
      this.Condition = Condition;
      this.ThenBranch = ThenBranch;
      this.ElseBranch = ElseBranch;
    }

    @override
    R Accept<R>(StmtVisitor<R> visitor) {
      return visitor.VisitIfStmt(this);
    }
  }
  // stmt-assert
  class AssertStmt extends Stmt {
    late Expr expression;
    late String? message;
    late bool isErrorAssert;

    AssertStmt(Expr expression, String? message, bool isErrorAssert) {
      this.expression = expression;
      this.message = message;
      this.isErrorAssert = isErrorAssert;
    }

    @override
    R Accept<R>(StmtVisitor<R> visitor) {
      return visitor.VisitAssertStmt(this);
    }
  }
  // stmt-return
  class ReturnStmt extends Stmt {
    late Token Keyword;
    late Expr? Value;

    ReturnStmt(Token Keyword, Expr? Value) {
      this.Keyword = Keyword;
      this.Value = Value;
    }

    @override
    R Accept<R>(StmtVisitor<R> visitor) {
      return visitor.VisitReturnStmt(this);
    }
  }
  // stmt-breakcontinue
  class BreakContinueStmt extends Stmt {
    late bool IsBreak;

    BreakContinueStmt(bool IsBreak) {
      this.IsBreak = IsBreak;
    }

    @override
    R Accept<R>(StmtVisitor<R> visitor) {
      return visitor.VisitBreakContinueStmt(this);
    }
  }
  // stmt-var
  class VarStmt extends Stmt {
    late String Name;
    late Expr? Initializer;

    VarStmt(String Name, Expr? Initializer) {
      this.Name = Name;
      this.Initializer = Initializer;
    }

    @override
    R Accept<R>(StmtVisitor<R> visitor) {
      return visitor.VisitVarStmt(this);
    }
  }
  // stmt-while
  class WhileStmt extends Stmt {
    late Expr Condition;
    late Stmt Body;
    late Expr? Increment;

    WhileStmt(Expr Condition, Stmt Body, Expr? Increment) {
      this.Condition = Condition;
      this.Body = Body;
      this.Increment = Increment;
    }

    @override
    R Accept<R>(StmtVisitor<R> visitor) {
      return visitor.VisitWhileStmt(this);
    }
  }
  // stmt-repeat
  class RepeatStmt extends Stmt {
    late Expr Count;
    late Stmt Body;

    RepeatStmt(Expr Count, Stmt Body) {
      this.Count = Count;
      this.Body = Body;
    }

    @override
    R Accept<R>(StmtVisitor<R> visitor) {
      return visitor.VisitRepeatStmt(this);
    }
  }
