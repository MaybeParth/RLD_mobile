import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/patients.dart';
import '../bloc/patient/patient_bloc.dart';
import '../bloc/events/patient_events.dart';
import '../bloc/states/patient_states.dart';
import 'simple_test_screen_bloc.dart';
import '../db/patient_database.dart';

class PatientFormScreenBloc extends StatefulWidget {
  const PatientFormScreenBloc({super.key});

  @override
  State<PatientFormScreenBloc> createState() => _PatientFormScreenBlocState();
}

class _PatientFormScreenBlocState extends State<PatientFormScreenBloc> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _commentsController = TextEditingController();
  String _selectedGender = 'Male';

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'New Patient Form',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<PatientBloc, PatientState>(
        listener: (context, state) {
          if (state is PatientOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(fontSize: 18),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Navigate to test screen with the new patient
            () async {
              final newId = _idController.text;
              final fetched = await PatientDatabase.getPatient(newId);
              if (mounted && fetched != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SimpleTestScreenBloc(patient: fetched),
                  ),
                );
              } else if (mounted && state.patients.isNotEmpty) {
                final fallback = state.patients.last;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SimpleTestScreenBloc(patient: fallback),
                  ),
                );
              }
            }();
          } else if (state is PatientError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(fontSize: 18),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Patient Information',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'Patient ID *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Please enter Patient ID' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Please enter Name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age (years)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Non-Binary', child: Text('Non-Binary')),
                    DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value ?? _selectedGender;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _commentsController,
                  decoration: const InputDecoration(
                    labelText: 'Medical History / Comments',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 32),
                
                BlocBuilder<PatientBloc, PatientState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state is PatientLoading ? null : _submitForm,
                      child: state is PatientLoading
                          ? const Text('Creating Patient...')
                          : const Text('Create Patient'),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  

  void _submitForm() {
    if (_formKey.currentState?.validate() == true) {
      // print('🔍 Creating new patient...');
      // print('ID: ${_idController.text}');
      // print('Name: ${_nameController.text}');
      // print('Age: ${_ageController.text}');
      // print('Gender: $_selectedGender');
      // print('Condition: ${_commentsController.text}');
      
      final patient = Patient(
        id: _idController.text,
        name: _nameController.text,
        age: _ageController.text,
        gender: _selectedGender,
        condition: _commentsController.text,
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      );

      print('🔍 Patient created, sending AddPatient event...');
      context.read<PatientBloc>().add(AddPatient(patient));
    } else {
      print('❌ Form validation failed');
    }
  }
}
