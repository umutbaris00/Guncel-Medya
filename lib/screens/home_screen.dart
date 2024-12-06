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

    homeTitle = _language == 'tr' ? 'Ana Sayfa' : 'Home';
    welcomeText = _language == 'tr'
        ? 'Hoşgeldiniz, ${widget.username}!'
        : 'Welcome, ${widget.username}!';

    greetingMessage = _getGreetingMessage();
    await _fetchNews(); 
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchNews() async {
    const url =
        'https://newsapi.org/v2/top-headlines?country=us&apiKey=96287d2df6914204af9b1c79b489500d';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _newsArticles = data['articles']
              .where((article) =>
                  article['urlToImage'] != null &&
                  article['urlToImage'].isNotEmpty &&
                  article['description'] != null &&
                  article['description'].isNotEmpty)
              .toList();
        });
      } else {
        print('Haberleri getirirken hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      print('Haberleri getirirken bir hata oluştu: $e');
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
              onPressed: () => _fetchNews(),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$greetingMessage, ${widget.username}!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _newsArticles.isNotEmpty
                  ? ListView.builder(
                      itemCount: _newsArticles.length,
                      itemBuilder: (context, index) {
                        final article = _newsArticles[index];
                        final imageUrl = article['urlToImage'];

                        return FutureBuilder(
                          future: _validateImage(imageUrl),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.data == true) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => NewsDetailScreen(
                                        imageUrl: imageUrl,
                                        description: article['description'] ??
                                            (_language == 'tr'
                                                ? 'Açıklama Yok'
                                                : 'No Description'),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              article['title'] ??
                                                  (_language == 'tr'
                                                      ? 'Başlık Yok'
                                                      : 'No Title'),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              article['description'] ??
                                                  (_language == 'tr'
                                                      ? 'Açıklama Yok'
                                                      : 'No Description'),
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
                            } else {
                              return SizedBox.shrink();
                            }
                          },
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        _language == 'tr' ? 'Hoşgeldiniz!' : welcomeText,
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

  Future<bool> _validateImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}

// Detay ekranı
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
        title: Text('News Details'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
