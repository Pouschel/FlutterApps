import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eleu/eleu.dart';
import 'package:eleu/interpret/interpreter.dart';
import 'package:eleu/puzzles/parser.dart';
import 'package:eleu/puzzles/puzzle.dart';
import 'package:eleu/puzzles/types.dart';

enum CmdMode {
  /// next line as command expected
  command,
  code,
  puzzle,
}

class CallbackWriter extends TextWriter {
  void Function(String) callback;

  CallbackWriter(this.callback);

  // ignore: non_constant_identifier_names
  @override
  void WriteLine(String msg) {
    callback(msg);
  }
}

class CmdProcessorBase {
  final void Function(String) _output;
  CmdMode _mode = CmdMode.command;
  StringBuffer _buffer = StringBuffer();
  String _fileName = "";
  Interpreter? _interpreter;
  EEleuResult _lastResult = EEleuResult.NextStep;
  bool _outStateChanged = false;
  Stopwatch _watch = Stopwatch();
  PuzzleBundle? _bundle;
  int bundleIndex = 0;

  CmdProcessorBase(this._output);

  void processLines(String linesString) {
    var lines = linesString.split('\n');
    for (var l in lines) {
      processLine(l);
    }
  }

  void processLine(String line) {
    //stderr.writeln("<$line");
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
      case "ping":
        _sendInfo("Eleu Sprachserver bereit.");
        break;
      case "code":
        _mode = CmdMode.code;
        break;
      case "end_code":
      case "endcode":
        _endCodeHandler();
        break;
      case "puzzle":
        _mode = CmdMode.puzzle;
        break;
      case "endpuzzle":
        _endPuzzleHandler();
        break;
      case "exit":
        exit();
        break;
      case "stop":
        _stop();
        break;
      case "steps":
        _nextSteps(20);
        break;
      default:
        _sendInternalError("invalid command: $line");
        break;
    }
  }

  void exit() {}
  void _stop() {
    _fileName = "";
    _mode = CmdMode.command;
    _buffer = StringBuffer();
    _interpreter = null;
    _lastResult = EEleuResult.CompileError;
    _outStateChanged = false;
    _sendRunState(false);
  }

  void _sendString(String head, String s) {
    s.split("\n").forEach((element) {
      if (element.isNotEmpty) _output("$head $s");
    });
  }

  void _sendError(String msg) => _sendString("err", msg); // compiler and runtime errors
  void _sendInternalError(String msg) => _sendString("i_err", msg);
  void _sendInfo(String msg) => _sendString("info", msg); // information
  void _sendOutput(String msg) => _sendString("out", msg); // normal output from print
  void _sendRunState(bool running) => _sendString("state", "${running ? 1 : 0}");

  void _onErrorMsg(String s) => _sendError(s);
  void _onOutput(String s) {
    _sendOutput(s);
    _outStateChanged = true;
  }

  void _onPuzzleChanged(Puzzle? puzzle) {
    _outStateChanged = true;
  }

  void _endCodeHandler() {
    var code = _buffer.toString();
    _buffer.clear();
    var opt = EleuOptions()
      ..Out = CallbackWriter(_onOutput)
      ..Err = CallbackWriter(_onErrorMsg);
    _watch = Stopwatch()..start();
    var (result, interp) = Compile(code, _fileName, opt);
    _sendInfo("Skript übersetzt in ${_watch.elapsedMilliseconds} ms");
    _lastResult = result;
    if (result == EEleuResult.Ok) {
      _interpreter = interp;
      interp!.PuzzleChanged = _onPuzzleChanged;
      _lastResult = _interpreter!.start();
    }
    _sendRunState(_lastResult == EEleuResult.NextStep);
    _watch.stop();
    _watch.reset();
  }

  void _nextSteps(int maxSteps) {
    if (_interpreter == null || _lastResult != EEleuResult.NextStep) {
      //_sendInternalError("no program running");
      _sendRunState(false);
      return;
    }
    _watch.start();
    _outStateChanged = false;
    var interp = _interpreter!;
    for (var i = 0; i < maxSteps && _lastResult == EEleuResult.NextStep; i++) {
      _lastResult = interp.step();
      if (_outStateChanged) break;
    }
    if (_lastResult == EEleuResult.Ok) {
      _sendInfo("Skriptausführung wurde normal beendet.");
      _watch.stop();
      var ts = _watch.elapsedMicroseconds;
      int statementCount = _interpreter!.ExecutedInstructionCount;
      var speed = 1000000 * statementCount ~/ _watch.elapsedMicroseconds;
      _sendInfo(
          "$statementCount Befehle in ${_watch.elapsedMilliseconds} ms verarbeitet ($speed Bef./s).");
      _interpreter = null;
    } else if (_lastResult != EEleuResult.NextStep) {
      _sendError("Bei der Skriptausführung sind Fehler aufgetreten.");
      _interpreter = null;
    }
    _watch.stop();
    _sendRunState(_lastResult == EEleuResult.NextStep);
  }

  void _endPuzzleHandler() {
    var code = _buffer.toString();
    _buffer.clear();
    try {
      var bundle = ParseBundle(code);
      _bundle = bundle;
      bundleIndex = 0;
      if (bundle.Count>0)  _sendPuzzle(bundle[0]);
    } on PuzzleParseException catch (ex) {
      _sendError(ex.Message);
    }
  }

  void _sendPuzzle(Puzzle puzzle) {
    Map<String, dynamic> map = puzzle.toJson();
    var s = jsonEncode(map);

    _sendString("puzzle", s);
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
