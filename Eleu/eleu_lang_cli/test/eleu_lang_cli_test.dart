import 'package:eleu_lang_cli/eleu_lang_cli.dart';
import 'package:test/test.dart';

var t1 = """§filename Ex1.eleu
§code

pr int("ÄÜ");
if (x >= 4); { print(x); }
§end_code
§exit
""";
var r1 = """err Ex1.eleu(2,1,2,7): Cerr: Ein ';' wird hier erwartet.""";

bool testPair(String cmds, String result) {
  var buffer = StringBuffer();
  var proc = CmdProcessorBase((s)=>buffer.writeln(s));
  proc.processLines(cmds);
  var s = buffer.toString();
  return s.trim() == result.trim();
}

void main() {
  test('t1', () {
    expect(testPair(t1, r1), true);
  });
}
