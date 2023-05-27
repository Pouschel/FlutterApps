// ignore_for_file: file_names

import 'dart:math';

class InputStatus {
  String FileName = "";

  int LineStart = 1, LineEnd = 1;

  int ColStart = 1, ColEnd = 1;

  InputStatus({
    this.FileName = "",
    this.LineStart = 1,
    this.LineEnd = 1,
    this.ColStart = 1,
    this.ColEnd = 1,
  });

  bool get IsEmpty {
    return LineStart == LineEnd && ColStart == ColEnd;
  }

  void NextLine() {
    this.LineStart++;
    this.LineEnd++;
    this.ColStart = this.ColEnd = 1;
  }

  void NextChar() {
    this.ColStart++;
    this.ColEnd++;
  }

  InputStatus Union(InputStatus other) {
    var result = this;
    if (result.FileName != this.FileName) return InputStatus();
    if (other.LineStart < this.LineStart) {
      result.LineStart = other.LineStart;
      result.ColStart = other.ColStart;
    } else if (other.LineStart == this.LineStart) result.ColStart = min(this.ColStart, other.ColStart);
    if (other.LineEnd > this.LineEnd) {
      result.LineEnd = other.LineEnd;
      result.ColEnd = other.ColEnd;
    } else if (other.LineEnd == this.LineEnd) result.ColEnd = max(this.ColEnd, other.ColEnd);
    return result;
  }

  String get Message => "${FileName}(${LineStart},${ColStart},${LineEnd},${ColEnd})";

  String ToString() => Message;

  // String ReadPartialText()
  // {
  // 	var lines= File.ReadAllLines(FileName);
  // 	var sb =  StringBuilder();
  // 	for (int i = LineStart; i <= LineEnd; i++)
  // 	{
  // 		if (i <= 0 || i > lines.Length) continue;
  // 		var line = lines[i-1];
  // 		if (LineStart == LineEnd)
  // 			sb.Append(line[(ColStart - 1)..(ColEnd - ColStart +1)]);
  // 		else if (i == LineStart)
  // 			sb.Append(lines[(ColStart - 1)..]);
  // 		else if (i == LineEnd)
  // 			sb.Append(lines[..(ColEnd -1)]);
  // 		else
  // 			sb.AppendLine(line);
  // 	}
  // 	return sb.ToString();
  // }

  static final InputStatus Empty = InputStatus();

  static InputStatus Parse(String hint) {
    int idx = hint.indexOf("): ");
    if (idx < 0) return Empty;
    int idx0 = hint.lastIndexOf('(', idx);
    if (idx0 < 0) return Empty;
    var fileName = hint.substring(0, idx0);
    var numbers = hint.substring((idx0 + 1), idx).split(',').map((s) => int.parse(s)).toList();
    return InputStatus(
      FileName: fileName,
      LineStart: numbers[0],
      ColStart: numbers[1],
      LineEnd: numbers[2],
      ColEnd: numbers[3],
    );
  }
}

enum TokenType {
  // Single-character tokens.
  TokenLeftParen,
  TokenRightParen,
  TokenLeftBrace,
  TokenRightBrace,
  TokenLeftBracket,
  TokenRightBracket,
  TokenComma,
  TokenSemicolon,
  TokenDot,
  TokenMinus,
  TokenPlus,
  TokenSlash,
  TokenStar,
  TokenPercent,
  // One or two character tokens.
  TokenBang,
  TokenBangEqual, // !, !=
  TokenEqual,
  TokenEqualEqual,
  TokenGreater,
  TokenGreaterEqual,
  TokenLess,
  TokenLessEqual,
  // Literals.
  TokenIdentifier,
  TokenString,
  TokenNumber,
  // Keywords.
  TokenKeywordStart,
  TokenAnd,
  TokenBreak,
  TokenClass,
  TokenContinue,
  TokenElse,
  TokenFalse,
  TokenFor,
  TokenFun,
  TokenIf,
  TokenNil,
  TokenOr,
  TokenAssert,
  TokenReturn,
  TokenSuper,
  TokenThis,
  TokenTrue,
  TokenVar,
  TokenWhile,
  TokenRepeat,
  TokenKeywordEnd,
  // Error, EOF
  TokenError,
  TokenEof
}

class Token {
  final TokenType Type;
  int Start;
  int End;
  InputStatus Status = InputStatus.Empty;
  final String Source;

  Token({this.Type = TokenType.TokenError, this.Source = "", this.Start = 0, this.End = 0, Status}) {
    // ignore: prefer_initializing_formals
    this.Status = Status;
  }

