import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'welcome_screen.dart';
import 'bloc/patient/patient_bloc.dart';
import 'bloc/test/test_bloc.dart';
import 'bloc/events/patient_events.dart';
import 'bloc/events/test_events.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PatientBloc>(
          create: (context) => PatientBloc()..add(const LoadPatients()),
        ),
        BlocProvider<TestBloc>(
          create: (context) => TestBloc()..add(const InitializeTest()),
        ),
      ],
      child: MaterialApp(
        title: 'Reactive Leg Drop',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const WelcomeScreen(),
      ),
    );
  }
}
