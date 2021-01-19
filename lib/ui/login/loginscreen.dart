import 'package:alcwireless/business/usercontrol.dart';
import 'package:alcwireless/ui/main/mainscreen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatelessWidget {
  Duration get loginTime => Duration(milliseconds: 2250);

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
  @override
  Widget build(BuildContext context) {
    
    return FlutterLogin(
      title: 'ALCWireless',
    
      onLogin: _authUser,
      onSignup: null,
      onRecoverPassword: null,
      logo: 'assets/images/logo.png',
      passwordValidator: (text) => null,
      emailValidator: (text) => null,
      
      theme: LoginTheme(
        cardTheme: CardTheme(
          margin: EdgeInsets.all(40)
        ),
        
      ),
      messages: LoginMessages(
        usernameHint: 'Tên đăng nhập',
        passwordHint: 'Mật khẩu', 
        loginButton: 'Đăng nhập',
        confirmPasswordError: 'Mật khẩu chưa đúng',
        confirmPasswordHint: 'Mật khẩu',
        forgotPasswordButton: 'Quên mật khẩu',
        goBackButton: 'Quay lại',
        signupButton: 'Đăng ký', 
        recoverPasswordButton: '',
        recoverPasswordDescription: '',
        recoverPasswordIntro: '',
        recoverPasswordSuccess: ''
      ),
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => MainScreen(),
        ));
      },
    );
  }
}
