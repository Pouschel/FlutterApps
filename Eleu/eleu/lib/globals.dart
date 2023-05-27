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
