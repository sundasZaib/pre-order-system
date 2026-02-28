import 'package:flutter/material.dart';
import 'package:pre_order_system/app/routes.dart';
import 'package:pre_order_system/features/auth/login_screen.dart';
import 'package:pre_order_system/features/auth/signup_screen.dart';
import 'package:pre_order_system/features/dashboard/dashboard_screen.dart';

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Canteen Preorder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.signup: (context) => const SignupScreen(),
        AppRoutes.dashboard: (context) => const DashboardScreen(),
      },
    );
  }
}
