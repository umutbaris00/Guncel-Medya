import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'profile_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:io';

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
  Map<String, dynamic>? _weatherData;
  String _city = 'istanbul';
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
    _city = prefs.getString('selectedCity') ?? 'istanbul';
    homeTitle = _language == 'tr' ? 'Ana Sayfa' : 'Home';
    welcomeText = _language == 'tr'
        ? 'Hoşgeldiniz, ${widget.username}!'
        : 'Welcome, ${widget.username}!';
    greetingMessage = _getGreetingMessage();
    await _fetchNews();
    await _fetchWeather();
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

  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.collectapi.com/weather/getWeather?data.lang=$_language&data.city=$_city'),
        headers: {
          'content-type': '/json',
          'authorization': 'apikey 3liK3HUBCBw1cohdV7C4oC:0AQH5Lkj2HKRa4vTprvtDW'
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _weatherData = jsonDecode(response.body)['result'][0];
        });
      } else {
        print('Failed to fetch weather: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching weather: $e');
    }
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return _language == 'tr' ? 'Günaydın' : 'Good Morning';
    } else if (hour < 18) {
      return _language == 'tr' ? 'İyi Günler' : 'Good Afternoon';
    } else {
      return _language == 'tr' ? 'İyi Akşamlar' : 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = _isCustomTheme
        ? TextStyle(color: Colors.red, fontFamily: 'Courier', fontSize: 18)
        : TextStyle(
            color: const Color.fromARGB(255, 121, 121, 121),
            fontFamily: 'Arial',
            fontSize: 16);
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
            if (_weatherData != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: Image.network(
                      _weatherData!['icon'],
                      width: 50,
                      height: 50,
                    ),
                    title: Text(
                      '${_weatherData!['description'] ?? ''}',
                      style: textTheme,
                    ),
                    subtitle: Text(
                      '${_weatherData!['degree']}°C',
                      style: textTheme,
                    ),
                    trailing: Text(
                      '${_weatherData!['date']}\n${_weatherData!['day']}',
                      style: textTheme.copyWith(fontSize: 12),
                    ),
                  ),
                ),
              ),
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
