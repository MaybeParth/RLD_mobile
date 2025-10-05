import 'package:bloc/bloc.dart';
import '../events/patient_events.dart';
import '../states/patient_states.dart';
import '../../db/patient_database.dart';

class PatientBloc extends Bloc<PatientEvent, PatientState> {
  PatientBloc() : super(const PatientInitial()) {
    on<LoadPatients>(_onLoadPatients);
    on<AddPatient>(_onAddPatient);
    on<UpdatePatient>(_onUpdatePatient);
    on<DeletePatient>(_onDeletePatient);
    on<SelectPatient>(_onSelectPatient);
    on<SaveCalibration>(_onSaveCalibration);
  }

  Future<void> _onLoadPatients(
      LoadPatients event, Emitter<PatientState> emit) async {
    try {
      emit(const PatientLoading());
      final patients = await PatientDatabase.getAllPatients();
      emit(PatientLoaded(patients: patients));
    } catch (e) {
      emit(PatientError('Failed to load patients: $e'));
    }
  }

  Future<void> _onAddPatient(
      AddPatient event, Emitter<PatientState> emit) async {
    try {
      print('🔍 PatientBloc: Adding patient ${event.patient.id}');
      print('🔍 PatientBloc: Patient data: ${event.patient.toMap()}');

      // Initialize database if needed
      await PatientDatabase.database;
      print('🔍 PatientBloc: Database initialized successfully');

      await PatientDatabase.insertPatient(event.patient);
      print('🔍 PatientBloc: Patient inserted successfully');

      final patients = await PatientDatabase.getAllPatients();
      print(
          '🔍 PatientBloc: Retrieved ${patients.length} patients from database');

      emit(PatientOperationSuccess(
        message: 'Patient added successfully',
        patients: patients,
      ));
      print('🔍 PatientBloc: Emitted PatientOperationSuccess');
    } catch (e, stackTrace) {
      print('❌ PatientBloc: Error adding patient: $e');
      print('❌ PatientBloc: Stack trace: $stackTrace');
      emit(PatientError('Failed to add patient: $e'));
    }
  }

  Future<void> _onUpdatePatient(
      UpdatePatient event, Emitter<PatientState> emit) async {
    try {
      await PatientDatabase.upsertPatient(event.patient);
      final patients = await PatientDatabase.getAllPatients();
      emit(PatientOperationSuccess(
        message: 'Patient updated successfully',
        patients: patients,
      ));
    } catch (e) {
      emit(PatientError('Failed to update patient: $e'));
    }
  }

  Future<void> _onDeletePatient(
      DeletePatient event, Emitter<PatientState> emit) async {
    try {
      await PatientDatabase.deletePatient(event.patientId);
      final patients = await PatientDatabase.getAllPatients();
      emit(PatientOperationSuccess(
        message: 'Patient deleted successfully',
        patients: patients,
      ));
    } catch (e) {
      emit(PatientError('Failed to delete patient: $e'));
    }
  }

  void _onSelectPatient(SelectPatient event, Emitter<PatientState> emit) {
    if (state is PatientLoaded) {
      final currentState = state as PatientLoaded;
      emit(currentState.copyWith(selectedPatient: event.patient));
    }
  }

  Future<void> _onSaveCalibration(
      SaveCalibration event, Emitter<PatientState> emit) async {
    try {
      await PatientDatabase.saveCalibration(
        id: event.patientId,
        zeroOffsetDeg: event.zeroOffsetDeg,
        ref: event.ref,
        u: event.u,
        v: event.v,
      );
      final patients = await PatientDatabase.getAllPatients();
      emit(PatientOperationSuccess(
        message: 'Calibration saved successfully',
        patients: patients,
      ));
    } catch (e) {
      emit(PatientError('Failed to save calibration: $e'));
    }
  }
}
