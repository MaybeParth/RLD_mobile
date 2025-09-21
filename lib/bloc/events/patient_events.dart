import 'package:equatable/equatable.dart';
import '../../models/patients.dart';

abstract class PatientEvent extends Equatable {
  const PatientEvent();

  @override
  List<Object?> get props => [];
}

class LoadPatients extends PatientEvent {
  const LoadPatients();
}

class AddPatient extends PatientEvent {
  final Patient patient;
  
  const AddPatient(this.patient);
  
  @override
  List<Object?> get props => [patient];
}

class UpdatePatient extends PatientEvent {
  final Patient patient;
  
  const UpdatePatient(this.patient);
  
  @override
  List<Object?> get props => [patient];
}

class DeletePatient extends PatientEvent {
  final String patientId;
  
  const DeletePatient(this.patientId);
  
  @override
  List<Object?> get props => [patientId];
}

class SelectPatient extends PatientEvent {
  final Patient? patient;
  
  const SelectPatient(this.patient);
  
  @override
  List<Object?> get props => [patient];
}

class SaveCalibration extends PatientEvent {
  final String patientId;
  final double zeroOffsetDeg;
  final List<double> ref;
  final List<double> u;
  final List<double> v;
  
  const SaveCalibration({
    required this.patientId,
    required this.zeroOffsetDeg,
    required this.ref,
    required this.u,
    required this.v,
  });
  
  @override
  List<Object?> get props => [patientId, zeroOffsetDeg, ref, u, v];
}

