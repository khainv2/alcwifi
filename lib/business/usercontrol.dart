

class UserControl {
  
  static final UserControl _singleton = UserControl._internal();
  factory UserControl(){
    return _singleton;
  }
  UserControl._internal();


  String username = '';
  String name = '';
}