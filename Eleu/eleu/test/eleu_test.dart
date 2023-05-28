import 'dart:math';

import 'package:eleu/eleu.dart';
import 'package:eleu/interpret/interpreter.dart';
import 'package:eleu/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("true ist true", () {
    print("Testing somthing");
    expect(1, 1);
  });
  test("t2", () => expect(1, 1));

  test("Native Func Register", () {
    var eopt = EleuOptions();
    var inp = Interpreter(eopt, [], []);
    var func = inp.globals.GetAt("print", 0) as NativeFunction;
    expect(func.Arity, -1);
    //func.Call(inp, ["Hallo Puschel"]);
  });
}
