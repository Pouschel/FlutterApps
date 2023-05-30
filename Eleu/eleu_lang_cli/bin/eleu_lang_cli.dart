import 'dart:convert';
import 'dart:io';

import 'package:eleu_lang_cli/eleu_lang_cli.dart';

void main(List<String> arguments) {
  print(calculate());
  print('1 + 1 = ...');
  var line = stdin.readLineSync(encoding: utf8);
  print(line?.trim() == '2' ? 'Yup!' : 'Nope :(');
}
