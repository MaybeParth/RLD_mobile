import 'package:flutter/material.dart';
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
  final _genderController = TextEditingController();
  final _commentsController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Patient Form')),
      body: BlocListener<PatientBloc, PatientState>(
        listener: (context, state) {
          if (state is PatientOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
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
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildTextField(
                  'Patient ID# *',
                  _idController,
                  validator: (value) => value?.isEmpty == true ? 'Please enter Patient ID' : null,
                ),
                _buildTextField(
                  'Name *',
                  _nameController,
                  validator: (value) => value?.isEmpty == true ? 'Please enter Name' : null,
                ),
                _buildTextField(
                  'Age (yrs)',
                  _ageController,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  'Male/Female',
                  _genderController,
                ),
                _buildTextField(
                  'Comments / Relevant History',
                  _commentsController,
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                BlocBuilder<PatientBloc, PatientState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state is PatientLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: state is PatientLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Done'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() == true) {
      print('🔍 Creating new patient...');
      print('ID: ${_idController.text}');
      print('Name: ${_nameController.text}');
      print('Age: ${_ageController.text}');
      print('Gender: ${_genderController.text}');
      print('Condition: ${_commentsController.text}');
      
      final patient = Patient(
        id: _idController.text,
        name: _nameController.text,
        age: _ageController.text,
        gender: _genderController.text,
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
