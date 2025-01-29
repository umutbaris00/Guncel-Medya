import 'package:flutter/material.dart';
import '../screens/loading.dart';
import '../screens/language_selection.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => LoadingScreen());
      case '/language':
        return MaterialPageRoute(builder: (_) => LanguageSelectionScreen());
      case '/auth':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/home':
        final String? username = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => HomeScreen(username: username ?? 'Kullanıcı'),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('404 - Route Not Found')),
          ),
        );
    }
  }
}
