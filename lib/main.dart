import 'dart:io';

import 'package:alcwireless/ui/login/loginscreen.dart';
import 'package:alcwireless/ui/main/mainscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'business/usercontrol.dart';

Future<String> _authUser(LoginData data) async {
  print('Name: ${data.name}, Password: ${data.password}');

  final userPath = FirebaseDatabase.instance.reference()
                    .child('GROUPS')
                    .child(data.name.toUpperCase());
  final dataSnapshot = await userPath.once();
  if (dataSnapshot.value == null){
    return 'Sai tên đăng nhập hoặc mật khẩu';
  } else {
    final passSnapshot = await userPath.child('AUTH').child('PASS').once();
    final nameSnapshot = await userPath.child('AUTH').child('NAME').once();
    if (passSnapshot.value == data.password){
      final userControl = UserControl();
      userControl.name = nameSnapshot.value;
      userControl.username = data.name;

      final pref = await SharedPreferences.getInstance();
      await pref.setString('username', data.name);
      await pref.setString('password', data.password);

      return null;
    } else {
      return 'Sai tên đăng nhập hoặc mật khẩu';
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp(
    name: 'test',
    options: FirebaseOptions(
      appId: '1:464535171463:android:4da9ddae3fbcb2c5b7a322',
      apiKey: 'AIzaSyDrSPtCdtrfnU5irWIXtwE5tJr0oNgUdiU',
      messagingSenderId: '297855924061',
      projectId: 'mqtt-sim800',
      databaseURL: 'https://mqtt-sim800.firebaseio.com/',
    ),
  ).then((value){
    SharedPreferences.getInstance().then((pref){
      final username = pref.getString('username');
      final password = pref.getString('password');
      if (username == null || password == null){
        runApp(MyApp(LoginScreen()));
        return;
      }
      LoginData loginData = LoginData(name: username, password: password);
      _authUser(loginData).then((value){
        if (value == null){
          runApp(MyApp(MainScreen()));
        } else {
          runApp(MyApp(LoginScreen()));
        }
      });
    });
  });
}


class MyApp extends StatelessWidget {
  Widget _homeWidget;
  MyApp(Widget widget){
    _homeWidget = widget;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        accentColor: Colors.pink[200],
        textTheme: TextTheme(
          headline3: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 45.0,
            color: Colors.white70,
          ),
          button: TextStyle(
            fontFamily: 'OpenSans',
          ),
          subtitle1: TextStyle(fontFamily: 'NotoSans'),
          bodyText2: TextStyle(fontFamily: 'NotoSans'),
        ),
      ),
      home: _homeWidget
    );
  }
}