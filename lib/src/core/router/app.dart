import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:pethome_app/src/features/auth/presentation/pages/login_page.dart';
import 'package:pethome_app/src/features/home/presentation/pages/home_page.dart';
import 'package:pethome_app/src/features/tracking/presentation/pages/tracking_page.dart';
import 'package:pethome_app/src/core/features/compras/providers/carrito_provider.dart';
import 'package:pethome_app/src/core/features/compras/data/services/carrito_service.dart';
import 'package:pethome_app/src/features/appointments/data/appointments_service.dart';
import 'package:pethome_app/src/features/pets/data/pets_service.dart';

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

    final authService = AuthService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CarritoProvider>(
          create: (_) => CarritoProvider(
            carritoService: CarritoService(authService: authService),
            appointmentsService: AppointmentsService(authService: authService),
            petsService: PetsService(authService: authService),
          )..loadCarrito(),
        ),
      ],
      child: MaterialApp(
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

      onGenerateRoute: (settings) {
        if (settings.name == TrackingPage.routeName) {
          final args = settings.arguments;
          if (args is TrackingRouteArgs) {
            return MaterialPageRoute(
              builder: (_) => TrackingPage(
                authService: args.authService,
                roleNombre: args.roleNombre,
              ),
            );
          }
        }
        return null;
      },

      home: const SessionGate(),
      ),
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

class TrackingRouteArgs {
  const TrackingRouteArgs({
    required this.authService,
    required this.roleNombre,
  });

  final AuthService authService;
  final String roleNombre;
}
