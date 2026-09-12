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
import 'providers/message_provider.dart';
import 'providers/treating_request_provider.dart';
import 'screens/auth/cover_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/welcome_screen_original.dart';
import 'screens/auth/choose_register_screen.dart';
import 'screens/auth/patient_login_screen.dart';
import 'screens/auth/doctor_login_screen.dart';
import 'screens/auth/patient_register_screen.dart';
import 'screens/auth/doctor_register_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/patient/patient_home_screen.dart';
import 'screens/doctor/doctor_home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/patient/doctor_profile_screen.dart';
import 'screens/patient/security_privacy_screen.dart';
import 'screens/patient/help_faq_screen.dart';
import 'screens/patient/contact_support_screen.dart';
import 'screens/patient/edit_profile_screen.dart' as patient_edit_profile;
import 'screens/doctor/manage_slots_screen.dart';
import 'screens/doctor/doctor_payment_screen.dart';
import 'screens/doctor/edit_profile_screen.dart' as doctor_edit_profile;
import 'core/routing/auth_guard.dart';
import 'core/routing/route_persistence_service.dart';
import 'services/supabase_service.dart';
import 'models/user_model.dart';
import 'models/doctor_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    debugPrint('⚠️ MODE DÉGRADÉ : Firebase désactivé - Chat et notifications indisponibles');
  }

  // 1. Initialiser la base de données locale (Hive)
  await DatabaseService().initialize();

  // 2. Initialiser la connexion PostgreSQL (Supabase)
  await SupabaseService().initialize();

  // 3. Initialiser la persistance de route et d'onglets
  await RoutePersistenceService.init();

  // 3. Initialiser AuthProvider et restaurer la session AVANT runApp
  // Garantit zéro écran blanc de chargement lors du rafraîchissement navigateur (F5)
  final authProvider = AuthProvider();
  await authProvider.initSession();

  // 4. Initialiser la box Hive des demandes traitant
  final treatingRequestProvider = TreatingRequestProvider();
  await treatingRequestProvider.initialize();

  // Formatage des dates
  await initializeDateFormatting('fr_FR', null);

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

  final initialRoute = RoutePersistenceService.getInitialRoute(authProvider);

  runApp(AlloDocteurApp(
    authProvider: authProvider,
    treatingRequestProvider: treatingRequestProvider,
    initialRoute: initialRoute,
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
    final effectiveRoute = initialRoute ?? RoutePersistenceService.getInitialRoute(effectiveAuth);

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
        ChangeNotifierProvider<TreatingRequestProvider>.value(value: treatingRequestProvider),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, app, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(app.textScaleFactor),
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
              '/': (_) => const GuestOnlyRoute(child: WelcomeScreenOriginal()),
              '/welcome': (_) => const GuestOnlyRoute(child: WelcomeScreenOriginal()),
              '/splash': (_) => const SplashScreen(),
              '/cover': (_) => const GuestOnlyRoute(child: CoverScreen()),
              '/auth/choose-register': (_) => const GuestOnlyRoute(child: ChooseRegisterScreen()),
              '/auth/patient/login': (_) => const GuestOnlyRoute(child: PatientLoginScreen()),
              '/auth/doctor/login': (_) => const GuestOnlyRoute(child: DoctorLoginScreen()),
              '/auth/patient/register': (_) => const GuestOnlyRoute(child: PatientRegisterScreen()),
              '/auth/doctor/register': (_) => const GuestOnlyRoute(child: DoctorRegisterScreen()),
              '/patient/home': (_) => const AuthenticatedRoute(requiredRole: UserRole.patient, child: PatientHomeScreen()),
              '/doctor/home': (_) => const AuthenticatedRoute(requiredRole: UserRole.doctor, child: DoctorHomeScreen()),
              '/admin': (_) => const AdminDashboardScreen(initialTab: 0),
              '/admin/users': (_) => const AdminDashboardScreen(initialTab: 1),
              '/admin/doctors': (_) => const AdminDashboardScreen(initialTab: 2),
              '/admin/patients': (_) => const AdminDashboardScreen(initialTab: 3),
              '/admin/requests': (_) => const AdminDashboardScreen(initialTab: 4),
              '/admin/appointments': (_) => const AdminDashboardScreen(initialTab: 5),
              '/admin/conversations': (_) => const AdminDashboardScreen(initialTab: 6),
              // Sous-écrans patients persistants
              '/patient/security-privacy': (_) => const AuthenticatedRoute(requiredRole: UserRole.patient, child: SecurityPrivacyScreen()),
              '/patient/help-faq': (_) => const AuthenticatedRoute(requiredRole: UserRole.patient, child: HelpFaqScreen()),
              '/patient/contact-support': (_) => const AuthenticatedRoute(requiredRole: UserRole.patient, child: ContactSupportScreen()),
              '/patient/edit-profile': (_) => const AuthenticatedRoute(requiredRole: UserRole.patient, child: patient_edit_profile.EditProfileScreen()),
              // Sous-écrans médecins persistants
              '/doctor/manage-slots': (_) => const AuthenticatedRoute(requiredRole: UserRole.doctor, child: ManageSlotsScreen()),
              '/doctor/payments': (_) => const AuthenticatedRoute(requiredRole: UserRole.doctor, child: DoctorPaymentScreen()),
              '/doctor/edit-profile': (_) => const AuthenticatedRoute(requiredRole: UserRole.doctor, child: doctor_edit_profile.EditProfileScreen()),
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
                      doc = effectiveAuth.mockDoctors.firstWhere((d) => d.id == doctorId || d.userId == doctorId);
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
              if (effectiveAuth.isAuthenticated && effectiveAuth.currentUser != null) {
                final role = effectiveAuth.currentUser!.role;
                if (role == UserRole.admin) {
                  return MaterialPageRoute(
                    builder: (_) => const AuthenticatedRoute(requiredRole: UserRole.admin, child: AdminDashboardScreen()),
                  );
                } else if (role == UserRole.doctor) {
                  return MaterialPageRoute(
                    builder: (_) => const AuthenticatedRoute(requiredRole: UserRole.doctor, child: DoctorHomeScreen()),
                  );
                } else {
                  return MaterialPageRoute(
                    builder: (_) => const AuthenticatedRoute(requiredRole: UserRole.patient, child: PatientHomeScreen()),
                  );
                }
              }

              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const GuestOnlyRoute(child: WelcomeScreenOriginal()),
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
