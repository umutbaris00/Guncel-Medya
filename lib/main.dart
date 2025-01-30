import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme_provider.dart';
import 'screens/loading.dart';
import 'screens/language_selection.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/news_detail.dart'; // Haber detay sayfasını ekledik!

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final GoRouter _router = GoRouter(
      initialLocation: '/loading',
      routes: [
        GoRoute(path: '/loading', builder: (context, state) => LoadingScreen()),
        GoRoute(path: '/language_selection', builder: (context, state) => LanguageSelectionScreen()),
        GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
        GoRoute(path: '/profile', builder: (context, state) => ProfileScreen()),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            final username = state.extra as String?;
            return HomeScreen(username: username ?? 'Guest');
          },
        ),
        GoRoute(
          path: '/news_detail',
          builder: (context, state) {
            final Map<String, String> newsData = state.extra as Map<String, String>;
            return NewsDetailScreen(
              imageUrl: newsData['imageUrl'] ?? '',
              description: newsData['description'] ?? 'Açıklama bulunamadı.',
            );
          },
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      routerConfig: _router,
    );
  }
}
