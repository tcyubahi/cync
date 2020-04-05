import 'package:Cync/Screens/AuthScreen.dart';
import 'package:Cync/Screens/Home.dart';
import 'package:Cync/Screens/Login.dart';
import 'package:flutter/material.dart';
import 'Assets/AppColors.dart';


  void main() => runApp(CyncApp());

  class CyncApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Cync',
        debugShowCheckedModeBanner: false, // TODO: Remove for prod
        theme: ThemeData(
            primarySwatch: Colors.teal,
            focusColor: AppColors.lightGreen
        ),
        home: AuthScreen(),
        routes: {
          '/home': (BuildContext context) => Home(),
          '/login': (BuildContext context) => Login(),
        },
      );
    }
  }
