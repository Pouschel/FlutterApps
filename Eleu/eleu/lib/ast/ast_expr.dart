// This file was generated by a tool. Do not edit!
// AST classes for expr
// ignore_for_file: prefer_initializing_formals
import '../scanning.dart';
import 'ast_parser.dart';

abstract class ExprVisitor<R> {
    R VisitAssignExpr(AssignExpr expr);
    R VisitBinaryExpr(BinaryExpr expr);
    R VisitCallExpr(CallExpr expr);
    R VisitGetExpr(GetExpr expr);
    R VisitGroupingExpr(GroupingExpr expr);
    R VisitLiteralExpr(LiteralExpr expr);
    R VisitLogicalExpr(LogicalExpr expr);
    R VisitSetExpr(SetExpr expr);
    R VisitSuperExpr(SuperExpr expr);
    R VisitThisExpr(ThisExpr expr);
    R VisitUnaryExpr(UnaryExpr expr);
    R VisitVariableExpr(VariableExpr expr);
  }

abstract class Expr extends ExprStmtBase {
  R Accept<R>(ExprVisitor<R> visitor);

  static AssignExpr Assign(String Name, Expr Value) => AssignExpr(Name, Value);
  static BinaryExpr Binary(Expr Left, Token Op, Expr Right) => BinaryExpr(Left, Op, Right);
  static CallExpr Call(Expr Callee, String? Method, bool CallSuper, List<Expr> Arguments) => CallExpr(Callee, Method, CallSuper, Arguments);
  static GetExpr Get(Expr Obj, String Name) => GetExpr(Obj, Name);
  static GroupingExpr Grouping(Expr Expression) => GroupingExpr(Expression);
  static LiteralExpr Literal(Object? Value) => LiteralExpr(Value);
  static LogicalExpr Logical(Expr Left, Token Op, Expr Right) => LogicalExpr(Left, Op, Right);
  static SetExpr Set(Expr Obj, String Name, Expr Value) => SetExpr(Obj, Name, Value);
  static SuperExpr Super(String Keyword, String Method) => SuperExpr(Keyword, Method);
  static ThisExpr This(String Keyword) => ThisExpr(Keyword);
  static UnaryExpr Unary(Token Op, Expr Right) => UnaryExpr(Op, Right);
  static VariableExpr Variable(String Name) => VariableExpr(Name);
}

  // Nested Expr classes here...
  // expr-assign
  class AssignExpr extends Expr {
    late String Name;
    late Expr Value;

    AssignExpr(String Name, Expr Value) {
      this.Name = Name;
      this.Value = Value;
    }

    @override
    R Accept<R>(ExprVisitor<R> visitor) {
      return visitor.VisitAssignExpr(this);
    }
  }
  // expr-binary
  class BinaryExpr extends Expr {
    late Expr Left;
    late Token Op;
    late Expr Right;

    BinaryExpr(Expr Left, Token Op, Expr Right) {
      this.Left = Left;
      this.Op = Op;
      this.Right = Right;
    }

    @override
    R Accept<R>(ExprVisitor<R> visitor) {
      return visitor.VisitBinaryExpr(this);
    }
  }
  // expr-call
  class CallExpr extends Expr {
    late Expr Callee;
    late String? Method;
    late bool CallSuper;
    late List<Expr> Arguments;

    CallExpr(Expr Callee,
          String? Method,
          bool CallSuper,
          List<Expr> Arguments) {
      this.Callee = Callee;
      this.Method = Method;
      this.CallSuper = CallSuper;
      this.Arguments = Arguments;
    }

    @override
    R Accept<R>(ExprVisitor<R> visitor) {
      return visitor.VisitCallExpr(this);
    }
  }
  // expr-get
  class GetExpr extends Expr {
    late Expr Obj;
    late String Name;

    GetExpr(Expr Obj, String Name) {
      this.Obj = Obj;
      this.Name = Name;
    }

    @override
    R Accept<R>(ExprVisitor<R> visitor) {
      return visitor.VisitGetExpr(this);
    }
  }
  // expr-grouping
  class GroupingExpr extends Expr {
    late Expr Expression;

    GroupingExpr(Expr Expression) {
      this.Expression = Expression;
    }

    @override
    R Accept<R>(ExprVisitor<R> visitor) {
      return visitor.VisitGroupingExpr(this);
    }
  }
  // expr-literal
  class LiteralExpr extends Expr {
    late Object? Value;

    LiteralExpr(Object? Value) {
      this.Value = Value;
    }

    @override
    R Accept<R>(ExprVisitor<R> visitor) {
      return visitor.VisitLiteralExpr(this);
    }
  }
  // expr-logical
  class LogicalExpr extends Expr {
    late Expr Left;
    late Token Op;
    late Expr Right;

    LogicalExpr(Expr Left, Token Op, Expr Right) {
      this.Left = Left;
      this.Op = Op;
      this.Right = Right;
    }

    @override
    R Accept<R>(ExprVisitor<R> visitor) {
      return visitor.VisitLogicalExpr(this);
    }
  }
  // expr-set
  class SetExpr extends Expr {
    late Expr Obj;
    late String Name;
    late Expr Value;

    SetExpr(Expr Obj, String Name, Expr Value) {
      this.Obj = Obj;
      this.Name = Name;
      this.Value = Value;
    }

    @override
    R Accept<R>(ExprVisitor<R> visitor) {
      return visitor.VisitSetExpr(this);
    }
  }
  // expr-super
  class SuperExpr extends Expr {
    late String Keyword;
    late String Method;

    SuperExpr(String Keyword, String Method) {
      this.Keyword = Keyword;
      this.Method = Method;
    }

    @override
    R Accept<R>(ExprVisitor<R> visitor) {
      return visitor.VisitSuperExpr(this);
    }
  }
  // expr-this
  class ThisExpr extends Expr {
    late String Keyword;

    ThisExpr(String Keyword) {
      this.Keyword = Keyword;
    }

    @override
    R Accept<R>(ExprVisitor<R> visitor) {
      return visitor.VisitThisExpr(this);
    }
  }
  // expr-unary
  class UnaryExpr extends Expr {
    late Token Op;
    late Expr Right;

    UnaryExpr(Token Op, Expr Right) {
      this.Op = Op;
      this.Right = Right;
    }

    @override
    R Accept<R>(ExprVisitor<R> visitor) {
      return visitor.VisitUnaryExpr(this);
    }
  }
  // expr-variable
  class VariableExpr extends Expr {
    late String Name;

    VariableExpr(String Name) {
      this.Name = Name;
    }

    @override
    R Accept<R>(ExprVisitor<R> visitor) {
      return visitor.VisitVariableExpr(this);
    }
  }
