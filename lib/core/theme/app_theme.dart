import 'package:flutter/material.dart';

/// Design Tokens officiels selon les spécifications My Doctor & Logo officiel
class AppColors {
  // ─── Couleurs officielles fidèles au Logo My Doctor ──────────────────────────
  static const Color logoBlue       = Color(0xFF0070D2); // Main bleue & "my" : boutons principaux, titres, liens actifs
  static const Color logoTurquoise  = Color(0xFF00A896); // Main turquoise & "doctor" : accents, icônes secondaires, badges
  static const Color logoCrossRed   = Color(0xFFEB5757); // Croix médicale centrale : symboles médicaux, urgences, alertes

  // ─── Couleurs de marque alignées sur le logo ────────────────────────────────
  static const Color brandBlue      = logoBlue;          // Color(0xFF0070D2)
  static const Color brandTurquoise = logoTurquoise;     // Color(0xFF00A896)
  static const Color brandCoral     = logoCrossRed;      // Color(0xFFEB5757)
  static const Color brandNavy      = Color(0xFF1E293B); // Gris foncé / Bleu foncé contrasté pour les titres

  // ─── Neutres & Surfaces ─────────────────────────────────────────────────────
  static const Color surfaceApp     = Color(0xFFFFFFFF); // Blanc comme couleur principale de fond
  static const Color surfaceSubtle  = Color(0xFFF8FAFC); // Gris très clair pour éléments secondaires et listes
  static const Color surfaceCard    = Color(0xFFFFFFFF); // Cartes blanches
  static const Color borderSubtle   = Color(0xFFE2E8F0); // Gris clair pour bordures et champs de saisie

  // ─── Textes (Gris foncé pour garantir une lisibilité optimale) ──────────────
  static const Color textPrimary    = Color(0xFF1E293B); // Titres, libellés importants (gris foncé / bleu nuit)
  static const Color textSecondary  = Color(0xFF475569); // Paragraphes, descriptions (gris moyen)
  static const Color textMuted      = Color(0xFF94A3B8); // Métadonnées, aides, états désactivés (gris doux)
  static const Color textOnColor    = Color(0xFFFFFFFF); // Texte blanc sur surface colorée
  static const Color textLight      = textMuted;         // Alias compatibilité

  // ─── États d'interface ──────────────────────────────────────────────────────
  static const Color successBg      = Color(0xFFE6F7F5); // Fond état succès turquoise très doux
  static const Color warningBg      = Color(0xFFFFF7ED); // Fond état alerte ambre doux
  static const Color errorBg        = Color(0xFFFEF2F2); // Fond état erreur rouge doux
  static const Color selectedBg     = Color(0xFFEBF5FB); // Fond sélection bleu logo très doux

  // ─── Rétrocompatibilité & Alias sémantiques ─────────────────────────────────
  static const Color primary        = brandBlue;         // Bleu du logo
  static const Color primaryDark    = Color(0xFF0056A3); // Bleu du logo profond
  static const Color primaryLight   = selectedBg;
  static const Color primaryUltraLight = surfaceSubtle;
  static const Color accent         = brandTurquoise;    // Turquoise du logo
  static const Color accentBlue     = brandBlue;
  static const Color accentPink     = brandCoral;
  static const Color green          = brandTurquoise;
  static const Color yellow         = Color(0xFFFFB800);

  static const Color backgroundDark  = brandNavy;
  static const Color backgroundLight = surfaceApp;       // Blanc
  static const Color backgroundCard  = surfaceCard;      // Blanc
  static const Color backgroundGrey  = borderSubtle;     // Gris clair
  static const Color cream           = surfaceSubtle;

  static const Color success = brandTurquoise;           // Turquoise du logo
  static const Color warning = Color(0xFFD97706);
  static const Color error   = brandCoral;               // Rouge du logo (avec modération)
  static const Color info    = brandBlue;                // Bleu du logo
  static const Color star    = Color(0xFFFFB800);
  static const Color callRed = brandCoral;
  static const Color online  = brandTurquoise;
  static const Color offline = textMuted;
  static const Color textWhite = textOnColor;

  // ─── Gradients harmonisés avec le logo ──────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBlue, Color(0xFF0056A3)],
  );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBlue, brandTurquoise],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [brandBlue, Color(0xFF0056A3)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandNavy, Color(0xFF0F172A)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceApp, surfaceSubtle],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceCard, surfaceSubtle],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBlue, Color(0xFF0056A3)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandTurquoise, Color(0xFF00897B)],
  );
}

/// Typographie officielle My Doctor basée sur la police Outfit (constantes de compilation)
class AppTextStyles {
  static const String fontFamily = 'Outfit';

  // ─── Échelle typographique officielle (Spécification Section 5.2) ─────────
  
  /// Titre d'accueil ou écran exceptionnel : 32px / 700 / line-height 38px
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 38 / 32,
  );

  /// Titre principal d'écran : 28px / 700 / line-height 34px
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 34 / 28,
  );

  /// Titre de section : 22px / 600 / line-height 28px
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 28 / 22,
  );

  /// Titre de carte ou groupe : 18px / 600 / line-height 24px
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 24 / 18,
  );

  /// Introduction et texte important : 17px / 400 / line-height 26px
  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 26 / 17,
  );

  /// Texte courant par défaut : 16px / 400 / line-height 24px
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 24 / 16,
  );

  /// Labels, boutons et champs : 14px / 600 / line-height 20px
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 20 / 14,
  );

  /// Métadonnées et aide secondaire : 12px / 500 / line-height 16px
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 16 / 12,
  );

  // ─── Alias de compatibilité avec le code existant ─────────────────────────
  static const TextStyle heading1 = h1;
  static const TextStyle heading2 = h2;
  static const TextStyle heading3 = h3;
  static const TextStyle subtitle1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  static const TextStyle subtitle2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  static const TextStyle body1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  static const TextStyle body2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
    letterSpacing: 0.5,
  );
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textWhite,
    letterSpacing: 0.3,
  );
}

/// Thème global Material 3 My Doctor
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: ThemeData.light().textTheme.apply(fontFamily: AppTextStyles.fontFamily),
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.logoBlue,
        brightness: Brightness.light,
        primary: AppColors.logoBlue,
        secondary: AppColors.logoTurquoise,
        surface: Colors.white,
        error: AppColors.logoCrossRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.h3,
        iconTheme: IconThemeData(color: AppColors.logoBlue),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
          borderRadius: BorderRadius.circular(20), // --radius-card
        ),
        shadowColor: AppColors.brandBlue.withValues(alpha: 0.06),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.logoBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52), // Hauteur min 52px spécifiée
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // --radius-control
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.logoBlue,
          side: const BorderSide(color: AppColors.logoBlue, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.logoBlue),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.logoBlue,
          textStyle: AppTextStyles.label.copyWith(
            color: AppColors.logoBlue,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.logoBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.logoCrossRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.logoCrossRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        labelStyle: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.logoBlue,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'Outfit', fontSize: 11),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSubtle,
        selectedColor: AppColors.selectedBg,
        labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: AppTextStyles.fontFamily),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandBlue,
        brightness: Brightness.dark,
        primary: AppColors.brandBlue,
        secondary: AppColors.brandTurquoise,
        surface: const Color(0xFF1E293B),
        error: AppColors.brandCoral,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF334155), width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: AppColors.textOnColor,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
        space: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
