// lib/services/supabase_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized && _client != null;
  SupabaseClient? get client => _client;

  /// Initialise la connexion au serveur PostgreSQL via Supabase
  Future<bool> initialize() async {
    await SupabaseConfig.init();

    if (!SupabaseConfig.isConfigured) {
      debugPrint('ℹ️ Supabase PostgreSQL non configuré (utilisation du mode local Hive)');
      return false;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      debugPrint('🐘 Connexion à la base de données PostgreSQL (Supabase) établie avec succès !');
      return true;
    } catch (e) {
      debugPrint('⚠️ Erreur d\'initialisation Supabase PostgreSQL: $e');
      _isInitialized = false;
      return false;
    }
  }

  // ─── REQUÊTES UTILISATEURS (PostgreSQL `users`) ────────────────────────────

  Future<Map<String, dynamic>?> getUserById(String id) async {
    if (!isInitialized) return null;
    try {
      final res = await _client!.from('users').select().eq('id', id).maybeSingle();
      return res;
    } catch (e) {
      debugPrint('Erreur Supabase getUserById: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserByEmailOrPhone(String identifier) async {
    if (!isInitialized) return null;
    try {
      final res = await _client!
          .from('users')
          .select()
          .or('email.eq.$identifier,phone.eq.$identifier')
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('Erreur Supabase getUserByEmailOrPhone: $e');
      return null;
    }
  }

  Future<bool> insertUser(Map<String, dynamic> userData) async {
    if (!isInitialized) return false;
    try {
      await _client!.from('users').insert(userData);
      return true;
    } catch (e) {
      debugPrint('Erreur Supabase insertUser: $e');
      return false;
    }
  }

  // ─── REQUÊTES MÉDECINS (PostgreSQL `doctors`) ──────────────────────────────

  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    if (!isInitialized) return [];
    try {
      final res = await _client!
          .from('users')
          .select('*, doctors(*)')
          .eq('role', 'doctor')
          .eq('status', 'active');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Erreur Supabase getAllDoctors: $e');
      return [];
    }
  }

  // ─── DEMANDES MÉDECIN TRAITANT (PostgreSQL `treating_requests`) ───────────

  Future<List<Map<String, dynamic>>> getTreatingRequests() async {
    if (!isInitialized) return [];
    try {
      final res = await _client!
          .from('treating_requests')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Erreur Supabase getTreatingRequests: $e');
      return [];
    }
  }

  Future<bool> saveTreatingRequest(Map<String, dynamic> requestData) async {
    if (!isInitialized) return false;
    try {
      await _client!.from('treating_requests').upsert(requestData);
      return true;
    } catch (e) {
      debugPrint('Erreur Supabase saveTreatingRequest: $e');
      return false;
    }
  }

  Future<bool> updateTreatingRequestStatus(String requestId, String status) async {
    if (!isInitialized) return false;
    try {
      await _client!
          .from('treating_requests')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', requestId);
      return true;
    } catch (e) {
      debugPrint('Erreur Supabase updateTreatingRequestStatus: $e');
      return false;
    }
  }

  // ─── RENDEZ-VOUS (PostgreSQL `appointments`) ──────────────────────────────

  Future<List<Map<String, dynamic>>> getAppointments({String? patientId, String? doctorId}) async {
    if (!isInitialized) return [];
    try {
      var query = _client!.from('appointments').select();
      if (patientId != null && patientId.isNotEmpty) {
        query = query.eq('patient_id', patientId);
      }
      if (doctorId != null && doctorId.isNotEmpty) {
        query = query.eq('doctor_id', doctorId);
      }
      final res = await query.order('scheduled_at', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Erreur Supabase getAppointments: $e');
      return [];
    }
  }

  Future<bool> saveAppointment(Map<String, dynamic> appointmentData) async {
    if (!isInitialized) return false;
    try {
      await _client!.from('appointments').upsert(appointmentData);
      return true;
    } catch (e) {
      debugPrint('Erreur Supabase saveAppointment: $e');
      return false;
    }
  }

  Future<bool> updateAppointmentStatus(String appointmentId, String status) async {
    if (!isInitialized) return false;
    try {
      await _client!
          .from('appointments')
          .update({'status': status})
          .eq('id', appointmentId);
      return true;
    } catch (e) {
      debugPrint('Erreur Supabase updateAppointmentStatus: $e');
      return false;
    }
  }
}
