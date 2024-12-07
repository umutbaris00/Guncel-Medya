import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var usernameController = TextEditingController();
  var passController = TextEditingController();

  var animationLink = 'assets/animations/animated_login_screen.riv';
  SMITrigger? failTrigger, successTrigger;
  SMIBool? isHandsUp, isChecking;
  SMINumber? lookNum;
  StateMachineController? stateMachineController;
  Artboard? artboard;

  String _language = 'en'; 

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();

    RiveFile.initialize().then((_) async {
      final value = await rootBundle.load(animationLink);
      final file = RiveFile.import(value);
      final art = file.mainArtboard;
      stateMachineController =
          StateMachineController.fromArtboard(art, "Login Machine");

      if (stateMachineController != null) {
        art.addController(stateMachineController!);

        stateMachineController!.inputs.forEach((element) {
          if (element.name == "isChecking") {
            isChecking = element as SMIBool;
          } else if (element.name == "isHandsUp") {
            isHandsUp = element as SMIBool;
          } else if (element.name == "trigSuccess") {
            successTrigger = element as SMITrigger;
          } else if (element.name == "trigFail") {
            failTrigger = element as SMITrigger;
          } else if (element.name == "numLook") {
            lookNum = element as SMINumber;
          }
        });
      }
      setState(() => artboard = art);
    });
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('selectedLanguage') ?? 'tr';
    });
  }

  Future<void> _saveLoginAndProceed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', usernameController.text);
    await prefs.setString('password', passController.text);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(username: usernameController.text), 
      ),
    );
  }

  void lookAround() {
    isChecking?.change(true);
    isHandsUp?.change(false);
    lookNum?.change(0);
  }

  void moveEyes(value) {
    lookNum?.change(value.length.toDouble());
  }

  void handsUpOnEyes() {
    isHandsUp?.change(true);
    isChecking?.change(false);
  }

  void loginClick() {
    isChecking?.change(false);
    isHandsUp?.change(false);
    
    successTrigger?.fire();
    setState(() {});


    Future.delayed(const Duration(seconds: 3), () {
      _saveLoginAndProceed();
    });
    
    


  }

  @override
  Widget build(BuildContext context) {
    final isTurkish = _language == 'tr';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black87,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (artboard != null)
                SizedBox(
                  width: 500,
                  height: 300,
                  child: Rive(artboard: artboard!),
                ),

              Padding(
                padding: const EdgeInsets.all(15.0),
                child: _buildTextField(
                  controller: usernameController,
                  labelText: isTurkish ? 'Kullanıcı Adı' : 'Username',
                  onTap: lookAround,
                  onChanged: moveEyes,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0, right: 15, top: 0),
                child: _buildTextField(
                  controller: passController,
                  labelText: isTurkish ? 'Şifre' : 'Password',
                  onTap: handsUpOnEyes,
                  obscureText: true,
                ),
              ),
              const SizedBox(height: 10),
              
              Container(
                height: 50,
                width: 250,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: MaterialButton(
                  onPressed: loginClick,
                  child: Text(
                    isTurkish ? 'Giriş Yap' : 'Login',
                    style: const TextStyle(color: Colors.white, fontSize: 25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    Function(String)? onChanged,
    VoidCallback? onTap,
  }) {
    return Container(
      alignment: Alignment.center,
      height: 80,
      width: 400,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          onTap: onTap,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 20),
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
