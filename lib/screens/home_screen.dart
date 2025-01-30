import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme_provider.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({required this.username, Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Uint8List? _webImage;
  File? _imageFile;
  String _language = 'en';
  String homeTitle = 'Loading...';
  String welcomeText = 'Loading...';
  List<dynamic> _newsArticles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLanguageAndSetTexts();
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) {
      final savedData = prefs.getString('user_avatar_web');
      if (savedData != null) {
        setState(() {
          _webImage = Uint8List.fromList(savedData.codeUnits);
        });
      }
    } else {
      final savedPath = prefs.getString('user_avatar');
      if (savedPath != null && savedPath.isNotEmpty) {
        final file = File(savedPath);
        if (await file.exists()) {
          setState(() {
            _imageFile = file;
          });
        }
      }
    }
  }

  Widget getProfileIcon() {
    if (_webImage != null) {
      return CircleAvatar(
        backgroundImage: MemoryImage(_webImage!),
        radius: 12,
      );
    } else if (_imageFile != null) {
      return CircleAvatar(
        backgroundImage: FileImage(_imageFile!),
        radius: 12,
      );
    } else {
      return Icon(Icons.person);
    }
  }

  Future<void> _loadLanguageAndSetTexts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('selectedLanguage') ?? 'en';
    homeTitle = _language == 'tr' ? 'Ana Sayfa' : 'Home';
    welcomeText =
        _language == 'tr' ? 'Hoşgeldiniz, ${widget.username}!' : 'Welcome, ${widget.username}!';
    await _fetchNews();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchNews() async {
    try {
      final String response = await rootBundle.loadString(
        _language == 'tr' ? 'assets/news_tr.json' : 'assets/news_en.json',
      );
      final data = jsonDecode(response);
      setState(() {
        _newsArticles = data['articles'];
      });
    } catch (e) {
      print('Error loading local news: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(homeTitle, style: GoogleFonts.oswald()),
        backgroundColor: Colors.deepPurpleAccent,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? CupertinoIcons.sun_max_fill
                  : CupertinoIcons.moon_stars_fill,
              color: themeProvider.themeMode == ThemeMode.dark 
                  ? Colors.amber 
                  : const Color.fromARGB(255, 219, 219, 219),
            ),
            onPressed: () {
              themeProvider.toggleTheme(themeProvider.themeMode != ThemeMode.dark);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _newsArticles.isNotEmpty
                ? ListView.builder(
                    itemCount: _newsArticles.length,
                    itemBuilder: (context, index) {
                      final article = _newsArticles[index];
                      final imageUrl = article['image'];
                      final title = article['title'];
                      final description = article['description'];
                      return GestureDetector(
                        onTap: () {
                          context.push('/news_detail', extra: {
                            'imageUrl': imageUrl?.toString() ?? '',
                            'description': description?.toString() ?? '',
                          });
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (imageUrl != null && imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                  child: Image.asset(
                                    imageUrl,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title ?? (_language == 'tr' ? 'Başlık Yok' : 'No Title'),
                                      style: GoogleFonts.roboto(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      description ?? (_language == 'tr' ? 'Açıklama Yok' : 'No Description'),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.roboto(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      _language == 'tr' ? 'Haber bulunamadı!' : 'No News!',
                      style: GoogleFonts.roboto(fontSize: 24, color: Colors.deepPurpleAccent),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: _language == 'tr' ? 'Ana Sayfa' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: getProfileIcon(),
            label: _language == 'tr' ? 'Profil' : 'Profile',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            context.push('/profile');
          }
        },
      ),
    );
  }
}
