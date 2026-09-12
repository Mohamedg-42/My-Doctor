import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design Tokens officiels selon les spécifications My Doctor
class AppColors {
  // ─── Couleurs de marque ───────────────────────────────────────────────────
  static const Color brandBlue      = Color(0xFF2D9CDB); // Action principale, sélection active, navigation
  static const Color brandTurquoise = Color(0xFF27AE60); // Succès, validation, état sain, confirmation
  static const Color brandCoral     = Color(0xFFEB5757); // Urgence, erreur, suppression, critique
  static const Color brandNavy      = Color(0xFF1A365D); // Titres, texte fort, contraste premium

  // Couleurs dérivées du logo officiel
  static const Color logoBlue       = Color(0xFF0070D2); // Main bleue supérieure & "my"
  static const Color logoTurquoise  = Color(0xFF00A896); // Main turquoise & "doctor"
  static const Color logoCrossRed   = Color(0xFFEB5757); // Croix médicale centrale

  // ─── Neutres & Surfaces ───────────────────────────────────────────────────
  static const Color surfaceApp     = Color(0xFFFDFCF8); // Fond général ivoire de l'application
  static const Color surfaceSubtle  = Color(0xFFF7FAFC); // Champs, éléments secondaires, listes
  static const Color surfaceCard    = Color(0xFFFFFFFF); // Cartes et surfaces élevées
  static const Color borderSubtle   = Color(0xFFEDF2F7); // Bordures discrètes et séparateurs

  // ─── Textes ───────────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF1A365D); // Titres, libellés importants
  static const Color textSecondary  = Color(0xFF4A5568); // Paragraphes, descriptions
  static const Color textMuted      = Color(0xFF718096); // Métadonnées, aides, états désactivés
  static const Color textOnColor    = Color(0xFFFFFFFF); // Texte sur bouton ou surface colorée
  static const Color textLight      = Color(0xFF718096); // Alias compatibilité

  // ─── États d'interface ────────────────────────────────────────────────────
  static const Color successBg      = Color(0xFFE9F7EF); // Fond état succès
  static const Color warningBg      = Color(0xFFFFF4E8); // Fond état alerte
  static const Color errorBg        = Color(0xFFFFF0F0); // Fond état erreur
  static const Color selectedBg     = Color(0xFFE7F3FB); // Fond état sélectionné

  // ─── Rétrocompatibilité & Alias sémantiques ───────────────────────────────
  static const Color primary        = brandBlue;
  static const Color primaryDark    = brandNavy;
  static const Color primaryLight   = selectedBg;
  static const Color primaryUltraLight = surfaceApp;
  static const Color accent         = brandTurquoise;
  static const Color accentBlue     = brandNavy;
  static const Color accentPink     = brandCoral;
  static const Color green          = brandTurquoise;
  static const Color yellow         = Color(0xFFFFB800);

  static const Color backgroundDark  = brandNavy;
  static const Color backgroundLight = surfaceApp;
  static const Color backgroundCard  = surfaceCard;
  static const Color backgroundGrey  = borderSubtle;
  static const Color cream           = surfaceSubtle;

  static const Color success = brandTurquoise;
  static const Color warning = Color(0xFFC05621);
  static const Color error   = brandCoral;
  static const Color info    = brandBlue;
  static const Color star    = Color(0xFFFFB800);
  static const Color callRed = brandCoral;
  static const Color online  = brandTurquoise;
  static const Color offline = textMuted;
  static const Color textWhite = textOnColor;

  // ─── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBlue, Color(0xFF1B82BD)],
  );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBlue, brandTurquoise],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [brandBlue, Color(0xFF1B82BD)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandNavy, Color(0xFF2C4A7A)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceApp, surfaceCard],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceCard, surfaceSubtle],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBlue, brandNavy],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandTurquoise, Color(0xFF219653)],
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
      textTheme: GoogleFonts.outfitTextTheme(),
      scaffoldBackgroundColor: AppColors.surfaceApp,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandBlue,
        brightness: Brightness.light,
        primary: AppColors.brandBlue,
        secondary: AppColors.brandTurquoise,
        surface: AppColors.surfaceCard,
        error: AppColors.brandCoral,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceCard,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.h3,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
          borderRadius: BorderRadius.circular(20), // --radius-card
        ),
        shadowColor: AppColors.brandNavy.withValues(alpha: 0.06),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: AppColors.textOnColor,
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
          foregroundColor: AppColors.brandBlue,
          side: const BorderSide(color: AppColors.brandBlue, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.brandBlue),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandBlue,
          textStyle: AppTextStyles.label.copyWith(
            color: AppColors.brandBlue,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSubtle,
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
          borderSide: const BorderSide(color: AppColors.brandBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandCoral, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandCoral, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        labelStyle: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceCard,
        selectedItemColor: AppColors.brandBlue,
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
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
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
