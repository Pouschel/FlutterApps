import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:eleu/interpret/interpreter.dart';
import 'package:eleu/lang_server.dart';

String calculate() {
  return LangServer().Version;
}

class CmdProcessor {
  final Stream<String> _input;
  final void Function(String) _output;
  late StreamSubscription<String> _subscr;
  final ChunkRunner _runner =ChunkRunner();

  CmdProcessor(this._input, this._output) {
    _subscr = _input.listen(processLine);
    
  }
  void processLine(String line) {
    stderr.writeln("<$line");

    if (line == "exit") _subscr.cancel();
  }

  static CmdProcessor createStdinOutProcessor() {
    Stream<String> st = stdin.transform(utf8.decoder).transform(const LineSplitter());
    return CmdProcessor(st, print);
  }
}

class ChunkRunner {}
