import 'package:flutter/material.dart';
import 'home_screen.dart'; // Make sure this path is correct relative to your file structure

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reactive Leg Drop',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(), // << Use a separate stateful widget
    );
  }
}