  String get StringValue => Source.substring(Start, End);
  String get StringStringValue => Source.substring((Start + 1), (End - 1));
  @override
  String toString() => "${Type}: ${StringValue}";
}

class Scanner {
  int start = 0;
  int current = 0;
  String _fileName = "";
  String _source = "";
  int line = 1, col = 1, startLine = 1, startCol = 1;

  Scanner({source = "", fileName = ""}) {
    this._fileName = fileName;
    this._source = source;
    this.start = this.current = 0;
    this.line = this.col = 1;
    this.startLine = 1;
    this.startCol = 1;
  }

  Token ScanToken() {
    SkipWhitespace();
    start = current;
    startLine = line;
    startCol = col;
    if (IsAtEnd) return MakeToken(TokenType.TokenEof);
    var c = Advance();
    if (IsAlpha(c)) return Identifier();
    if (IsDigit(c)) return Number();
    switch (c) {
      case '(':
        return MakeToken(TokenType.TokenLeftParen);
      case ')':
        return MakeToken(TokenType.TokenRightParen);
      case '{':
        return MakeToken(TokenType.TokenLeftBrace);
      case '}':
        return MakeToken(TokenType.TokenRightBrace);
      case '[':
        return MakeToken(TokenType.TokenLeftBracket);
      case ']':
        return MakeToken(TokenType.TokenRightBracket);
      case ';':
        return MakeToken(TokenType.TokenSemicolon);
      case ',':
        return MakeToken(TokenType.TokenComma);
      case '.':
        return MakeToken(TokenType.TokenDot);
      case '-':
        return MakeToken(TokenType.TokenMinus);
      case '+':
        return MakeToken(TokenType.TokenPlus);
      case '/':
        return MakeToken(TokenType.TokenSlash);
      case '*':
        return MakeToken(TokenType.TokenStar);
      case '%':
        return MakeToken(TokenType.TokenPercent);
      case '!':
        return MakeToken(Match('=') ? TokenType.TokenBangEqual : TokenType.TokenBang);
      case '=':
        return MakeToken(Match('=') ? TokenType.TokenEqualEqual : TokenType.TokenEqual);
      case '<':
        return MakeToken(Match('=') ? TokenType.TokenLessEqual : TokenType.TokenLess);
      case '>':
        return MakeToken(Match('=') ? TokenType.TokenGreaterEqual : TokenType.TokenGreater);
      case '"':
        return ScanString();
      default:
        return ErrorToken("Unerwartetes Zeichen: '${c}'");
    }
  }

  List<Token> ScanAllTokens() {
    var result = List<Token>.empty(growable: true);
    while (true) {
      var token = ScanToken();
      result.add(token);
      if (token.Type == TokenType.TokenEof || token.Type == TokenType.TokenError) break;
    }
    return result;
  }

  static bool isWhitespace(String ch) {
    if (ch.isEmpty) {
      return false;
    }
    int rune = ch.codeUnitAt(0);
    return (rune >= 0x0009 && rune <= 0x000D) ||
        rune == 0x0020 ||
        rune == 0x0085 ||
        rune == 0x00A0 ||
        rune == 0x1680 ||
        rune == 0x180E ||
        (rune >= 0x2000 && rune <= 0x200A) ||
        rune == 0x2028 ||
        rune == 0x2029 ||
        rune == 0x202F ||
        rune == 0x205F ||
        rune == 0x3000 ||
        rune == 0xFEFF;
  }

  static bool isLetter(String ch) {
    if (ch.isEmpty) {
      return false;
    }

    int rune = ch.codeUnitAt(0);
    return (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);
  }

  static bool isDigit(String? ch) {
    if (ch == null) {
      return false;
    }

    if (ch.isEmpty) {
      return false;
    }

    int rune = ch.codeUnitAt(0);
    return rune ^ 0x30 <= 9;
  }

  static bool IsDigit(String c) => isDigit(c);
  static bool IsAlpha(String c) => isLetter(c) || c == '_';
  Token Number() {
    while (IsDigit(Peek())) Advance();
    // Look for a fractional part.
    if (Peek() == '.' && IsDigit(Peek(n: 1))) {
      // Consume the ".".
      Advance();
      while (IsDigit(Peek())) Advance();
    }
    return MakeToken(TokenType.TokenNumber);
  }

  Token Identifier() {
    while (IsAlpha(Peek()) || IsDigit(Peek())) Advance();
    return MakeToken(GetIdentOrKeywordType());
  }

