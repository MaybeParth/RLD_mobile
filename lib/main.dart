import 'package:flutter/material.dart';
import 'home_screen.dart'; // Make sure this path is correct relative to your file structure

import 'package:flutter/material.dart';
import 'welcome_screen.dart'; // import the welcome screen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reactive Leg Drop',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: WelcomeScreen(), // this must be set
    );
  }
}
