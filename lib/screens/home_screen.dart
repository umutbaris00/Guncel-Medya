import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'profile_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  
  const HomeScreen({required this.username});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Uint8List? _webImage; 
  File? _imageFile; 
  String _language = 'en';
  String homeTitle = 'Loading...';
  String welcomeText = 'Loading...';
  String greetingMessage = 'Loading...';
  List<dynamic> _newsArticles = [];
  bool _isLoading = true;
  bool _isDarkMode = false;
  bool _isCustomTheme = false;

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
    welcomeText = _language == 'tr'
        ? 'Hoşgeldiniz, ${widget.username}!'
        : 'Welcome, ${widget.username}!';

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
    final textTheme = _isCustomTheme
      ? GoogleFonts.oswald(  
          color: Colors.red,
          fontSize: 18,
        )
      : GoogleFonts.roboto(
          color: const Color.fromARGB(255, 158, 158, 158),
          fontSize: 16,
        );
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                homeTitle,
                style: textTheme.copyWith(fontSize: 20, color: Colors.white),
              ),
              Row(
                children: [
                  Icon(_isDarkMode ? Icons.nights_stay : Icons.wb_sunny,
                      color: _isDarkMode ? Colors.yellow : Colors.orange), 
                  Switch(
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        _isDarkMode = value;
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.color_lens),
                    onPressed: () {
                      setState(() {
                        _isCustomTheme = !_isCustomTheme;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: Colors.deepPurpleAccent,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadLanguageAndSetTexts();
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NewsDetailScreen(
                                  imageUrl: imageUrl ?? '',
                                  description: description ?? '',
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title ?? (_language == 'tr'
                                            ? 'Başlık Yok'
                                            : 'No Title'),
                                        style: textTheme.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        description ?? (_language == 'tr'
                                            ? 'Açıklama Yok'
                                            : 'No Description'),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.copyWith(fontSize: 14),
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
                        style: textTheme.copyWith(
                            fontSize: 24, color: Colors.deepPurpleAccent),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class NewsDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String description;
  const NewsDetailScreen({
    required this.imageUrl,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('News Detail'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (imageUrl.isNotEmpty) Image.asset(imageUrl),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                description,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
