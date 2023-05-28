import '../eleu.dart';
import '../scanning.dart';
import '../types.dart';
import 'ast_expr.dart';
import 'ast_stmt.dart';

abstract class ExprStmtBase {
  InputStatus? Status;

  @override
  String toString() => Status != null ? Status.toString() : "a ${this.runtimeType}";
}

class AstParser {
  static LiteralExpr NilLiteral = LiteralExpr(NilValue),
      TrueLiteral = LiteralExpr(true),
      FalseLiteral = LiteralExpr(false);
  List<Token> tokens = List.empty();
  int current = 0;
  EleuOptions options;
  String fileName = "";
  int ErrorCount = 0;

  AstParser(this.options, this.fileName, this.tokens);

  List<Stmt> Parse() {
    List<Stmt> statements = List.empty(growable: true);
    while (!IsAtEnd()) {
      Declaration(statements);
    }
    if (statements.isEmpty && Peek.Type == TokenType.TokenError && ErrorCount == 0) {
      ErrorAt(Peek.Status, Peek.StringValue);
    }
    return statements;
  }

  void Declaration(List<Stmt> statements) {
    try {
      if (Match(TokenType.TokenVar)) statements.add(VarDeclaration());
      if (Match(TokenType.TokenFun))
        statements.add(Function(FunctionType.FunTypeFunction));
      else if (Match(TokenType.TokenClass))
        statements.add(ClassDeclaration());
      else
        statements.add(Statement());
    } on EleuParseError {
      Synchronize();
    }
  }

  Stmt Statement() {
    Stmt stmt;
    var curStat = CurrentInputStatus;
    if (Match(TokenType.TokenAssert))
      stmt = AssertStatement();
    else if (Match(TokenType.TokenLeftBrace))
      stmt = Stmt.Block(Block());
    else if (Match(TokenType.TokenIf))
      stmt = IfStatement();
    else if (Match(TokenType.TokenFor))
      stmt = ForStatement();
    else if (Match(TokenType.TokenReturn))
      stmt = ReturnStatement();
    else if (Match(TokenType.TokenWhile))
      stmt = WhileStatement();
    else if (Match(TokenType.TokenRepeat))
      stmt = RepeatStatement();
    else if (MatchList([TokenType.TokenContinue, TokenType.TokenBreak]))
      stmt = BreakContinueStatement();
    else
      stmt = ExpressionStatement();

    stmt.Status = curStat.Union(Previous.Status);
    return stmt;
  }

  Stmt AssertStatement() {
    string? msg;
    bool isErrorAssert = Check(TokenType.TokenBreak);
    if (isErrorAssert) Advance();
    Expr value = Expression();
    if (Match(TokenType.TokenString)) msg = Previous.StringStringValue;
    Consume(TokenType.TokenSemicolon,
        "Nach der Bedingung wird eine Zeichenkette oder ein ';' erwartet.");
    return Stmt.Assert(value, msg, isErrorAssert);
  }

  List<Stmt> Block() {
    List<Stmt> statements = [];
    while (!Check(TokenType.TokenRightBrace) && !IsAtEnd()) {
      Declaration(statements);
    }
    Consume(TokenType.TokenRightBrace, "Nach einem Block wird '}' erwartet.");
    return statements;
  }

  Stmt BreakContinueStatement() {
    Token keyword = Previous;
    Consume(
        TokenType.TokenSemicolon, "Nach '${keyword.StringValue}' wird ein ';' erwartet.");
    bool isBreak = keyword.Type == TokenType.TokenBreak;
    return Stmt.BreakContinue(isBreak);
  }

