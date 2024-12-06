import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({required this.username});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _language = 'en';
  String homeTitle = 'Loading...';
  String welcomeText = 'Loading...';
  String greetingMessage = 'Loading...';
  List<dynamic> _newsArticles = [];
  Map<String, dynamic>? _weatherData;
  String _city = 'istanbul';
  bool _isLoading = true;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadLanguageAndSetTexts();
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
  String url;
  if (_language == 'tr') {
    // Türkçe haberler için URL
    url = 'https://api.collectapi.com/news/getNews?country=tr&tag=general';
  } else {
    // İngilizce haberler için URL
    url = 'https://newsapi.org/v2/top-headlines?country=us&apiKey=96287d2df6914204af9b1c79b489500d';
  }

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: _language == 'tr'
          ? {
              'content-type': 'application/json',
              'authorization': 'apikey 3liK3HUBCBw1cohdV7C4oC:0AQH5Lkj2HKRa4vTprvtDW'
            }
          : null,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        if (_language == 'tr') {
          // Türkçe API'nin JSON formatını işlerken null kontrolü
          _newsArticles = (data['result'] as List).where((article) {
            return article['image'] != null &&
                article['image'].isNotEmpty &&
                article['name'] != null &&
                article['description'] != null;
          }).toList();
        } else {
          // İngilizce API'nin JSON formatını işlerken null kontrolü
          _newsArticles = data['articles'].where((article) {
            return article['urlToImage'] != null &&
                article['urlToImage'].isNotEmpty;
          }).toList();
        }
      });
    } else {
      print('Haberleri getirirken hata oluştu: ${response.statusCode}');
    }
  } catch (e) {
    print('Haberleri getirirken bir hata oluştu: $e');
  }
}


  Future<void> _fetchWeather() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.collectapi.com/weather/getWeather?data.lang=$_language&data.city=$_city'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'apikey 3liK3HUBCBw1cohdV7C4oC:0AQH5Lkj2HKRa4vTprvtDW'
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _weatherData = jsonDecode(response.body)['result'][0];
        });
      } else {
        print('Hava durumu getirilemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('Hava durumu getirirken hata oluştu: $e');
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

  Future<bool> _validateImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      return response.statusCode == 200;
    } catch (e) {
      print('Resim doğrulama hatası: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return MaterialApp(
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(homeTitle),
              Text(
                '${widget.username} 👋',
                style: TextStyle(fontSize: 16),
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
            Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
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
                      style: TextStyle(fontSize: 16),
                    ),
                    subtitle: Text(
                      '${_weatherData!['degree']}°C',
                    ),
                    trailing: Text(
                      '${_weatherData!['date']}\n${_weatherData!['day']}',
                      style: TextStyle(fontSize: 12),
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
            final imageUrl = _language == 'tr' ? article['image'] : article['urlToImage'];
            final title = _language == 'tr' ? article['name'] : article['title'];
            final description = _language == 'tr' ? article['description'] : article['description'];

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
                        child: Image.network(
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            description ?? (_language == 'tr' ? 'Açıklama Yok' : 'No Description'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14),
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
                        style: TextStyle(
                            fontSize: 24, color: Colors.deepPurpleAccent),
                      ),
                    ),
            ),
          ],
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(imageUrl),
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
