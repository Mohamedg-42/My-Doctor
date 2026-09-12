import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/appointment_model.dart';
import '../models/treating_doctor_request_model.dart';
import '../models/medical_record_model.dart';
import '../services/database_service.dart';
import 'treating_request_provider.dart';

class DoctorStats {
  final int totalPatients;
  final int totalAppointments;
  final int pendingAppointments;
  final int completedThisMonth;
  final double revenue;
  final double averageRating;
  final int newRequests;

  DoctorStats({
    this.totalPatients = 0,
    this.totalAppointments = 0,
    this.pendingAppointments = 0,
    this.completedThisMonth = 0,
    this.revenue = 0,
    this.averageRating = 0,
    this.newRequests = 0,
  });
}

class DoctorProvider extends ChangeNotifier {
  String? _currentDoctorId;
  StreamSubscription<List<AppointmentModel>>? _appointmentsSub;

  List<AppointmentModel> _appointments = [];
  List<TreatingDoctorRequest> _treatingRequests = [];
  List<MedicalRecord> _patientRecords = [];
  DoctorStats _stats = DoctorStats();
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<AppointmentModel> get appointments => _appointments;
  List<AppointmentModel> get pendingAppointments =>
      _appointments.where((a) => a.status == AppointmentStatus.pending).toList();
  List<AppointmentModel> get confirmedAppointments =>
      _appointments.where((a) => a.status == AppointmentStatus.confirmed).toList();
  List<AppointmentModel> get todayAppointments {
    final today = DateTime.now();
    return _appointments.where((a) {
      return a.scheduledAt.year == today.year &&
          a.scheduledAt.month == today.month &&
          a.scheduledAt.day == today.day;
    }).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  List<TreatingDoctorRequest> get treatingRequests => _treatingRequests;
  List<TreatingDoctorRequest> get pendingTreatingRequests =>
      _treatingRequests.where((r) => r.status == TreatingDoctorStatus.pending).toList();
  List<MedicalRecord> get patientRecords => _patientRecords;
  DoctorStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DoctorProvider() {
    _loadMockData();
    _initStream();
  }

  void _initStream() {
    _appointmentsSub = DatabaseService().appointmentsStream.listen((_) {
      if (_currentDoctorId != null && _currentDoctorId!.isNotEmpty) {
        _appointments = DatabaseService().getAppointmentsForDoctor(_currentDoctorId!);
        _recalculateStats();
        notifyListeners();
      }
    });
  }

  void _loadMockData() {
    _appointments = [];
    _treatingRequests = [];
    _patientRecords = [];
    _stats = DoctorStats();
  }

  /// Charge les données réelles du médecin (rendez-vous persistés et statistiques)
  Future<void> loadDoctorData(String doctorId, {TreatingRequestProvider? trProvider}) async {
    _currentDoctorId = doctorId;
    _appointments = DatabaseService().getAppointmentsForDoctor(doctorId);
    _recalculateStats(trProvider: trProvider);
    notifyListeners();
  }

  void _recalculateStats({TreatingRequestProvider? trProvider}) {
    final now = DateTime.now();
    
    // Rendez-vous confirmés ou terminés ce mois-ci
    final completedOrConfirmedThisMonth = _appointments.where((a) {
      return a.scheduledAt.year == now.year &&
          a.scheduledAt.month == now.month &&
          (a.status == AppointmentStatus.confirmed || a.status == AppointmentStatus.completed);
    }).toList();

    // Calcul du revenu des consultations
    double consultationRevenue = 0;
    for (final a in completedOrConfirmedThisMonth) {
      consultationRevenue += (a.consultationPrice ?? 15000.0);
    }

    // Demandes traitant
    int pendingReqs = 0;
    int acceptedReqs = 0;
    final patientIds = <String>{};

    for (final a in _appointments) {
      if (a.status == AppointmentStatus.confirmed || a.status == AppointmentStatus.completed) {
        patientIds.add(a.patientId);
      }
    }

    if (trProvider != null && _currentDoctorId != null) {
      final docRequests = trProvider.requestsForDoctor(_currentDoctorId!);
      pendingReqs = docRequests.where((r) => r.isPending).length;
      final accepted = docRequests.where((r) => r.isAccepted).toList();
      acceptedReqs = accepted.length;
      for (final r in accepted) {
        patientIds.add(r.patientId);
        consultationRevenue += r.amount; // 750 F CFA par demande traitant acceptée
      }
    }

    _stats = DoctorStats(
      totalPatients: patientIds.length,
      totalAppointments: _appointments.length,
      pendingAppointments: pendingAppointments.length,
      completedThisMonth: completedOrConfirmedThisMonth.length,
      revenue: consultationRevenue,
      averageRating: 4.9,
      newRequests: pendingReqs,
    );
  }

  Future<void> respondToAppointment(String appointmentId, bool accept) async {
    _isLoading = true;
    notifyListeners();

    final newStatus = accept ? AppointmentStatus.confirmed : AppointmentStatus.cancelled;
    await DatabaseService().updateAppointmentStatus(appointmentId, newStatus);

    if (_currentDoctorId != null) {
      _appointments = DatabaseService().getAppointmentsForDoctor(_currentDoctorId!);
      _recalculateStats();
    } else {
      final idx = _appointments.indexWhere((a) => a.id == appointmentId);
      if (idx != -1) {
        _appointments[idx] = _appointments[idx].copyWith(status: newStatus);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> respondToTreatingRequest(String requestId, bool accept) async {
    _isLoading = true;
    notifyListeners();

    final idx = _treatingRequests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      _treatingRequests.removeAt(idx);
    }
    _recalculateStats();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createMedicalRecord(MedicalRecord record) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    _patientRecords.add(record);
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _appointmentsSub?.cancel();
    super.dispose();
  }
}
