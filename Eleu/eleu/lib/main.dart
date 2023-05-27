import 'dart:io'; // Platform
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';
import 'package:code_text_field/code_text_field.dart';
import 'eleu.dart';

void main() {
  setupWindow();
  runApp(const MainApp());
}

const double windowWidth = 360;
const double windowHeight = 640;

void setupWindow() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    WidgetsFlutterBinding.ensureInitialized();
    setWindowTitle('Eleu Tester');
    setWindowMinSize(const Size(600, 400));
    //setWindowMaxSize(const Size(windowWidth, windowHeight));
    var r = const Rect.fromLTWH(1950, 10, 1400, 700);
    getCurrentScreen().then((screen) {
      setWindowFrame(r);
    });
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);
    return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 42, 3, 97)),
          useMaterial3: true,
          textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 1.3, fontSizeDelta: 2),
          //brightness: Brightness.dark,
        ),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: CodeEditor(),
        ));
  }
}

class CodeEditor extends StatefulWidget {
  const CodeEditor({super.key});

  @override
  CodeEditorState createState() => CodeEditorState();
}

class EleuCodeController extends CodeController {
  static final pMap = {
    r'".*"': TextStyle(color: Colors.yellow),
    r'[a-zA-Z0-9]+\(.*\)': TextStyle(color: Colors.green),
  };
  static final sMap = {
    "void": TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
    "var": TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
  };

  EleuCodeController() : super(patternMap: pMap, stringMap: sMap);
}

class UpdateWriter extends TextWriter {
  late CodeEditorState _codeEditorState;
  UpdateWriter(CodeEditorState cs) {
    this._codeEditorState = cs;
  }

  @override
  void WriteLine(String msg) {
    _codeEditorState.infoText += "${msg}\n";
  }
}

class CodeEditorState extends State<CodeEditor> {
  final CodeController _codeController = EleuCodeController();
  String infoText = "";
  CodeEditorState() {
    _codeController.text = 'print("Hello World")';
  }

  void updateLoop() {
    var opt = EleuOptions();
    opt.Out = opt.Err = UpdateWriter(this);
    infoText = "";
    Globals.ScanAndParse(_codeController.text, "", opt);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          flex: 10,
          child: Container(
            margin: const EdgeInsets.all(3.0),
            padding: const EdgeInsets.all(3.0),
            decoration: BoxDecoration(border: Border.all(color: theme.dividerColor, width: 3)),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _codeController,
                textStyle: TextStyle(
                  fontFamily: 'SourceCode',
                  color: Colors.black,
                  fontSize: theme.textTheme.bodyMedium!.fontSize,
                ),
                lineNumberStyle: LineNumberStyle(textStyle: TextStyle(color: theme.primaryColorDark)),
                background: theme.canvasColor,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        ElevatedButton(onPressed: () => setState(updateLoop), child: Text("Run")),
        SizedBox(
          height: 10,
        ),
        Expanded(
          flex: 4,
          child: Container(
            margin: const EdgeInsets.all(5.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                infoText,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
