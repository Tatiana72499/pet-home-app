import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:pethome_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:pethome_app/src/features/home/presentation/pages/home_page.dart';

class PetHomeApp extends StatelessWidget {
  const PetHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
  
    final baseTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',

      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6A11CB), // 💜 morado principal
        brightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'PetHome',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: Colors.white,

        textTheme: baseTheme.textTheme.apply(
          bodyColor: const Color(0xFF1A1A1A),
          displayColor: const Color(0xFF1A1A1A),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F1F1),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF6A11CB),
              width: 1.5,
            ),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6A11CB),
            side: const BorderSide(color: Color(0xFF6A11CB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      home: const SessionGate(),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  final AuthService _authService = AuthService();
  late final Future<bool> _hasSession = _authService.hasSession();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSession,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data ?? false) {
          return HomePage(authService: _authService);
        }

        return LoginPage(authService: _authService);
      },
    );
  }
}
