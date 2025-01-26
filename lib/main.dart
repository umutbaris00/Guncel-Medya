import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/themes.dart';
import 'screens/loading.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Güncel Medya',
            debugShowCheckedModeBanner: false, 
            theme: themeProvider.currentTheme,
            home: LoadingScreen(),
          );
        },
      ),
    );
  }
}
