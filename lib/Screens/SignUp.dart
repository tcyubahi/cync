import 'package:Cync/Screens/Home.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Assets
import '../Assets/AppColors.dart';

class SignUp extends StatefulWidget {
  SignUp({Key key, this.phone, this.verificationID, this.code}) : super(key: key);

  final String phone;
  final String verificationID;
  final String code;

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {

  final TextEditingController usernameFieldController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final dbRef = Firestore.instance;

  final usersCollection = 'users';

  bool isBusy = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    usernameFieldController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ));
  }

  void _signUserIn() async {

    setState(() {
      isBusy = true;
    });

    final AuthCredential credential = PhoneAuthProvider.getCredential(
        verificationId: widget.verificationID,
        smsCode: widget.code
    );

    final FirebaseUser user = (await _auth.signInWithCredential(credential)).user;

    final FirebaseUser currentUser = await _auth.currentUser();

    print(user.phoneNumber);
    print(currentUser.phoneNumber);

    setState(() {
      isBusy = false;
    });

    if(user != null && currentUser != null && user.phoneNumber == currentUser.phoneNumber) {
      _activateAccount();
    } else {
      _showSnackBar('Error authenticating');
    }
  }

  void _activateAccount() async {

    await dbRef.collection(usersCollection).document(widget.phone)
        .setData({'active': true}, merge: true)
        .whenComplete((){
            _goHome();
        })
        .catchError(() {
          _showSnackBar('Error activating account');
        });
  }

  void _goHome() async {

    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Home(phone: widget.phone, title: 'Cync', camera: firstCamera)), ModalRoute.withName('home'));
  }

  void _createUser() async {

    String username = usernameFieldController.text;

    setState(() {
      isBusy = true;
    });

    await dbRef.collection(usersCollection).document(widget.phone)
        .setData({
          'phone': widget.phone,
          'username': username,
          'joined': FieldValue.serverTimestamp(),
          'active': false
        }).whenComplete(() {
          _signUserIn();
        }).catchError((){
          _showErrorDialog('Error signing you up');
        });

    setState(() {
      isBusy = false;
    });
  }

  void _validateUserName() {
    String username = usernameFieldController.text.toLowerCase();
    if(username.length < 4) {
      _showSnackBar('Username must be at least 6 characters in length');
    } else {
      if(_isValidUsername(username)) {
        _createUser();
      } else {
        _showSnackBar('Username should only contain characters');
      }
    }
  }

  bool _isValidUsername(String username) {
    bool isValid = true;
    for(int i = 0; i < username.length; i++) {
      if(username.codeUnitAt(i) <= 'a'.codeUnitAt(0) || username.codeUnitAt(i) >= 'z'.codeUnitAt(0)) {
        isValid = false;
      }
    }
    return isValid;
  }

  Future<void> _showErrorDialog(String message) {
    return showDialog<void> (
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Center(
                    child: Text(message),
                  )
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Okay'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: GestureDetector(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 32,
                  width: MediaQuery.of(context).size.width,
                ),
                Text(
                  "Sign Up",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.tealTextColor
                  ),
                ),
                SizedBox(
                  height: 32,
                ),
                Padding(
                    padding: EdgeInsets.only(left: 32, right: 32),
                    child: Text("Let's start by creating your username for your profile on Cync")
                ),
                SizedBox(height: 32),
                Row(
                  children: <Widget>[
                   SizedBox(width: 32),
                    Text("Username", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.disabledTextColor))
                  ]
                ),
                SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    SizedBox(width: 32),
                    Expanded(
                      child: Container(
                        child: TextField(
                          controller: usernameFieldController,
                          keyboardType: TextInputType.text,
                          maxLength: 24,
                          decoration: InputDecoration(
                              border: OutlineInputBorder()
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 32),
                  ],
                ),
                SizedBox(height: 32),
                RaisedButton(
                  elevation: 2,
                  disabledElevation: 0,
                  color: AppColors.tealBackgroundColor,
                  disabledColor: AppColors.disabledTextColor,
                  textColor: AppColors.white,
                  disabledTextColor: AppColors.disabledTextColor,
                  padding: EdgeInsets.all(0.0),
                  child: Container(
                    child: Text(
                        "Sign up",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                        )),
                  ),
                  onPressed: (){
                    _validateUserName();
                  },
                ),
                SizedBox(height: 32),
                Center(
                  child: Visibility(
                    visible: isBusy, // TODO: Add state
                    child: CircularProgressIndicator(),
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
      ),
    );
  }
}