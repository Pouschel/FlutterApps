import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eleu/eleu.dart';
import 'package:eleu/interpret/interpreter.dart';

enum CmdMode {
  /// next line as command expected
  command,
  code,
  puzzle,
}

class CmdProcessorBase extends TextWriter {
  final void Function(String) _output;
  CmdMode _mode = CmdMode.command;
  StringBuffer _buffer = StringBuffer();
  String _fileName = "";
  Interpreter? _interpreter;

  CmdProcessorBase(this._output);

  void processLines(String linesString) {
    var lines = linesString.split('\n');
    for (var l in lines) {
       processLine(l);
    }
  }

  void processLine(String line) {
    stderr.writeln("<$line");
    if (line.isEmpty) {
      if (_mode != CmdMode.command) _buffer.writeln();
      return;
    }

    if (line[0] != "§") {
      if (_mode != CmdMode.command) {
        _buffer.writeln(line);
      } else {
        stderr.writeln("command starting with § expected!");
      }
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
        exit();
        break;
      case "reset":
        _resetHandler();
        break;
      default:
        stderr.writeln("invalid command: $line");
        break;
    }
  }

  void exit() {}
  void _resetHandler() {
    _fileName = "";
    _mode = CmdMode.command;
    _buffer = StringBuffer();
  }

  void _sendOutput(String head, String s) {
    s.split("\n").forEach((element) {
      if (element.isNotEmpty) _output("$head $s");
    });
  }

  void _sendError(String msg) => _sendOutput("err", msg);
  void _sendInfo(String msg) => _sendOutput("info", msg);

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

class CmdProcessor extends CmdProcessorBase {
  static const String partBreak = "§break", endCmd = "§end";

  final Stream<String> input;
  late StreamSubscription<String> subscr;

  CmdProcessor(this.input, void Function(String) output) : super(output) {
    subscr = input.listen(processLine);
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

  @override
  void exit() {
    subscr.cancel();
  }
}
