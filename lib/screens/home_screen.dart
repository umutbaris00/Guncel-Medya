import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/themes.dart'; // ThemeProvider burada tanımlı

class HomeScreen extends StatelessWidget {
  final String username;

  const HomeScreen({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ana Sayfa'),
        actions: [
          Row(
            children: [
              Text('Karanlık Mod'),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => themeProvider.toggleTheme(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Hoşgeldiniz, $username!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
