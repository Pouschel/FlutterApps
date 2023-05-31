import 'dart:convert';
import 'dart:io';

import 'package:eleu_lang_cli/eleu_lang_cli.dart';

void main(List<String> arguments) async {
  // ignore: unused_local_variable
  if (arguments.isNotEmpty) {
    var proc = CmdProcessorBase(print);
    var cnt = File(arguments[0]).readAsStringSync();
    proc.processLines(cnt);
    return;
  }
  CmdProcessor proc = CmdProcessor.createStdinOutProcessor();

  // await Future.delayed(Duration(seconds: 2));

  // print("after wait");
}

Stream<String> readLine() =>
    stdin.transform(utf8.decoder).transform(const LineSplitter());

void processLine(String line) {
  print(line);
}