  Stmt ForStatement() {
    Consume(TokenType.TokenLeftParen, "Nach 'for' wird '(' erwartet.");
    Stmt? initializer;
    if (Match(TokenType.TokenSemicolon))
      initializer = null;
    else if (Match(TokenType.TokenVar))
      initializer = VarDeclaration();
    else
      initializer = ExpressionStatement();
    Expr? condition;
    if (!Check(TokenType.TokenSemicolon)) {
      condition = Expression();
    }
    Consume(TokenType.TokenSemicolon, "Expect ';' after loop condition.");
    Expr? increment;
    if (!Check(TokenType.TokenRightParen)) {
      increment = Expression();
    }
    Consume(TokenType.TokenRightParen, "Expect ')' after for clauses.");
    Stmt body = Statement();
    condition ??= Expr.Literal(true);
    if (increment != null) {
      body = Stmt.Block([body, Stmt.Expression(increment)]);
    }
    // increment is needed in case of a continue in a for-loop.
    body = Stmt.While(condition, body, increment);
    if (initializer != null) {
      body = Stmt.Block([initializer, body]);
    }
    return body;
  }

  Stmt IfStatement() {
    Consume(TokenType.TokenLeftParen, "Nach 'if' wird '(' erwartet.");
    Expr condition = Expression();
    Consume(TokenType.TokenRightParen, "Nach der 'if'-Bedingung wird ')' erwartet.",
        status: condition.Status);
    Stmt thenBranch = Statement();
    Stmt? elseBranch;
    if (Match(TokenType.TokenElse)) {
      elseBranch = Statement();
    }
    return Stmt.If(condition, thenBranch, elseBranch);
  }

  Stmt RepeatStatement() {
    Consume(TokenType.TokenLeftParen, "Nach 'repeat' wird '(' erwartet.");
    Expr numExpr = Expression();
    Consume(TokenType.TokenRightParen, "Nach der Anzahl wird ')' erwartet.",
        status: numExpr.Status);
    Stmt body = Statement();
    return Stmt.Repeat(numExpr, body);
  }

  Stmt ReturnStatement() {
    Token keyword = Previous;
    Expr? value;
    if (!Check(TokenType.TokenSemicolon)) {
      value = Expression();
    }
    Consume(TokenType.TokenSemicolon, "Nach dem Rückgabewert wird ein ';' erwartet.");
    return Stmt.Return(keyword, value);
  }

  Stmt WhileStatement() {
    Consume(TokenType.TokenLeftParen, "Nach 'while' wird '(' erwartet.");
    Expr condition = Expression();
    Consume(TokenType.TokenRightParen, "Nach der 'while'-Bedingung wird ')' erwartet.",
        status: condition.Status);
    Stmt body = Statement();
    return Stmt.While(condition, body, null);
  }

  Stmt VarDeclaration() {
    var cs = CurrentInputStatus;
    if (Peek.Type.index >= TokenType.TokenKeywordStart.index &&
        Peek.Type.index <= TokenType.TokenKeywordEnd.index) {
      ErrorAt(Peek.Status,
          "Das Schlüsselwort '${Peek.StringValue}' ist kein gültiger Variablenname.");
      throw EleuParseError();
    }
    Token name =
        Consume(TokenType.TokenIdentifier, "Der Name einer Variablen wird erwartet.");
    Expr? initializer;
    if (Match(TokenType.TokenEqual)) {
      initializer = Expression();
    }
    cs = cs.Union(CurrentInputStatus);
    Consume(
        TokenType.TokenSemicolon, "Nach einer Variablendeklaration wird ';' erwartet.");
    var vstm = Stmt.Var(name.StringValue, initializer);
    vstm.Status = cs;
    return vstm;
  }

  FunctionStmt Function(FunctionType kind) {
    Token name = Consume(TokenType.TokenIdentifier, "Expect $kind name.");
    Consume(TokenType.TokenLeftParen, "Expect '(' after $kind name.");
    List<Token> parameters = [];
    if (!Check(TokenType.TokenRightParen)) {
      do {
        if (parameters.length >= 255) {
          Error(Peek, "Can't have more than 255 parameters.");
        }
        parameters.add(Consume(TokenType.TokenIdentifier, "Expect parameter name."));
      } while (Match(TokenType.TokenComma));
    }
    Consume(TokenType.TokenRightParen, "Nach den Parametern wird ')' erwartet.");
    string tmsg = kind == FunctionType.FunTypeFunction ? "function" : "method";
    Consume(TokenType.TokenLeftBrace, "Expect '{' before $tmsg body.");
    List<Stmt> body = Block();
    return Stmt.Function(kind, name.StringValue, parameters, body);
  }

