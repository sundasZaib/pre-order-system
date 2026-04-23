import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pre_order_system/app/canteen_app.dart';
import 'package:pre_order_system/shared/services/mock_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await MockAuthService.instance.restoreSession();
    runApp(const CanteenApp());
  } catch (error) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Firebase initialization failed. Check platform configuration files and try again.\n\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