  TokenType GetIdentOrKeywordType() {
    switch (PeekFromStart(0)) {
      case 'a':
        switch (PeekFromStart(1)) {
          case 'n':
            return CheckKeyword(2, "and", TokenType.TokenAnd);
          case 's':
            return CheckKeyword(2, "assert", TokenType.TokenAssert);
        }
        break;
      case 'b':
        return CheckKeyword(1, "break", TokenType.TokenBreak);
      case 'c':
        switch (PeekFromStart(1)) {
          case 'l':
            return CheckKeyword(2, "class", TokenType.TokenClass);
          case 'o':
            return CheckKeyword(2, "continue", TokenType.TokenContinue);
        }
        break;
      case 'e':
        return CheckKeyword(1, "else", TokenType.TokenElse);
      case 'f':
        switch (PeekFromStart(1)) {
          case 'a':
            return CheckKeyword(2, "false", TokenType.TokenFalse);
          case 'o':
            return CheckKeyword(2, "for", TokenType.TokenFor);
          case 'u':
            if (CheckKeyword(2, "fun", TokenType.TokenFun) == TokenType.TokenFun)
              return TokenType.TokenFun;
            else
              return (CheckKeyword(2, "function", TokenType.TokenFun));
        }
        break;
      case 'i':
        return CheckKeyword(1, "if", TokenType.TokenIf);
      case 'n':
        return CheckKeyword(1, "nil", TokenType.TokenNil);
      case 'o':
        return CheckKeyword(1, "or", TokenType.TokenOr);
      case 'r':
        switch (PeekFromStart(2)) {
          case 'p':
            return CheckKeyword(1, "repeat", TokenType.TokenRepeat);
          case 't':
            return CheckKeyword(1, "return", TokenType.TokenReturn);
        }
        break;
      case 's':
        return CheckKeyword(1, "super", TokenType.TokenSuper);
      case 't':
        switch (PeekFromStart(1)) {
          case 'h':
            return CheckKeyword(2, "this", TokenType.TokenThis);
          case 'r':
            return CheckKeyword(2, "true", TokenType.TokenTrue);
        }
        break;
      case 'v':
        return CheckKeyword(1, "var", TokenType.TokenVar);
      case 'w':
        return CheckKeyword(1, "while", TokenType.TokenWhile);
    }
    return TokenType.TokenIdentifier;
  }

  TokenType CheckKeyword(int start, String rest, TokenType type) {
    if (this.current - this.start != rest.length) return TokenType.TokenIdentifier;
    for (int i = start; i < rest.length; i++) {
      if (_source[this.start + i] != rest[i]) return TokenType.TokenIdentifier;
    }
    return type;
  }

  Token ScanString() {
    while (Peek() != '"' && !IsAtEnd) {
      if (Peek() == '\n') {
        line++;
        col = 0;
      }
      Advance();
    }
    if (IsAtEnd) return ErrorToken("Nicht abgeschlossene Zeichenkette.");

    // The closing quote.
    Advance();
    return MakeToken(TokenType.TokenString);
  }

  void SkipWhitespace() {
    while (true) {
      var c = Peek();
      switch (c) {
        case ' ':
        case '\r':
        case '\t':
          Advance();
          break;
        case '\n':
          line++;
          col = 0;
          Advance();
          break;
        case '/':
          if (Peek(n: 1) == '/') {
            // A comment goes until the end of the line.
            while (Peek() != '\n' && !IsAtEnd) Advance();
          } else {
            return;
          }
          break;
        default:
          if (isWhitespace(c)) continue;
          return;
      }
    }
  }

  String Advance() {
    col++;
    return _source[current++];
  }

  String Peek({int n = 0}) => current >= _source.length - n ? String.fromCharCode(0) : _source[current + n];
  String PeekFromStart(int n) => start >= _source.length - n ? String.fromCharCode(0) : _source[start + n];
  bool get IsAtEnd => current >= _source.length;

  bool Match(String expected) {
    if (IsAtEnd) return false;
    if (_source[current] != expected) return false;
    current++;
    return true;
  }

  InputStatus CreateStatus() {
    return InputStatus(FileName: _fileName, LineStart: startLine, LineEnd: line, ColStart: startCol, ColEnd: col);
  }

  Token MakeToken(TokenType type) {
    Token token = Token(Type: type, Start: start, End: current, Source: _source, Status: CreateStatus());
    return token;
  }

  Token ErrorToken(String message) {
    Token token = Token(
      Type: TokenType.TokenError,
      Start: 0,
      End: message.length,
      Source: message,
      Status: CreateStatus(),
    );
    return token;
  }
}
