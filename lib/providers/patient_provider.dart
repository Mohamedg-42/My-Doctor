import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/doctor_model.dart';
import '../models/appointment_model.dart';
import '../models/treating_doctor_request_model.dart';
import '../models/medical_record_model.dart';
import '../models/review_model.dart';
import '../services/database_service.dart';
// Note: ConversationModel removed - using Firebase Firestore for messaging now

class PatientProvider extends ChangeNotifier {
  String? _currentPatientId;
  StreamSubscription<List<AppointmentModel>>? _appointmentsSub;
  List<DoctorModel> _doctors = [];
  List<DoctorModel> _filteredDoctors = [];
  List<AppointmentModel> _appointments = [];
  List<TreatingDoctorRequest> _treatingRequests = [];
  List<MedicalRecord> _medicalRecords = [];
  // List<ConversationModel> _conversations = []; // Deprecated - using Firestore
  List<MedicationReminder> _reminders = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedSpecialty = '';
  String? _treatingDoctorId;
  double _maxPrice = 100000;
  String _selectedCity = '';
  String _selectedAvailability = '';
  String _sortBy = 'rating';

  // Getters
  List<DoctorModel> get doctors => _filteredDoctors.isEmpty && _searchQuery.isEmpty
      ? _doctors
      : _filteredDoctors;
  List<AppointmentModel> get appointments => _appointments;
  List<AppointmentModel> get upcomingAppointments =>
      _appointments.where((a) => a.isUpcoming).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  List<TreatingDoctorRequest> get treatingRequests => _treatingRequests;
  List<MedicalRecord> get medicalRecords => _medicalRecords;
  // List<ConversationModel> get conversations => _conversations; // Deprecated - using Firestore
  List<MedicationReminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedSpecialty => _selectedSpecialty;
  String? get treatingDoctorId => _treatingDoctorId;
  double get maxPrice => _maxPrice;
  String get selectedCity => _selectedCity;
  String get selectedAvailability => _selectedAvailability;
  String get sortBy => _sortBy;
  // int get totalUnreadMessages => 0; // Deprecated - using Firestore for messaging

  PatientProvider() {
    _loadMockData();
    _initStream();
  }

  void _initStream() {
    _appointmentsSub = DatabaseService().appointmentsStream.listen((_) {
      if (_currentPatientId != null && _currentPatientId!.isNotEmpty) {
        _appointments = DatabaseService().getAppointmentsForPatient(_currentPatientId!);
        notifyListeners();
      }
    });
  }

  Future<void> loadAppointments(String patientId) async {
    _currentPatientId = patientId;
    _appointments = DatabaseService().getAppointmentsForPatient(patientId);
    notifyListeners();
  }

  void _loadMockData() {
    // ✅ Toutes les données de démo supprimées - listes vides par défaut
    _appointments = [];
    _treatingRequests = [];
    _treatingDoctorId = null;
    _medicalRecords = [];
    _reminders = [];
  }

  /// Met à jour la liste des médecins disponibles.
  /// [excludedDoctorIds] : IDs de médecins à masquer (demande pending/accepted).
  void setDoctors(List<DoctorModel> doctors, {Set<String> excludedDoctorIds = const {}}) {
    _doctors = excludedDoctorIds.isEmpty
        ? doctors
        : doctors.where((d) => !excludedDoctorIds.contains(d.id)).toList();
    _filteredDoctors = List.from(_doctors);
    notifyListeners();
  }

