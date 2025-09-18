import 'package:flutter/material.dart';
import 'package:pos_rp/providers/auth_provider.dart';
import 'package:pos_rp/providers/cart_provider.dart';
import 'package:pos_rp/providers/customer_provider.dart';
import 'package:pos_rp/providers/settings_provider.dart';
import 'package:pos_rp/providers/purchase_provider.dart';
import 'package:pos_rp/providers/printer_provider.dart';
import 'package:pos_rp/providers/expense_provider.dart';
import 'package:pos_rp/providers/supplier_provider.dart';
import 'package:pos_rp/providers/product_provider.dart';
import 'package:pos_rp/providers/transaction_provider.dart';
import 'package:pos_rp/screens/login_screen.dart';
import 'package:pos_rp/screens/main_screen.dart';
import 'package:pos_rp/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  // Ensure that plugin services are initialized so that we can read the
  // session status before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // We will use AuthProvider to check the login status, so we can remove
  // the logic from here and handle it with a FutureBuilder in the UI.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => ProductProvider()),
        ChangeNotifierProvider(create: (ctx) => CustomerProvider()),
        ChangeNotifierProvider(create: (ctx) => TransactionProvider()),
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        ChangeNotifierProvider(create: (ctx) => SupplierProvider()),
        ChangeNotifierProvider(create: (ctx) => PurchaseProvider()),
        ChangeNotifierProvider(create: (ctx) => ExpenseProvider()),
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => PrinterProvider()),
        ChangeNotifierProvider(create: (ctx) => SettingsProvider()),
      ],
      child: Consumer2<SettingsProvider, AuthProvider>(
        builder: (context, settings, auth, child) {
          return MaterialApp(
            title: settings.name ?? 'Kasir Robin Puspa',
            theme: _buildTheme(settings.themeColor, Brightness.light),
            darkTheme: _buildTheme(settings.themeColor, Brightness.dark),
            themeMode: settings.themeMode,
            debugShowCheckedModeBanner: false,
            // Use a FutureBuilder to wait for the AuthProvider to load the user session.
            // This replaces the need for a separate SplashScreen.
            home: FutureBuilder(
              // The AuthProvider constructor calls _loadCurrentUser, which is a future.
              // We can listen to the provider to know when the user state is ready.
              future: auth.isReady,
              builder: (ctx, authResultSnapshot) {
                if (authResultSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  // While waiting, you can show a simple splash screen or a loading indicator.
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // If logged in, go to MainScreen, otherwise go to LoginScreen.
                return auth.isLoggedIn
                    ? const MainScreen()
                    : const LoginScreen();
              },
            ),
            routes: {
              '/main': (ctx) => const MainScreen(),
              '/login': (ctx) => const LoginScreen(),
              '/register': (ctx) => const RegisterScreen(),
            },
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Color seedColor, Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
      useMaterial3: true,
    );
  }
}
