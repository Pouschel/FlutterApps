import 'dart:io'; // Platform
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';
import 'package:code_text_field/code_text_field.dart';

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
    return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 97, 3, 48)),
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

class CodeEditorState extends State<CodeEditor> {
  CodeController? _codeController;

  @override
  void initState() {
    super.initState();
    const source = "var x=2;\n\n";
    // Instantiate the CodeController
    _codeController = CodeController(
      text: source,
      patternMap: {
        r'".*"': TextStyle(color: Colors.yellow),
        r'[a-zA-Z0-9]+\(.*\)': TextStyle(color: Colors.green),
      },
      stringMap: {
        "void": TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        "var": TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      },
    );
  }

  @override
  void dispose() {
    _codeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          flex: 10,
          child: SingleChildScrollView(
            child: CodeField(
              controller: _codeController!,
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
        SizedBox(
          height: 10,
        ),
        ElevatedButton(onPressed: null, child: Text("Run")),
        SizedBox(
          height: 10,
        ),
        Expanded(
          flex: 4,
          child: Text("data\nZ2"),
        ),
      ],
    );
  }
}
