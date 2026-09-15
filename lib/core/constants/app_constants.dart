class AppConstants {
  // App Info
  static const String appName = 'My Doctor';
  static const String appVersion = '1.0.0';
  static const String appSlogan = 'Votre santé, connectée';

  // Roles
  static const String rolePatient = 'patient';
  static const String roleDoctor = 'doctor';
  static const String roleAdmin = 'admin';

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserRole = 'user_role';
  static const String keyUserId = 'user_id';
  static const String keyUserData = 'user_data';
  static const String keyIs2FAVerified = 'is_2fa_verified';
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyLanguage = 'app_language';
  static const String keyAdminMessageQuota = 'admin_message_quota';
  static const String keyAdminManualDoctorApproval = 'admin_manual_doctor_approval';

  // Pagination
  static const int pageSize = 20;

  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Tarifs (FCFA)
  static const double doctorMonthlyFee = 10000;
  static const double patientTreatingDoctorFee = 750;

  // Validation
  static const int orderNumberLength = 5;
  static const int minPasswordLength = 8;
  static const int otpLength = 6;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB

  // Spécialités médicales
  static const List<String> specialties = [
    'Généraliste',
    'Cardiologue',
    'Dermatologue',
    'Gynécologue',
    'Neurologue',
    'Oncologue',
    'Ophtalmologue',
    'ORL',
    'Orthopédiste',
    'Pédiatre',
    'Psychiatre',
    'Radiologue',
    'Rhumatologue',
    'Urologue',
    'Chirurgien',
    'Interniste',
    'Endocrinologue',
    'Gastro-entérologue',
    'Pneumologue',
    'Néphrologue',
  ];

  // Numéros d'urgence CI
  static const Map<String, String> emergencyNumbers = {
    'SAMU': '185',
    'Pompiers': '180',
    'Police': '110',
    'Croix-Rouge CI': '+225 27 20 22 01 93',
    'CHU de Cocody': '+225 27 22 44 05 00',
    'CHU de Treichville': '+225 27 21 24 64 87',
    'CHU de Yopougon': '+225 27 23 51 21 32',
  };

  // Modes de paiement
  static const Map<String, Map<String, dynamic>> paymentMethods = {
    'wave': {
      'name': 'Wave',
      'icon': 'assets/icons/wave.png',
      'color': 0xFF1E88E5,
    },
    'orange_money': {
      'name': 'Orange Money',
      'icon': 'assets/icons/orange_money.png',
      'color': 0xFFFF6600,
    },
    'mtn_money': {
      'name': 'MTN Mobile Money',
      'icon': 'assets/icons/mtn.png',
      'color': 0xFFFFCC00,
    },
    'moov_money': {
      'name': 'Moov Money',
      'icon': 'assets/icons/moov.png',
      'color': 0xFF0066CC,
    },
    'djamo': {
      'name': 'Djamo',
      'icon': 'assets/icons/djamo.png',
      'color': 0xFF6C3CE1,
    },
  };

  // Créneaux horaires disponibles
  static const List<String> timeSlots = [
    '07:00', '07:30', '08:00', '08:30', '09:00', '09:30',
    '10:00', '10:30', '11:00', '11:30', '12:00', '12:30',
    '13:00', '13:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30', '18:00', '18:30',
  ];

  // Durée consultation (minutes)
  static const List<int> consultationDurations = [15, 20, 30, 45, 60];

  // Bictorys Payment Gateway
  static const String bictorysPublicKey =
      'test_public-1f408b1c-a65b-421a-bd8b-703b7cdfca1e.IbcwtwZHxjD0DzWDsS5Oc9idxdq3lruXFzl0JXCM4dlW3VfDa1j6kv2GS8S4wFrB';
  static const String bictorysTestApiUrl = 'https://api.test.bictorys.com';
  static const String bictorysLiveApiUrl = 'https://api.bictorys.com';
  static const String bictorysDefaultCountry = 'CI';
  static const String bictorysDefaultCurrency = 'XOF';
}

