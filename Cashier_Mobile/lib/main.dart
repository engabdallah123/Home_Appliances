import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/network/network_info.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/debts/providers/debts_provider.dart';
import 'features/expenses/providers/expenses_provider.dart';
import 'features/home/main_navigation_screen.dart';
import 'features/products/providers/products_provider.dart';
import 'features/products/providers/brands_provider.dart';
import 'features/notifications/providers/notifications_provider.dart';
import 'core/services/notification_service.dart';
import 'features/purchases/providers/purchases_provider.dart';
import 'features/returns/providers/returns_provider.dart';
import 'features/sales/providers/sales_provider.dart';
import 'features/suppliers/providers/suppliers_provider.dart';

import 'dart:ui';
import 'core/widgets/safe_error_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Global Flutter Error Interceptor
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint("🛑 [Global FlutterError]: ${details.exceptionAsString()}");
  };

  // 2. Global Async Platform Dispatcher Error Interceptor
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint("🛑 [Global Async Error]: $error\n$stack");
    return true; // Handled to prevent crash
  };

  // 3. Graceful Error Widget Builder (replaces red screen completely)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return SafeErrorWidget(details: details);
  };

  try {
    await LocalNotificationService().initialize();
  } catch (_) {}
  runApp(const CashierMobileApp());
}

class CashierMobileApp extends StatelessWidget {
  const CashierMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NetworkInfo()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => PurchasesProvider()),
        ChangeNotifierProvider(create: (_) => ReturnsProvider()),
        ChangeNotifierProvider(create: (_) => SuppliersProvider()),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => BrandsProvider()),
        ChangeNotifierProvider(create: (_) => DebtsProvider()),
        ChangeNotifierProvider(create: (_) => ExpensesProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider(), lazy: false),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Cashier',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,

            // Full Arabic RTL Setup
            locale: const Locale('ar', 'EG'),
            supportedLocales: const [
              Locale('ar', 'EG'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // Light Modern Theme
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              scaffoldBackgroundColor: AppColors.lightBackground,
              primaryColor: AppColors.primary,
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                secondary: AppColors.primaryDark,
                surface: AppColors.lightSurface,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                labelStyle: const TextStyle(color: AppColors.lightTextSecondary, fontSize: 13),
                hintStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.lightBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.lightBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
              fontFamily: 'Cairo',
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.lightSurface,
                foregroundColor: AppColors.lightTextPrimary,
                elevation: 0,
                centerTitle: false,
              ),
            ),

            // Dark Modern Theme
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: AppColors.darkBackground,
              primaryColor: AppColors.primary,
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                secondary: AppColors.accent,
                surface: AppColors.darkSurface,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.darkSurface,
                labelStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 13),
                hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.darkBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.darkBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5)),
              ),
              fontFamily: 'Cairo',
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.darkSurface,
                foregroundColor: AppColors.darkTextPrimary,
                elevation: 0,
                centerTitle: false,
              ),
            ),

            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isAuthenticated) {
      return const MainNavigationScreen();
    } else {
      return const LoginScreen();
    }
  }
}
