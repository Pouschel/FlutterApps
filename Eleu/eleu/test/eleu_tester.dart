import 'dart:io';

import 'package:eleu/eleu.dart';
import 'package:eleu/types.dart';

class EleuTester {
  int nTests = 0, nSuccess = 0, nFail = 0, nSkipped = 0;
  Map<string, Duration> benchMarkResults = <string, Duration>{};

  int testDirLen = 0;

  void TestFile(string fileName) {
    string? msg;
    try {
      nTests++;
      var source = File(fileName).readAsStringSync();
      var sw = StringWriter();
      RunTestCode(fileName, source, sw);
      var res = ProcessScriptOutput(sw.toString()).trimRight();
      var expected = GetSourceOutput(source).trimRight();
      if (res == expected) {
        nSuccess++;
        return;
      }
      if (expected.isEmpty) {
        nSkipped++;
        return;
      }
      msg = '''"..........got.......
${res}
.......expected.........
${expected}''';
    } on EleuAssertionFail catch (aex) {
      var location = aex.Status != null ? aex.Status!.Message : "";
      msg = "${location}: ${aex.Message}";
    } on Exception catch (ex) {
      msg = ex.toString();
    }
    //if (msg == null) return;
    nFail++;
    //lock (this)
    {
      // var col = Console.ForegroundColor;
      // Console.ForegroundColor = ConsoleColor.Magenta;
      print("\r${fileName.replaceAll("\\", "/")}              ");
      //Console.ForegroundColor = col;
      print(msg);
    }
  }

  bool RunTestCode(string path, string source, TextWriter tw) {
    var opt = EleuOptions();
    opt.Out = tw;
    opt.Err = tw;
    opt.DumpStackOnError = false;
    opt.UseDebugger = false;
    opt.ThrowOnAssert = true;
    var cres = CompileAndRunAst(source, path, opt);
    return cres == EEleuResult.Ok;
  }

  static string GetSourceOutput(string source) {
    var searches = ["// expect: ", "//? ", "// expect runtime error: ", "//Cerr: "];

    var sw = StringBuffer();
    var lines = source.split('\n');
    for (var line in lines) {
      for (int i = 0; i < searches.length; i++) {
        string? search = searches[i];
        int idx = line.indexOf(search);
        if (idx < 0) continue;
        if (idx >= 0) {
          int start = idx + (i < 3 ? search.length : 2);
          var resString = line.substring(start).trimRight();
          sw.writeln(resString);
          break;
        }
      }
    }
    return sw.toString();
  }

  string ProcessScriptOutput(string s) {
    var lines = s.split('\n');
    var sw = StringBuffer();
    for (var line in lines) {
      if (line.startsWith("Die _puzzle() Funktion überschreibt das aktive Puzzle"))
        continue;
      var l = line.trimRight();
      int idx = l.indexOf("): ");
      if (idx >= 0) l = l.substring(idx + 3);
      sw.writeln(l);
    }
    return sw.toString();
  }

 void RunActionInDir(string dir, void Function(string) action)  {
    var diro = Directory(dir);
    string locDir = GetFileName(dir);
    if (locDir[0] == '-') return;

    var entities = diro.listSync().toList();
    final Iterable<File> files = entities.whereType<File>();
    for (var file in files) {
      var fn = file.absolute.path;
      if (IsIgnored(fn)) continue;
      action(fn);
    }
    var subdirs = entities.whereType<Directory>();
    for (var idir in subdirs) {
      RunActionInDir(idir.absolute.path, action);
    }
  }

  bool IsIgnored(string file) {
    print("\r${file.substring(testDirLen)}           ");
    var baseName = GetFileName(file);
    if (baseName[0] == '-') {
      nSkipped++;
      return true;
    }
    return false;
  }

  RunTests(string dir)  {
    testDirLen = dir.length;
    printInfo("Start Testing dir: ${dir}");
    var watch = Stopwatch();
    RunActionInDir(dir, TestFile);

    print("");
    printInfo("---- Test Results ---");
    //var f=NumberFormat("###0");
    printWarning("Skipped: ${nSkipped}");
    printInfo("Tests  : ${nTests} in ${watch.elapsedMicroseconds} ms");
    printSuccess("Success: ${nSuccess}");
    if (nFail > 0) printError("Fail   : ${nFail}");
  }
}

string GetFileName(string fn) {
  return File(fn).uri.pathSegments.last;
}

void printWarning(String text) {
  print('\x1B[33m$text\x1B[0m');
}

void printError(String text) {
  print('\x1B[31m$text\x1B[0m');
}

void printInfo(String text) {
  print('\x1B[34m$text\x1B[0m');
}

void printSuccess(String text) {
  print('\x1B[32m$text\x1B[0m');
}

void main() {
  var tw = TextWriter();
  var fn = "C:/Code/OwnApps/EleuStudio/EleuSrc/Tests/variable/unreached_undefined.eleu";
  var tdir = "C:/Code/OwnApps/EleuStudio/EleuSrc/Tests";
  var etest = EleuTester();
  etest.RunTests(tdir);
  etest.TestFile(fn);
}
