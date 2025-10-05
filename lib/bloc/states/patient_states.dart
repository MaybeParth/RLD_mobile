import 'package:equatable/equatable.dart';
import '../../models/patients.dart';

abstract class PatientState extends Equatable {
  const PatientState();

  @override
  List<Object?> get props => [];
}

class PatientInitial extends PatientState {
  const PatientInitial();
}

class PatientLoading extends PatientState {
  const PatientLoading();
}

class PatientLoaded extends PatientState {
  final List<Patient> patients;
  final Patient? selectedPatient;

  const PatientLoaded({
    required this.patients,
    this.selectedPatient,
  });

  @override
  List<Object?> get props => [patients, selectedPatient];

  PatientLoaded copyWith({
    List<Patient>? patients,
    Patient? selectedPatient,
  }) {
    return PatientLoaded(
      patients: patients ?? this.patients,
      selectedPatient: selectedPatient ?? this.selectedPatient,
    );
  }
}

class PatientError extends PatientState {
  final String message;

  const PatientError(this.message);

  @override
  List<Object?> get props => [message];
}

class PatientOperationSuccess extends PatientState {
  final String message;
  final List<Patient> patients;

  const PatientOperationSuccess({
    required this.message,
    required this.patients,
  });

  @override
  List<Object?> get props => [message, patients];
}
