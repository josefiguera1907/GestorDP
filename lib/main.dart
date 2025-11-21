import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';

import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/setup_screen.dart';
import 'presentation/providers/package_provider.dart';
import 'presentation/providers/location_provider.dart';
import 'presentation/providers/warehouse_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'data/datasources/database_helper.dart';
import 'data/services/setup_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/memory_manager.dart';
import 'core/utils/performance_config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Aplicar optimizaciones de rendimiento para dispositivos bajos recursos
  PerformanceConfig.applyOptimizations();

  // Iniciar gestor de memoria optimizado para 1GB RAM
  MemoryManager().startMonitoring();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PackageProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => WarehouseProvider()),
      ],
      child: const MyApp(),
    ),
  );

  // Crear índices en background después de 15 segundos (para no sobrecargar inicio)
  // Ajustado para dispositivos con recursos limitados
  Future.delayed(const Duration(seconds: 15), () async {
    await DatabaseHelper().database; // Inicializar si no está
    // Crear índices de forma más eficiente en dispositivos bajos recursos
    await DatabaseHelper().createRemainingIndexes();
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isFirstTimeSetup = false;
  bool _isCheckingSetup = true;

  @override
  void initState() {
    super.initState();
    // Verificar si es la primera vez
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeSetup();
    });
  }

  Future<void> _checkFirstTimeSetup() async {
    try {
      final setupService = SetupService();
      final isFirstTime = await setupService.isFirstTimeSetup();
      setState(() {
        _isFirstTimeSetup = isFirstTime;
        _isCheckingSetup = false;
      });

      // Si no es primera vez, verificar sesión
      if (!isFirstTime && mounted) {
        context.read<AuthProvider>().checkSession();
      }
    } catch (e) {
      print('Error checking setup: $e');
      setState(() {
        _isCheckingSetup = false;
      });
    }
  }

  Widget _buildHome(AuthProvider authProvider) {
    if (_isCheckingSetup) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isFirstTimeSetup) {
      return const SetupScreen();
    }

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authProvider.isAuthenticated) {
      print('✅ Autenticado - Mostrando HomeScreen');
      return const HomeScreen();
    }

    print('❌ No autenticado - Mostrando LoginScreen');
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        // Debug logs
        print('🔄 Build: isCheckingSetup=$_isCheckingSetup, isFirstTimeSetup=$_isFirstTimeSetup, isAuthenticated=${authProvider.isAuthenticated}');

        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Sistema de Paquetería',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: _buildHome(authProvider),
          builder: (context, child) {
            // Optimización para TC26 y dispositivos móviles pequeños
            final mediaQueryData = MediaQuery.of(context);
            final screenWidth = mediaQueryData.size.width;

            // Ajustar escala de texto basado en el tamaño de pantalla
            double scaleFactor = 1.0;
            if (screenWidth < 360) {
              // Pantallas muy pequeñas (TC26) - reducir el escalado
              scaleFactor = 0.85;
            } else if (screenWidth < 600) {
              // Pantallas pequeñas normales
              scaleFactor = 0.95;
            } else {
              // Tablets y más grandes
              scaleFactor = 1.0;
            }

            return MediaQuery(
              data: mediaQueryData.copyWith(
                // Usar solo textScaler (nuevo API de Flutter)
                textScaler: TextScaler.linear(scaleFactor.clamp(0.8, 1.3)),
              ),
              child: ScrollConfiguration(
                // Optimización para mejor desempeño en scroll
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: { PointerDeviceKind.touch, PointerDeviceKind.mouse },
                ),
                child: child!,
              ),
            );
          },
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            // Deshabilitar el efecto de overscroll para mejor rendimiento
            overscroll: false,
            dragDevices: { PointerDeviceKind.touch, PointerDeviceKind.mouse },
          ),
        );
      },
    );
  }
}