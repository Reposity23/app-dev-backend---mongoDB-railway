import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'theme.dart';
import 'services/notification_service.dart'; // Import the new service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final appProvider = AppProvider();
  await appProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Toy Store',
      theme: AppTheme.lightTheme,
      home: Builder( // Wrap with a Builder
        builder: (context) {
          // Listen for order updates to show notifications
          _setupOrderUpdateListener(context);
          
          return Consumer<AppProvider>(
            builder: (context, provider, child) {
              return provider.isLoggedIn ? const MainScreen() : const LoginScreen();
            },
          );
        },
      ),
    );
  }

  void _setupOrderUpdateListener(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final notificationService = NotificationService();

    appProvider.onOrderDelivered = (order) {
      final user = appProvider.currentUser;
      if (user != null) {
        notificationService.show(
          context,
          name: user.username,
          toyName: order.toyName,
        );
      }
    };
  }
}
