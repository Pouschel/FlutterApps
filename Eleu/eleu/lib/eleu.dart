import 'dart:io';

import 'package:hati/hati.dart';

import 'ast/ast_parser.dart';
import 'ast/ast_stmt.dart';
import 'interpret/interpreter.dart';
import 'native.dart';
import 'scanning.dart';


enum FunctionType { FunTypeFunction, FunTypeInitializer, FunTypeMethod, FunTypeScript }

enum EEleuResult { Ok, CompileError, CodeGenError, RuntimeError, NextStep }

List<Stmt> ScanAndParse(String source, String fileName, EleuOptions options) {
  var scanner = Scanner(source, fileName);
  var tokens = scanner.ScanAllTokens();
  for (var tok in tokens) {
    options.Out.WriteLine(tok.toString());
  }

  var parser = AstParser(options, fileName, tokens);
  var parseResult = parser.Parse();
  for (var stmt in parseResult) {
    options.Out.WriteLine(stmt.toString());
  }
  return parseResult;
}

EEleuResult CompileAndRunAst(String source, String fileName, EleuOptions options) {
  var (res, vm) = Compile(source, fileName, options);
  if (res != EEleuResult.Ok) return res;
  return vm!.Interpret();
}

(EEleuResult, IInterpreter?) Compile(
    String source, String fileName, EleuOptions options) {
  var scanner = Scanner(source, fileName);
  var tokens = scanner.ScanAllTokens();
  var parser = AstParser(options, fileName, tokens);
  var parseResult = parser.Parse();
  var presult = parser.ErrorCount > 0 ? EEleuResult.CompileError : EEleuResult.Ok;

  if (presult != EEleuResult.Ok) return (presult, null);
  var interpreter = Interpreter(options, parseResult, tokens);
  return (presult, interpreter);
}

bool RunFile(string path, TextWriter tw) {
  var opt = EleuOptions();
  opt.Out = opt.Err = tw;
  var source = File(path).readAsStringSync();
  var result = CompileAndRunAst(source, path, opt);
  return result == EEleuResult.Ok;
}

class TextWriter {
  void WriteLine(String msg) {
    print(msg);
  }

  static final TextWriter Null = TextWriter();
}

class StringWriter extends TextWriter {
  final StringBuffer _buffer = StringBuffer();

  @override
  void WriteLine(String msg) {
    _buffer.writeln(msg);
  }

  @override
  String toString() => _buffer.toString();
}

class EleuOptions {
  bool DumpStackOnError = true;
  bool UseDebugger = false;
  bool ThrowOnAssert = false;
  TextWriter Out = TextWriter.Null;
  TextWriter Err = TextWriter.Null;
  bool PrintByteCode = false;
  bool UseInterpreter = true;

  void WriteCompilerError(InputStatus status, String message) {
    var msg = "${status.Message}: Cerr: ${message}";
    Err.WriteLine(msg);
    //print(msg);
  }
}

abstract class EleuException implements Exception {
  InputStatus? Status;
  String Message = "";

  EleuException(InputStatus? status, String msg) {
    this.Status = status;
    this.Message = msg;
  }
}

class EleuParseError extends EleuException {
  EleuParseError() : super(null, "");
}

class EleuRuntimeError extends EleuException {
  EleuRuntimeError(InputStatus? status, String msg) : super(status, msg);
}

class EleuResolverError extends EleuRuntimeError {
  EleuResolverError(InputStatus? status, String msg) : super(status, msg);
}

class EleuAssertionFail extends EleuRuntimeError {
  EleuAssertionFail(InputStatus? status, String msg) : super(status, msg);
}

typedef NativeFn = Object Function(List<Object>);

abstract class IInterpreter {
  EleuOptions options;
  InputStatus currentStatus = InputStatus.Empty;
  //Puzzle? Puzzle;
  //event PuzzleChangedDelegate? PuzzleChanged;
  int FrameTimeMs = 100;
  int InstructionCount = 0;
  IInterpreter(this.options) {
    this.options = options;
    NativeFunctions.DefineAll(this);
    //TODO NativeFunctionBase.DefineAll<PuzzleFunctions>(this);
  }
  EEleuResult Interpret();
  void RuntimeError(String msg);
  void DefineNative(String name, NativeFn function);

  //EEleuResult InterpretWithDebug(CancellationToken token);

  // void NotifyPuzzleChange(Puzzle? newPuzzle, float animateState)
  // {
  // 	PuzzleChanged?.Invoke(newPuzzle, animateState);
  // }
}
