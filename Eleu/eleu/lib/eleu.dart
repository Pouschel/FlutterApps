import 'Scanning.dart';

enum FunctionType { FunTypeFunction, FunTypeInitializer, FunTypeMethod, FunTypeScript }

enum EEleuResult { Ok, CompileError, CodeGenError, RuntimeError, NextStep }

class TextWriter {
  void WriteLine(String msg) {
    print(msg);
  }

  static final TextWriter Null = TextWriter();
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
    var msg = status.FileName.isEmpty ? message : "${status.Message}: Cerr: ${message}";
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

class Globals
{
  static void ScanAndParse(String source, String fileName, EleuOptions options)
	{
		var scanner = Scanner(source, fileName);
		var tokens = scanner.ScanAllTokens();
    for (var tok in tokens) {
      options.Out.WriteLine(tok.toString());
    }

		// var parser = AstParser(options, fileName, tokens);
		// var parseResult = parser.Parse();
		// return parseResult;
	}
}