import 'package:flutter_test/flutter_test.dart';

void main() {
  test("true ist true", () {
    print("Testing somthing");
    expect(1, 1);
  });
  test("t2", () => expect(1,1));
}
