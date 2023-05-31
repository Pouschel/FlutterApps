import 'dart:convert';
import 'dart:io';

import 'package:eleu_lang_cli/eleu_lang_cli.dart';

void main(List<String> arguments) {
  // ignore: unused_local_variable
  CmdProcessor proc = arguments.isEmpty
      ? CmdProcessor.createStdinOutProcessor()
      : CmdProcessor.createFileProcessor(arguments[0]);
}

Stream<String> readLine() =>
    stdin.transform(utf8.decoder).transform(const LineSplitter());

void processLine(String line) {
  print(line);
}
