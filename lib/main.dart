import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
// import 'package:firebase_core/firebase_core.dart'; // ⚠️ Désactivé en mode dégradé
// import 'firebase_options.dart'; // ⚠️ Désactivé en mode dégradé
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'services/database_service.dart';
// import 'services/push_notification_service.dart'; // ⚠️ Désactivé en mode dégradé
import 'providers/patient_provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/app_provider.dart';
import 'providers/cmu_provider.dart';
import 'providers/patient_subscription_provider.dart';
import 'providers/message_provider.dart';
import 'providers/treating_request_provider.dart';
import 'screens/patient/patient_subscription_screen.dart';
import 'screens/patient/cmu_screen.dart';
import 'screens/auth/cover_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'widgets/common/app_loading_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/welcome_screen_original.dart';
import 'screens/auth/choose_register_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/patient_login_screen.dart';
import 'screens/auth/doctor_login_screen.dart';
import 'screens/auth/patient_register_screen.dart';
import 'screens/auth/doctor_register_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/patient/patient_home_screen.dart';
import 'screens/doctor/doctor_home_screen.dart';
import 'screens/patient/doctor_profile_screen.dart';
import 'screens/patient/security_privacy_screen.dart';
import 'screens/patient/help_faq_screen.dart';
import 'screens/patient/contact_support_screen.dart';
import 'screens/patient/edit_profile_screen.dart' as patient_edit_profile;
import 'screens/doctor/manage_slots_screen.dart';
import 'screens/doctor/doctor_payment_screen.dart';
import 'screens/doctor/edit_profile_screen.dart' as doctor_edit_profile;
import 'screens/auth/admin_login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'core/routing/auth_guard.dart';
import 'core/routing/route_persistence_service.dart';
import 'services/supabase_service.dart';
import 'models/user_model.dart';
import 'models/doctor_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Gestionnaire global d'erreurs : adoucit les avertissements de layout overflow
  FlutterError.onError = (FlutterErrorDetails details) {
    final bool isOverflow = details.toString().contains('overflowed by') ||
        details.exceptionAsString().contains('overflowed by') ||
        details.exceptionAsString().contains('A RenderFlex overflowed');
    if (isOverflow) {
      debugPrint('⚠️ [Layout Overflow prévenu] : ${details.summary}');
      return;
    }
    FlutterError.presentError(details);
  };

  if (kDebugMode) {
    debugPrint(
        '⚠️ MODE DÉGRADÉ : Firebase désactivé - Chat et notifications indisponibles');
  }

  // 1. Initialisations asynchrones parallèles pour un démarrage ultra-rapide
  await Future.wait([
    DatabaseService().initialize(),
    SupabaseService().initialize(),
    RoutePersistenceService.init(),
    initializeDateFormatting('fr_FR', null),
  ]);

  // 2. Initialiser AuthProvider et la box Hive des demandes traitant en parallèle
  final authProvider = AuthProvider();
  final treatingRequestProvider = TreatingRequestProvider();
  await Future.wait([
    authProvider.initSession(),
    treatingRequestProvider.initialize(),
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(AlloDocteurApp(
    authProvider: authProvider,
    treatingRequestProvider: treatingRequestProvider,
    initialRoute: kIsWeb
        ? RoutePersistenceService.getInitialRoute(authProvider)
        : null,
  ));
}

class AlloDocteurApp extends StatelessWidget {
  final AuthProvider? authProvider;
  final TreatingRequestProvider treatingRequestProvider;
  final String? initialRoute;

  const AlloDocteurApp({
    super.key,
    this.authProvider,
    required this.treatingRequestProvider,
    this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAuth = authProvider ?? AuthProvider();
    final effectiveRoute =
        initialRoute ?? RoutePersistenceService.getInitialRoute(effectiveAuth);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: effectiveAuth),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        // CmuProvider écoute AuthProvider et met à jour la carte CMU selon l'utilisateur connecté
        ChangeNotifierProxyProvider<AuthProvider, CmuProvider>(
          create: (_) => CmuProvider(),
          update: (_, auth, cmu) {
            final provider = cmu ?? CmuProvider();
            if (auth.isAuthenticated && auth.currentUser != null) {
              provider.initFromUser(auth.currentUser!);
            } else {
              provider.reset();
            }
            return provider;
          },
        ),
        // PatientSubscriptionProvider synchronise l'abonnement du patient connecté
        ChangeNotifierProxyProvider<AuthProvider, PatientSubscriptionProvider>(
          create: (_) => PatientSubscriptionProvider(),
          update: (_, auth, sub) {
            final provider = sub ?? PatientSubscriptionProvider();
            if (auth.isAuthenticated && auth.currentUser != null) {
              provider.initFromUser(auth.currentUser!);
            } else {
              provider.reset();
            }
            return provider;
          },
        ),
        ChangeNotifierProvider<TreatingRequestProvider>.value(
            value: treatingRequestProvider),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, app, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler:
                TextScaler.linear(app.textScaleFactor.clamp(0.85, 1.15)),
          ),
          child: MaterialApp(
            title: 'My Doctor',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: app.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: effectiveRoute,
            navigatorObservers: [AppRouteObserver()],
            routes: {
              '/': (_) => const SplashScreen(),
              '/loading': (_) => const AppLoadingScreen(),
              '/welcome': (_) => const LoginScreen(),
              '/welcome/profile-select': (_) => const LoginScreen(),
              '/splash': (_) => const SplashScreen(),
              '/cover': (_) => const GuestOnlyRoute(child: CoverScreen()),
              '/login': (_) => const LoginScreen(),
              '/auth/login': (_) => const LoginScreen(),
              '/auth/choose-register': (_) =>
                  const GuestOnlyRoute(child: ChooseRegisterScreen()),
              '/auth/patient/login': (_) =>
                  const GuestOnlyRoute(child: PatientLoginScreen()),
              '/auth/doctor/login': (_) =>
                  const GuestOnlyRoute(child: DoctorLoginScreen()),
              '/auth/patient/register': (_) =>
                  const GuestOnlyRoute(child: PatientRegisterScreen()),
              '/auth/doctor/register': (_) =>
                  const GuestOnlyRoute(child: DoctorRegisterScreen()),
              '/patient/home': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.patient, child: PatientHomeScreen()),
              '/doctor/home': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.doctor, child: DoctorHomeScreen()),
              // Abonnements Santé & Carte CMU-CI
              '/patient/subscription': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.patient,
                  child: PatientSubscriptionScreen()),
              '/patient/cmu': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.patient, child: CmuScreen()),
              '/patient/my-card': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.patient, child: CmuScreen()),
              '/cmu': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.patient, child: CmuScreen()),
              // Sous-écrans patients persistants
              '/patient/security-privacy': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.patient,
                  child: SecurityPrivacyScreen()),
              '/patient/help-faq': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.patient, child: HelpFaqScreen()),
              '/patient/contact-support': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.patient,
                  child: ContactSupportScreen()),
              '/patient/edit-profile': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.patient,
                  child: patient_edit_profile.EditProfileScreen()),
              // Sous-écrans médecins persistants
              '/doctor/manage-slots': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.doctor, child: ManageSlotsScreen()),
              '/doctor/payments': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.doctor, child: DoctorPaymentScreen()),
              '/doctor/edit-profile': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.doctor,
                  child: doctor_edit_profile.EditProfileScreen()),
              // Console Administrateur
              '/auth/admin/login': (_) => const AdminLoginScreen(),
              '/admin/login': (_) => const AdminLoginScreen(),
              '/admin': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.admin, child: AdminDashboardScreen()),
              '/admin/overview': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.admin,
                  child: AdminDashboardScreen(initialTab: 0)),
              '/admin/cards': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.admin,
                  child: AdminDashboardScreen(initialTab: 1)),
              '/admin/patient-cards': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.admin,
                  child: AdminDashboardScreen(initialTab: 1)),
              '/admin/withdrawals': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.admin,
                  child: AdminDashboardScreen(initialTab: 2)),
              '/admin/doctors': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.admin,
                  child: AdminDashboardScreen(initialTab: 3)),
              '/admin/patients': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.admin,
                  child: AdminDashboardScreen(initialTab: 4)),
              '/admin/appointments': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.admin,
                  child: AdminDashboardScreen(initialTab: 5)),
              '/admin/requests': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.admin,
                  child: AdminDashboardScreen(initialTab: 6)),
              '/admin/conversations': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.admin,
                  child: AdminDashboardScreen(initialTab: 7)),
              '/admin/audit': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.admin,
                  child: AdminDashboardScreen(initialTab: 7)),
              '/admin/settings': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.admin,
                  child: AdminDashboardScreen(initialTab: 8)),
              '/admin/users': (_) => const AuthenticatedRoute(
                  requiredRole: UserRole.admin,
                  child: AdminDashboardScreen(initialTab: 9)),
            },
            onGenerateRoute: (settings) {
              // Profil médecin avec persistance
              if (settings.name == '/patient/doctor-profile') {
                final doctorId = (settings.arguments is String)
                    ? settings.arguments as String
                    : RoutePersistenceService.getCachedDoctorId();
                DoctorModel? doc;
                if (doctorId != null && doctorId.isNotEmpty) {
                  final dbUser = DatabaseService().getUserById(doctorId);
                  if (dbUser != null) {
                    doc = effectiveAuth.dbUserToDoctorModel(dbUser);
                  }
                  if (doc == null) {
                    try {
                      doc = effectiveAuth.mockDoctors.firstWhere(
                          (d) => d.id == doctorId || d.userId == doctorId);
                    } catch (_) {}
                  }
                }
                if (doc != null) {
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => AuthenticatedRoute(
                      requiredRole: UserRole.patient,
                      child: DoctorProfileScreen(doctor: doc!),
                    ),
                  );
                }
                return MaterialPageRoute(
                  builder: (_) => const AuthenticatedRoute(
                    requiredRole: UserRole.patient,
                    child: PatientHomeScreen(),
                  ),
                );
              }

              // Route OTP avec arguments
              if (settings.name == '/auth/otp') {
                final args = settings.arguments as Map<String, dynamic>?;
                if (args != null) {
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => GuestOnlyRoute(
                      child: OtpScreen(
                        identifier: args['identifier'] as String,
                        role: args['role'] as String,
                      ),
                    ),
                  );
                }
              }

              // Fallback intelligent : si authentifié, rediriger vers l'espace de l'utilisateur
              if (effectiveAuth.isAuthenticated &&
                  effectiveAuth.currentUser != null) {
                final role = effectiveAuth.currentUser!.role;
                if (role == UserRole.admin) {
                  return MaterialPageRoute(
                    builder: (_) => const AuthenticatedRoute(
                        requiredRole: UserRole.admin,
                        child: AdminDashboardScreen()),
                  );
                } else if (role == UserRole.doctor) {
                  return MaterialPageRoute(
                    builder: (_) => const AuthenticatedRoute(
                        requiredRole: UserRole.doctor,
                        child: DoctorHomeScreen()),
                  );
                } else {
                  return MaterialPageRoute(
                    builder: (_) => const AuthenticatedRoute(
                        requiredRole: UserRole.patient,
                        child: PatientHomeScreen()),
                  );
                }
              }

              return MaterialPageRoute(
                settings: settings,
                builder: (_) =>
                    const GuestOnlyRoute(child: WelcomeScreenOriginal()),
              );
            },
            onUnknownRoute: (settings) => MaterialPageRoute(
              settings: settings,
              builder: (_) => const GuestOnlyRoute(child: WelcomeScreen()),
            ),
          ),
        ),
      ),
    );
  }
}
