import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _language = 'tr'; 
  late String loginTitle = '...';
  late String usernameLabel = '...';
  late String passwordLabel = '...';
  late String loginButton = '...';

  @override
  void initState() {
    super.initState();
    _loadLanguageAndSetTexts();
  }

  Future<void> _loadLanguageAndSetTexts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _language = prefs.getString('selectedLanguage') ?? 'tr'; 


    if (_language == 'tr') {
      loginTitle = 'Giriş Yap';
      usernameLabel = 'Kullanıcı Adı';
      passwordLabel = 'Şifre';
      loginButton = 'Giriş Yap';
    } else if (_language == 'en') {
      loginTitle = 'Login';
      usernameLabel = 'Username';
      passwordLabel = 'Password';
      loginButton = 'Log In';
    }

    setState(() {}); 
  }

  Future<void> _saveLoginAndProceed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _usernameController.text);
    await prefs.setString('password', _passwordController.text);


    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(username: _usernameController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(loginTitle),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: false, 
      body: Container(
        width: double.infinity, 
        height: double.infinity, 
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[200]!, Colors.blue[800]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 100),
                Text(
                  loginTitle,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: usernameLabel,
                    labelStyle: TextStyle(color: const Color.fromARGB(255, 2, 0, 0)), 
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: passwordLabel,
                    labelStyle: TextStyle(color: const Color.fromARGB(255, 5, 0, 0)), 
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _saveLoginAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent, 
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    loginButton,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
