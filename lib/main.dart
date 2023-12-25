import 'package:flutter/material.dart';
import 'screens/screen1.dart';
import 'screens/database_helper.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().initDatabase();
  runApp(MaterialApp(
    home: SplashScreen(),
    routes: {
      '/screen1': (context) => MyApp(),
    },
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen 1',
      home: Screen1(),
    );
  }
}
