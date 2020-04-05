import 'package:Cync/BLoC/BlocProvider.dart';
import 'package:Cync/Screens/Home.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SignUp.dart';

// Assets
import '../Assets/AppColors.dart';

class Login extends StatefulWidget {
  Login({Key key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {

  final String country = 'Rwanda';
  final TextEditingController phoneFieldController = TextEditingController();
  final TextEditingController codeFieldController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final dbRef = Firestore.instance;

  final String _countryCode = '+250';

  final usersCollection = 'users';

  String _verificationId;

  bool isBusy = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    phoneFieldController.dispose();
    codeFieldController.dispose();
    super.dispose();
  }

  Future<void> _showVerificationCodeView() async {
    return showDialog<void> (
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Verify Phone Number'),
            content: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Center(
                    child: Text('Enter the code we sent to your phone number below and tap Verify'),
                  ),
                  SizedBox(height: 16),
                  PinCodeTextField(
                    length: 6,
                    obsecureText: false,
                    animationType: AnimationType.fade,
                    shape: PinCodeFieldShape.underline,
                    animationDuration: Duration(milliseconds: 300),
                    fieldHeight: 44,
                    fieldWidth: 32,
                    textInputType: TextInputType.number,
                    activeColor: AppColors.tealBackgroundColor,
                    selectedColor: AppColors.tealBackgroundColor,
                    inactiveColor: AppColors.lightGreyIconsColor,
                    autoFocus: true,
                    controller: codeFieldController,
                  )
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                textColor: AppColors.lightGreyIconsColor,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Verify', style: TextStyle(fontWeight: FontWeight.bold)),
                textColor: AppColors.tealTextColor,
                  onPressed: () {
                  String code = codeFieldController.text;
                    if(code.length == 6) {
                      Navigator.of(context).pop();
                      authenticateUser(code);
                    } else{
                      _showSnackBar('Invalid code');
                    }
                  }
              )
            ],
          );
        }
    );
  }

  void _showSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
    ));
  }

  /// Method to handle phone number verification
  /// @param: void
  /// @return: void
  void _verifyNumber() {
    String phoneNumber = phoneFieldController.text;
    if(phoneNumber.isEmpty) {
      _showErrorDialog('Please enter a valid phone number');
    } else {
      verifyPhone(phoneNumber);
    }
  }

  verifyPhone(String phone) async {

    setState(() {
      isBusy = true;
    });

    final PhoneVerificationCompleted verificationCompleted = (AuthCredential phoneAuthCredential) {
      _auth.signInWithCredential(phoneAuthCredential);
      setState(() {
        isBusy = false;
      });
    };

    final PhoneVerificationFailed verificationFailed = (AuthException authException) {
      setState(() {
        isBusy = false;
      });
      _showErrorDialog(authException.message);
    };

    final PhoneCodeSent codeSent = (String verificationId, [int forceResendingToken]) async {
      _verificationId = verificationId;
      _showVerificationCodeView();
      setState(() {
        isBusy = false;
      });
    };

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout = (String verificationId) {
      _verificationId = verificationId;
      setState(() {
        isBusy = false;
      });
      //_showErrorDialog('Request timed out');
    };

    await _auth.verifyPhoneNumber(
        phoneNumber: _countryCode + phone,
        timeout: const Duration(seconds: 5),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout
    );
  }

  void authenticateUser(String code) async {

    setState(() {
      isBusy = true;
    });

    final AuthCredential credential = PhoneAuthProvider.getCredential(
        verificationId: _verificationId,
        smsCode: code
    );

    final FirebaseUser user = (await _auth.signInWithCredential(credential)).user;

    final FirebaseUser currentUser = await _auth.currentUser();

    setState(() {
      isBusy = false;
    });

    if(user != null && currentUser != null && user.phoneNumber == currentUser.phoneNumber) {
      _checkIfSignedUp(currentUser.phoneNumber, code);

    } else {
      _showSnackBar('Error authenticating');
    }
  }

  void _checkIfSignedUp(String phoneNumber, String code) async {

    await dbRef.collection(usersCollection)
        .document(phoneNumber)
        .get()
        .then((doc){
          if(doc.exists) {
            if(doc.data.containsKey("active") && doc.data['active']) {
              _goHome(phoneNumber);
            } else {
              _signNewUser(phoneNumber, code);
            }
          } else {
            _signNewUser(phoneNumber, code);
          }
    });
  }

  void _goHome(String phoneNumber) async {

    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Home(phone: phoneNumber, title: 'Cync', camera: firstCamera)), ModalRoute.withName('home'));
  }

  void _signNewUser(String phoneNumber, String code) async {

    await _auth.signOut();

    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SignUp(phone: phoneNumber, verificationID: _verificationId, code: code))
    );

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
                  "Get Started",
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
                    child: Text("Cync will send an SMS message to verify your phone number.")
                ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(width: 32),
                    DropdownButton<String>(
                      value: country,
                      iconSize: 32,
                      iconEnabledColor: AppColors.tealIconsColor,
                      elevation: 2,
                      style: TextStyle(color: AppColors.tealTextColor),
                      underline: Container(
                        height: 1,
                        color: AppColors.tealBackgroundColor,
                      ),
                      onChanged: (String newSelection) {
                        setState(() {
                          // TODO: Change country Selection
                        });
                      },
                      items: <String>['Rwanda'].map<DropdownMenuItem<String>> ((String newSelection){
                        return DropdownMenuItem<String>(
                          value: newSelection,
                          child: Text(newSelection, style: TextStyle(color: AppColors.black)),
                        );
                      }).toList(),
                    ),
                    SizedBox(width: 32)
                  ],
                ),
                SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    SizedBox(width: 32),
                    Container(
                      width: 64,
                      child: TextField(
                        enabled: false,
                        maxLines: 1,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '+250'
                        ),
                      ),
                    ),
                    SizedBox(width: 32),
                    Expanded(
                      child: Container(
                        child: TextField(
                          controller: phoneFieldController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                              border: OutlineInputBorder()
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 32),
                  ],
                ),
                SizedBox(height: 16),
                Text("Carrier SMS charges may apply",
                  style: TextStyle(color: AppColors.disabledTextColor),
                ),
                SizedBox(height: 48),
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
                            "Login",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                            )),
                      ),
                      onPressed: (){
                        _verifyNumber();
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