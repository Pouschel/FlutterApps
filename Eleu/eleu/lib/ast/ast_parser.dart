import '../eleu.dart';
import '../scanning.dart';
import 'ast_expr.dart';
import 'ast_stmt.dart';
import 'interpreter.dart';

abstract class ExprStmtBase {
  InputStatus? Status;

  @override
  String toString() => Status != null ? Status.toString() : "a ${this.runtimeType}";
}

class AstParser {
  static LiteralExpr NilLiteral = LiteralExpr(InterpreterStatics.NilValue), TrueLiteral = LiteralExpr(true), FalseLiteral = LiteralExpr(false);
  List<Token> tokens = List.empty();
  int current = 0;
  EleuOptions options;
  String fileName = "";
  int ErrorCount = 0;

  AstParser(this.options, this.fileName, this.tokens);

  List<Stmt> Parse() {
    List<Stmt> statements = List.empty(growable: true);
    while (!IsAtEnd()) {
      //Declaration(statements);
      Advance();
    }
    if (statements.isEmpty && Peek.Type == TokenType.TokenError && ErrorCount == 0) {
      ErrorAt(Peek.Status, Peek.StringValue);
    }
    return statements;
  }

  bool IsAtEnd() {
    var t = Peek.Type;
    return t == TokenType.TokenEof || t == TokenType.TokenError;
  }

  Token get Peek => tokens[current];
  Token get Previous => current > 0 ? tokens[current - 1] : tokens[0];
  Token Advance() {
    if (!IsAtEnd()) {
      current++;
      var tok = Peek;
      if (tok.Type == TokenType.TokenError) {
        ErrorAt(tok.Status, tok.StringValue);
      }
    }
    return Previous;
  }

  void ErrorAt(InputStatus status, String message) {
    ErrorCount++;
    options.WriteCompilerError(status, message);
  }
}