  Stmt ClassDeclaration() {
    var curStat = Previous.Status;
    Token name = Consume(TokenType.TokenIdentifier, "Expect class name.");
    VariableExpr? superclass;
    if (Match(TokenType.TokenLess)) {
      Consume(TokenType.TokenIdentifier, "Expect superclass name.");
      superclass = Expr.Variable(Previous.StringValue);
    }
    curStat = Previous.Status.Union(curStat);
    Consume(TokenType.TokenLeftBrace, "Expect '{' before class body.");
    List<FunctionStmt> methods = [];
    while (!Check(TokenType.TokenRightBrace) && !IsAtEnd()) {
      methods.add(Function(FunctionType.FunTypeMethod));
    }
    Consume(TokenType.TokenRightBrace, "Expect '}' after class body.");
    var cls = Stmt.Class(name.StringValue, superclass, methods);
    cls.Status = curStat;
    return cls;
  }

  Stmt ExpressionStatement() {
    if (Match(TokenType.TokenSemicolon)) return Stmt.Expression(NilLiteral);
    Expr expr = Expression();
    Consume(TokenType.TokenSemicolon, "Ein ';' wird hier erwartet.");
    return Stmt.Expression(expr);
  }

  Expr Expression() {
    var curStat = CurrentInputStatus;
    var expr = Assignment();
    expr.Status = curStat.Union(CurrentInputStatus);
    return expr;
  }

  Expr Assignment() {
    Expr expr = Or();
    if (Match(TokenType.TokenEqual)) {
      Token equals = Previous;
      Expr value = Assignment();
      if (expr is VariableExpr) {
        var name = expr.Name;
        return Expr.Assign(name, value);
      } else if (expr is GetExpr) {
        return Expr.Set(expr.Obj, expr.Name, value);
      }
      ErrorAt(expr.Status ?? equals.Status,
          "Diesem Ausdruck kann kein Wert zugewiesen werden.");
    }
    return expr;
  }

  Expr Or() {
    Expr expr = And();
    while (Match(TokenType.TokenOr)) {
      Token op = Previous;
      Expr right = And();
      expr = Expr.Logical(expr, op, right);
    }
    return expr;
  }

  Expr And() {
    Expr expr = Equality();
    while (Match(TokenType.TokenAnd)) {
      Token op = Previous;
      Expr right = Equality();
      expr = Expr.Logical(expr, op, right);
    }
    return expr;
  }

  Expr Equality() {
    Expr expr = Comparison();
    while (MatchList([TokenType.TokenBangEqual, TokenType.TokenEqualEqual])) {
      Token op = Previous;
      Expr right = Comparison();
      expr = Expr.Binary(expr, op, right);
    }
    return expr;
  }

  Expr Comparison() {
    Expr expr = Term();
    while (MatchList([
      TokenType.TokenGreater,
      TokenType.TokenGreaterEqual,
      TokenType.TokenLess,
      TokenType.TokenLessEqual
    ])) {
      Token op = Previous;
      Expr right = Term();
      expr = Expr.Binary(expr, op, right);
    }
    return expr;
  }

  Expr Term() {
    Expr expr = Factor();
    while (MatchList([TokenType.TokenMinus, TokenType.TokenPlus])) {
      Token op = Previous;
      Expr right = Factor();
      expr = Expr.Binary(expr, op, right);
    }
    return expr;
  }

  Expr Factor() {
    Expr expr = Unary();
    while (
        MatchList([TokenType.TokenSlash, TokenType.TokenStar, TokenType.TokenPercent])) {
      Token op = Previous;
      Expr right = Unary();
      expr = Expr.Binary(expr, op, right);
    }
    return expr;
  }

