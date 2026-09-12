// lib/core/config/supabase_config.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseConfig {
  static const String keySupabaseUrl = 'supabase_url';
  static const String keySupabaseAnonKey = 'supabase_anon_key';

  // Valeurs par défaut configurables
  // Vous pouvez remplacer ces valeurs par l'URL et la clé anonyme de votre projet Supabase
  static String supabaseUrl = 'https://votre-projet.supabase.co';
  static String supabaseAnonKey = 'votre-cle-anonyme-supabase';

  /// Indique si une vraie configuration Supabase PostgreSQL est active
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('votre-projet') &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('votre-cle');
  }

  /// Initialise la configuration depuis SharedPreferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(keySupabaseUrl);
      final savedKey = prefs.getString(keySupabaseAnonKey);

      if (savedUrl != null && savedUrl.isNotEmpty) {
        supabaseUrl = savedUrl;
      }
      if (savedKey != null && savedKey.isNotEmpty) {
        supabaseAnonKey = savedKey;
      }

      debugPrint('🐘 Supabase PostgreSQL configuré: $isConfigured ($supabaseUrl)');
    } catch (e) {
      debugPrint('⚠️ Erreur init SupabaseConfig: $e');
    }
  }

  /// Sauvegarde les identifiants Supabase PostgreSQL
  static Future<void> saveConfig(String url, String anonKey) async {
    supabaseUrl = url.trim();
    supabaseAnonKey = anonKey.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySupabaseUrl, supabaseUrl);
    await prefs.setString(keySupabaseAnonKey, supabaseAnonKey);
  }
}
