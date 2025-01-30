import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  Uint8List? _webImage;
  String? _username;
  String _language = 'en';
  

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      
      _username = prefs.getString('username') ?? 'Misafir';
      _language = prefs.getString('selectedLanguage') ?? 'en';
    });

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

  Future<void> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      if (kIsWeb) {
        if (result.files.single.bytes != null) {
          setState(() {
            _webImage = result.files.single.bytes;
            _imageFile = null;
          });
          _saveImageWeb(result.files.single.bytes!);
        }
      } else {
        if (result.files.single.path != null) {
          File file = File(result.files.single.path!);
          setState(() {
            _imageFile = file;
            _webImage = null;
          });
          _saveImageMobile(file);
        }
      }
    } else {
      print("Resim seçimi iptal edildi.");
    }
  }

  Future<void> _saveImageMobile(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final savedPath = '${directory.path}/user_avatar.png';
    final savedFile = await image.copy(savedPath);
    
    
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('user_avatar', savedFile.path);
    print("Resim mobilde kaydedildi: $savedPath");
  }

  Future<void> _saveImageWeb(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_avatar_web', String.fromCharCodes(bytes));
    print("Resim web'de kaydedildi.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            
            context.push('/home', extra: _username ?? 'Misafir');
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.purple.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_username != null)
                Text(
                  _username!,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              SizedBox(height: 20),
              if (_webImage != null)
                CircleAvatar(
                  radius: 60,
                  backgroundImage: MemoryImage(_webImage!),
                )
              else if (_imageFile != null)
                CircleAvatar(
                  radius: 60,
                  backgroundImage: FileImage(_imageFile!),
                )
              else
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.purple,
                  ),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _language == 'en' ? 'Change Profile Picture' : 'Profil Resmini Değiştir',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  context.push('/language_selection');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _language == 'en' ? 'Change Language' : 'Dil Değiştir',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
