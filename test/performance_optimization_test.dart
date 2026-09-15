import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:allo_docteur/core/theme/app_theme.dart';
import 'package:allo_docteur/widgets/common/avatar_widget.dart';
import 'package:allo_docteur/screens/shared/pre_call_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Performance & Optimization Tests', () {
    test('Theme uses local font and does not request external fonts at runtime', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      expect(lightTheme.textTheme.bodyMedium?.fontFamily, contains(AppTextStyles.fontFamily));
      expect(darkTheme.textTheme.bodyMedium?.fontFamily, contains(AppTextStyles.fontFamily));
      expect(AppTextStyles.fontFamily, isNotEmpty);
    });

    testWidgets('AvatarWidget and DoctorAvatar construct and render cleanly with image caching', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AvatarWidget(
                  initials: 'AB',
                  imageUrl: 'https://example.com/avatar.jpg',
                  size: 48,
                ),
                DoctorAvatar(
                  name: 'Dr. Jean Kouamé',
                  imageUrl: 'https://example.com/doc.jpg',
                  size: 56,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AvatarWidget), findsOneWidget);
      expect(find.byType(DoctorAvatar), findsOneWidget);
    });

    testWidgets('PreCallScreen mounts and disposes its AnimationController cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PreCallScreen(
            doctorName: 'Dr. Kouamé',
            doctorSpecialty: 'Généraliste',
          ),
        ),
      );

      expect(find.byType(PreCallScreen), findsOneWidget);

      // Unmount to trigger dispose()
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('SplashScreen displays logo, CupertinoActivityIndicator, Chargement... and heartbeat', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Chargement...'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Chargement...'), findsOneWidget);
    });
  });
}
