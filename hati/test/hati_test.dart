import 'package:hati/hati.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    test('First Test', () {
      var s = "a,,b";
      var l= s.splitAndRemoveEmpty(',');
      expect(l.length, 2);
    });
  });
}
