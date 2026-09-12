// ════════════════════════════════════════════════════════════
//  database_reset_service.dart
//  Service de réinitialisation complète des bases de données
// ════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseResetService {
  /// Supprime TOUTES les données de TOUTES les boxes Hive
  /// ⚠️ ATTENTION : Cette action est IRRÉVERSIBLE
  static Future<void> resetAllDatabases() async {
    try {
      debugPrint('🗑️ Début de la réinitialisation des bases de données...');
      
      // Liste de toutes les boxes utilisées dans l'application
      final boxNames = [
        'users_v1',
        'doctors_v1',
        'sessions_v1',
        'treating_requests_v1',
        'pharmacie_v1',
        'ordonnances_v1',
      ];
      
      int deletedCount = 0;
      
      // Supprimer toutes les boxes une par une
      for (final boxName in boxNames) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            final itemCount = box.length;
            await box.clear(); // Vide le contenu
            debugPrint('  ✅ Box "$boxName" vidée ($itemCount items supprimés)');
            deletedCount += itemCount;
          } else {
            // Ouvrir la box si elle n'est pas ouverte, puis la vider
            final box = await Hive.openBox(boxName);
            final itemCount = box.length;
            await box.clear();
            await box.close();
            debugPrint('  ✅ Box "$boxName" vidée ($itemCount items supprimés)');
            deletedCount += itemCount;
          }
        } catch (e) {
          debugPrint('  ⚠️ Erreur lors du nettoyage de "$boxName": $e');
        }
      }
      
      debugPrint('🎉 Réinitialisation terminée !');
      debugPrint('📊 Total: $deletedCount items supprimés');
      debugPrint('');
      debugPrint('ℹ️ IMPORTANT :');
      debugPrint('  - Tous les comptes patients ont été supprimés');
      debugPrint('  - Tous les comptes médecins ont été supprimés');
      debugPrint('  - Toutes les demandes de traitant ont été supprimées');
      debugPrint('  - Toutes les données pharmacies ont été supprimées');
      debugPrint('  - L\'application est maintenant vierge');
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la réinitialisation: $e');
      rethrow;
    }
  }
  
  /// Supprime uniquement les comptes patients
  static Future<void> resetPatientsOnly() async {
    try {
      debugPrint('🗑️ Suppression des comptes patients...');
      
      if (Hive.isBoxOpen('users_v1')) {
        final box = Hive.box('users_v1');
        final keysToDelete = <dynamic>[];
        
        // Identifier tous les patients
        for (final key in box.keys) {
          final data = box.get(key) as Map?;
          if (data != null && data['role'] == 'patient') {
            keysToDelete.add(key);
          }
        }
        
        // Supprimer les patients
        for (final key in keysToDelete) {
          await box.delete(key);
        }
        
        debugPrint('✅ ${keysToDelete.length} comptes patients supprimés');
      }
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression des patients: $e');
      rethrow;
    }
  }
  
  /// Supprime uniquement les comptes médecins
  static Future<void> resetDoctorsOnly() async {
    try {
      debugPrint('🗑️ Suppression des comptes médecins...');
      
      if (Hive.isBoxOpen('users_v1')) {
        final box = Hive.box('users_v1');
        final keysToDelete = <dynamic>[];
        
        // Identifier tous les médecins
        for (final key in box.keys) {
          final data = box.get(key) as Map?;
          if (data != null && data['role'] == 'doctor') {
            keysToDelete.add(key);
          }
        }
        
        // Supprimer les médecins
        for (final key in keysToDelete) {
          await box.delete(key);
        }
        
        debugPrint('✅ ${keysToDelete.length} comptes médecins supprimés');
      }
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression des médecins: $e');
      rethrow;
    }
  }
  
  /// Affiche les statistiques actuelles de la base de données
  static Future<void> showDatabaseStats() async {
    try {
      debugPrint('📊 Statistiques des bases de données :');
      debugPrint('────────────────────────────────────');
      
      if (Hive.isBoxOpen('users_v1')) {
        final box = Hive.box('users_v1');
        int patients = 0;
        int doctors = 0;
        
        for (final key in box.keys) {
          final data = box.get(key) as Map?;
          if (data != null) {
            if (data['role'] == 'patient') patients++;
            if (data['role'] == 'doctor') doctors++;
          }
        }
        
        debugPrint('  Utilisateurs (users_v1):');
        debugPrint('    - Patients: $patients');
        debugPrint('    - Médecins: $doctors');
        debugPrint('    - Total: ${box.length}');
      }
      
      if (Hive.isBoxOpen('treating_requests_v1')) {
        final box = Hive.box('treating_requests_v1');
        debugPrint('  Demandes traitant: ${box.length}');
      }
      
      if (Hive.isBoxOpen('sessions_v1')) {
        final box = Hive.box('sessions_v1');
        debugPrint('  Sessions: ${box.length}');
      }
      
      debugPrint('────────────────────────────────────');
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des stats: $e');
    }
  }
}