  Expr Unary() {
    if (MatchList([TokenType.TokenBang, TokenType.TokenMinus])) {
      Token op = Previous;
      Expr right = Unary();
      return Expr.Unary(op, right);
    }
    return Call();
  }

  Expr Call() {
    Expr expr = Primary();
    while (true) {
      if (Match(TokenType.TokenLeftParen)) {
        expr = FinishCall(expr, null);
      } else if (Match(TokenType.TokenDot)) {
        Token name =
            Consume(TokenType.TokenIdentifier, "Expect property name after '.'.");
        expr = Expr.Get(expr, name.StringValue);
      } else {
        break;
      }
    }
    return expr;
  }

  Expr FinishCall(Expr callee, String? mthName) {
    List<Expr> arguments = List.empty(growable: true);
    if (!Check(TokenType.TokenRightParen)) {
      do {
        if (arguments.length >= 255) {
          ErrorAt(CurrentInputStatus, "Can't have more than 255 arguments.");
        }
        arguments.add(Expression());
      } while (Match(TokenType.TokenComma));
    }
    Consume(TokenType.TokenRightParen, "Nach den Argumenten wird ')' erwartet.");
    return Expr.Call(callee, mthName, callee is SuperExpr, arguments);
  }

  Expr Primary() {
    if (Match(TokenType.TokenFalse)) return FalseLiteral;
    if (Match(TokenType.TokenTrue)) return TrueLiteral;
    if (Match(TokenType.TokenNil)) return NilLiteral;
    if (Match(TokenType.TokenNumber)) {
      return Expr.Literal(Number.TryParse(Previous.StringValue));
    }
    if (Match(TokenType.TokenString)) {
      return Expr.Literal(Previous.StringStringValue);
    }
    if (Match(TokenType.TokenSuper)) {
      Token keyword = Previous;
      Consume(TokenType.TokenDot, "Expect '.' after 'super'.");
      Token method = Consume(TokenType.TokenIdentifier, "Expect superclass method name.");
      return Expr.Super(keyword.StringValue, method.StringValue);
    }
    if (Match(TokenType.TokenThis)) return Expr.This(Previous.StringValue);
    if (Match(TokenType.TokenIdentifier)) {
      return Expr.Variable(Previous.StringValue);
    }
    if (Match(TokenType.TokenLeftParen)) {
      Expr expr = Expression();
      Consume(TokenType.TokenRightParen, "Expect ')' after expression.");
      return Expr.Grouping(expr);
    }
    throw Error(Previous, "Hier wird ein Ausdruck erwartet.");
  }

  bool Match(TokenType type) {
    return MatchList([type]);
  }

  bool MatchList(List<TokenType> types) {
    for (TokenType type in types) {
      if (Check(type)) {
        Advance();
        return true;
      }
    }
    return false;
  }

  Token Consume(TokenType type, String message, {InputStatus? status}) {
    if (Check(type)) return Advance();
    var stat = status ?? Previous.Status;
    ErrorAt(stat, message);
    throw EleuParseError();
  }

  bool Check(TokenType type) {
    if (IsAtEnd()) return false;
    return Peek.Type == type;
  }

  bool IsAtEnd() {
    var t = Peek.Type;
    return t == TokenType.TokenEof || t == TokenType.TokenError;
  }

  void Synchronize() {
    Advance();
    while (!IsAtEnd()) {
      if (Previous.Type == TokenType.TokenSemicolon) return;
      switch (Peek.Type) {
        case TokenType.TokenClass:
        case TokenType.TokenFun:
        case TokenType.TokenVar:
        case TokenType.TokenFor:
        case TokenType.TokenIf:
        case TokenType.TokenWhile:
        case TokenType.TokenReturn:
        case TokenType.TokenError:
          return;
        default:
      }
      Advance();
    }
  }

  Token get Peek => tokens[current];
  Token get Previous => current > 0 ? tokens[current - 1] : tokens[0];
  InputStatus get CurrentInputStatus => Peek.Status;
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

  EleuParseError Error(Token token, String message) {
    ErrorAt(token.Status, message);
    return EleuParseError();
  }
}