  void searchDoctors(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterBySpecialty(String specialty) {
    _selectedSpecialty = specialty;
    _applyFilters();
  }

  void setMaxPrice(double price) {
    _maxPrice = price;
    _applyFilters();
  }

  void setCity(String city) {
    _selectedCity = city;
    _applyFilters();
  }

  void setAvailability(String availability) {
    _selectedAvailability = availability;
    _applyFilters();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    _applyFilters();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedSpecialty = '';
    _maxPrice = 100000;
    _selectedCity = '';
    _selectedAvailability = '';
    _sortBy = 'rating';
    _filteredDoctors = List.from(_doctors);
    notifyListeners();
  }

  void _applyFilters() {
    List<DoctorModel> filtered = List.from(_doctors);

    // Recherche par nom, spécialité, ville, prénom
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((d) {
        return d.fullName.toLowerCase().contains(q) ||
            d.firstName.toLowerCase().contains(q) ||
            d.lastName.toLowerCase().contains(q) ||
            d.specialty.toLowerCase().contains(q) ||
            (d.city?.toLowerCase().contains(q) ?? false) ||
            (d.bio?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Filtre spécialité
    if (_selectedSpecialty.isNotEmpty) {
      filtered = filtered
          .where((d) => d.specialty.toLowerCase() == _selectedSpecialty.toLowerCase())
          .toList();
    }

    // Filtre prix maximum
    if (_maxPrice < 100000) {
      filtered = filtered.where((d) => d.consultationPrice <= _maxPrice).toList();
    }

    // Filtre ville
    if (_selectedCity.isNotEmpty) {
      final cityLower = _selectedCity.toLowerCase();
      filtered = filtered.where((d) {
        final city = d.city;
        return city != null && city.toLowerCase().contains(cityLower);
      }).toList();
    }

    // Filtre disponibilité
    if (_selectedAvailability.isNotEmpty) {
      final now = DateTime.now();
      final dayNames = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
      if (_selectedAvailability == 'today') {
        final todayName = dayNames[now.weekday - 1];
        filtered = filtered.where((d) => d.isAvailable && d.availableDays.contains(todayName)).toList();
      } else if (_selectedAvailability == 'week') {
        filtered = filtered.where((d) => d.isAvailable && d.availableDays.isNotEmpty).toList();
      } else if (_selectedAvailability == 'available') {
        filtered = filtered.where((d) => d.isAvailable).toList();
      }
    }

    // Tri
    switch (_sortBy) {
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'price':
        filtered.sort((a, b) => a.consultationPrice.compareTo(b.consultationPrice));
        break;
      case 'price_desc':
        filtered.sort((a, b) => b.consultationPrice.compareTo(a.consultationPrice));
        break;
      case 'experience':
        filtered.sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
        break;
      case 'distance':
        filtered.sort((a, b) => (a.distanceKm ?? 99).compareTo(b.distanceKm ?? 99));
        break;
      case 'reviews':
        filtered.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }

    _filteredDoctors = filtered;
    notifyListeners();
  }

  // Deprecated - Messaging now handled by Firestore
  // Ajoute une conversation pour un médecin donné
  // void startConversation({...}) { ... }

  // Deprecated - Messaging now handled by Firestore
  // Trouver une conversation par doctorId
  // ConversationModel? findConversationByDoctor(String doctorId) { ... }

  // Deprecated - Messaging now handled by Firestore
  // Marquer une conversation comme lue
  // void markConversationRead(String convId) { ... }

  /// Délégué au TreatingRequestProvider — méthode maintenue pour compatibilité.
  /// Préférer appeler TreatingRequestProvider.sendRequest() directement depuis l'UI.
  Future<bool> sendTreatingDoctorRequest({
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required String message,
    required String paymentMethod,
    required String patientId,
    required String patientName,
    String? patientPhone,
    String? patientAvatar,
  }) async {
    // Cette méthode est gardée pour rétro-compatibilité uniquement.
    // La logique réelle est dans TreatingRequestProvider.sendRequest().
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> bookAppointment(AppointmentModel appointment) async {
    _isLoading = true;
    notifyListeners();

    await DatabaseService().saveAppointment(appointment);
    if (_currentPatientId != null) {
      _appointments = DatabaseService().getAppointmentsForPatient(_currentPatientId!);
    } else {
      _appointments.add(appointment);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> cancelAppointment(String appointmentId) async {
    _isLoading = true;
    notifyListeners();

    await DatabaseService().updateAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
    if (_currentPatientId != null) {
      _appointments = DatabaseService().getAppointmentsForPatient(_currentPatientId!);
    } else {
      final idx = _appointments.indexWhere((a) => a.id == appointmentId);
      if (idx != -1) {
        _appointments[idx] = _appointments[idx].copyWith(status: AppointmentStatus.cancelled);
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  void addReminder(MedicationReminder reminder) {
    _reminders.add(reminder);
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
