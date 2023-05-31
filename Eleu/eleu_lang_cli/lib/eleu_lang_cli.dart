import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eleu/eleu.dart';
import 'package:eleu/interpret/interpreter.dart';
import 'package:eleu/lang_server.dart';

String calculate() {
  return LangServer().Version;
}

enum CmdMode {
  /// next line as command expected
  command,
  code,
  puzzle,
}

class CmdProcessor extends TextWriter {
  static const String partBreak = "§break", endCmd = "§end";

  final Stream<String> _input;
  final void Function(String) _output;
  late StreamSubscription<String> _subscr;
  CmdMode _mode = CmdMode.command;
  StringBuffer _buffer = StringBuffer();
  String _fileName = "";
  IInterpreter? _interpreter;

  CmdProcessor(this._input, this._output) {
    _subscr = _input.listen(processLine);
  }
  void processLine(String line) {
    if (_mode != CmdMode.command) {
      _buffer.writeln(line);
      return;
    }
    if (line.isEmpty) return;
    //stderr.writeln("<$line");
    if (line[0] != "§") {
      stderr.writeln("command starting with § expected!");
      return;
    }
    line = line.substring(1).trim();
    if (line.startsWith("filename")) {
      _fileName = line.substring(8).trim();
      return;
    }
    switch (line) {
      case "code":
        _mode = CmdMode.code;
        break;
      case "end_code":
      case "endcode":
        _endCodeHandler();
        break;
      case "exit":
        _subscr.cancel();
        break;
      case "reset":
        _resetHandler();
        break;
      default:
        stderr.writeln("invalid command: $line");
        break;
    }
  }

  static CmdProcessor createStdinOutProcessor() {
    Stream<String> st = stdin.transform(utf8.decoder).transform(const LineSplitter());
    return CmdProcessor(st, print);
  }

  static CmdProcessor createFileProcessor(String fileName) {
    Stream<List<int>> stream = File(fileName).openRead();
    Stream<String> st = stream.transform(utf8.decoder).transform(LineSplitter());
    return CmdProcessor(st, print);
  }

  void _resetHandler() {
    _fileName = "";
    _mode = CmdMode.command;
    _buffer = StringBuffer();
  }

  void _sendOutput(String s) {
    _output(s);
  }

  void _sendError(String msg) => _output("err $msg");

  void _endCodeHandler() {
    var code = _buffer.toString();
    var swErr = StringWriter(), swOut = StringWriter();
    var opt = EleuOptions()
      ..Out = swOut
      ..Err = swErr;
    var (result, interp) = Compile(code, _fileName, opt);
    if (result != EEleuResult.Ok) {
      _sendError(swErr.toString());
      return;
    }
    _interpreter = interp;
  }
}
