import 'package:Cync/Screens/Home.dart';
import 'package:Cync/Screens/Login.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Assets
import '../Assets/AppColors.dart';

class AuthScreen extends StatefulWidget {
  AuthScreen({Key key}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final dbRef = Firestore.instance;
  final usersCollection = 'users';

  bool isBusy = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    setState(() {
      isBusy = true;
    });
    _authenticate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _authenticate() async {

    final FirebaseUser currentUser = await _auth.currentUser();

    setState(() {
      isBusy = false;
    });

    if(currentUser != null && currentUser.phoneNumber != null) {
      print(currentUser.phoneNumber);
      _getUserData(currentUser.phoneNumber);
    } else {
      _goToLogin();
    }
  }

  void _getUserData(String phoneNumber) async {

    await dbRef.collection(usersCollection)
        .document(phoneNumber)
        .get()
        .then((doc){
      if(doc.exists) {
        if(doc.data.containsKey("active") && doc.data['active']) {
          _goHome(phoneNumber, doc.data['username']);
        } else {

        }
      } else {

      }
    });
  }

  void _showSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ));
  }

  void _goHome(String phoneNumber, String username) async {

    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Home(phone: phoneNumber, title: 'Cync', camera: firstCamera)), ModalRoute.withName('home'));
  }

  void _goToLogin() {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Login()), ModalRoute.withName('login'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image(image: AssetImage('assets/images/logo.png'), width: 96, height: 96),
                SizedBox(height: 48),
                Center(
                  child: Visibility(
                    visible: isBusy,
                    child: CircularProgressIndicator(),
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
        ),
    );
  }
}