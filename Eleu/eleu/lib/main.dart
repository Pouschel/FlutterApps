import 'dart:io'; // Platform
import 'package:flutter/foundation.dart'; // kIsWeb

import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 6, 6, 132)),
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 1.3, fontSizeDelta: 2),
      ),
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}
