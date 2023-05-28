import 'package:eleu/eleu.dart';
import 'package:eleu/interpret/interpreter.dart';
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
    
  });
}
