import 'dart:async';

import 'package:alcwireless/business/usercontrol.dart';
import 'package:alcwireless/ui/login/loginscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _name = '';
  String _load = 'TFKTFKTFFKT';
  DatabaseReference _stateReference;
  bool _onTransaction = false;
  Timer _timer;
  
  @override
  void initState(){
    super.initState();
    final userControl = UserControl();
    _name = userControl.name;
    final username = userControl.username;
    _stateReference = FirebaseDatabase.instance.reference()
                                      .child('GROUPS')
                                      .child(username.toUpperCase())
                                      .child('STATE');
    final loadViewNode = _stateReference.child('LOADVIEW');
    loadViewNode.onValue.listen((event) { 
      setState(() {
        _load = event.snapshot.value;
        
        setState(() {
          _onTransaction = false;
        });
        if (_timer != null && _timer.isActive){
          _timer.cancel();
        }
      });
    });
  }

  void saveToFirebase() async {
    setState(() {
      _onTransaction = true;
    });
    final auth = _stateReference.child('LOAD');
    await auth.runTransaction((MutableData mutableData) async {
      mutableData.value = _load;
      return mutableData;
    });

    if (_timer != null && _timer.isActive){
      _timer.cancel();
    }
    _timer = Timer.periodic(Duration(seconds: 5), (timer){ 
      setState(() {
        _onTransaction = false;
      });
      final loadViewNode = _stateReference.child('LOADVIEW');
      loadViewNode.once().then((v){
        final loadViewValue = v.value;
        if (loadViewValue != _load){
          // Value is difference, rewrite load
          auth.runTransaction((MutableData mutableData) async {
            mutableData.value = loadViewValue;
            return mutableData;
          }).then((value){
            setState(() {
              _load = loadViewValue;
            });
            showDialog(
              context: context,
              builder: (_) => new AlertDialog(
                title: new Text("Thông báo"),
                content: new Text('Thiết lập không thành công, vui lòng thử lại sau'),
                actions: [
                  FlatButton(
                    child: Text('Đóng'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              )
            );
          });
        }
      });
      timer.cancel();
    });
  }

  Widget _drawCircle(Color color){
    return Container(
        width: 32,
        height: 32,
        decoration: new BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        )
      );
  }
 
  Widget _getDynamicSingleLed(String title, String value1, Color color1, bool value,
    Function(bool) onChange){

    Color textColor;
    if (onChange == null){
      textColor = Colors.black45;
    } else if (value){
      textColor = Colors.green;
    } else {
      textColor = Colors.red;
    }
    return Card(
      color: Colors.white54,
      child: Container(
        padding: EdgeInsets.only(
          left: 2,
          right: 2,
          top: 12,
          bottom: 0
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 18
              )
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _drawCircle(color1),
                      SizedBox(height: 4),
                      Text(
                        value1, 
                        style: TextStyle(
                          color: textColor
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Transform.scale( 
                        scale: 1.3,
                        child: new Switch(
                          value: value,
                          onChanged: onChange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        )
      )
    );
  }

  Widget _getHeaderTextUI(String text) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(top: 8.0, left: 0, right: 0),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          fontSize: 19,
          letterSpacing: 0.27,
          color: Colors.black45,
        ),
      ),
    );
  }

  String replaceCharAt(String oldString, int index, String newChar) {
    return oldString.substring(0, index) + newChar + oldString.substring(index + 1);
  }
    

  Widget _getCabinetListUI() {
    return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.65,
      ),
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          String valueText;
          Color color;
          bool state;

          if (_load[index] == 'T'){
            valueText = 'Bật';
            color = Colors.green;
            state = true;
          } else if (_load[index] == 'F'){
            valueText = 'Tắt';
            color = Colors.red;
            state = false;
          } else {
            valueText = 'NA';
            color = Colors.black26;
            state = false;
          }
          return Container(
            alignment: Alignment.center,
            child: _getDynamicSingleLed('Tải ${index + 1}', valueText, color, state, 
              ((_load[index] == 'T' || _load[index] == 'F') && !_onTransaction) ? (newValue){
                String oldLoad = _load;
                if (newValue == false){
                  setState(() {
                    _load = replaceCharAt(_load, index, 'F');
                  });
                } else {
                  setState(() {
                    _load = replaceCharAt(_load, index, 'T');
                  });
                }
                FirebaseDatabase.instance.reference().child('.info/connected').once()
                .then((isInternetConnected){
                  if (isInternetConnected.value){
                    saveToFirebase();
                  } else {
                    setState(() {
                      _load = oldLoad;
                    });
                    showDialog(
                      context: context,
                      builder: (_) => new AlertDialog(
                        title: new Text("Thông báo"),
                        content: new Text('Không có kết nối đến máy chủ, vui lòng chờ trong giây lát...'),
                        actions: [
                          FlatButton(
                            child: Text('Đóng'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          )
                        ],
                      )
                    );
                  }
                });
              } : null
            )
          );
        },
        childCount: _load.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          _name,
          textAlign: TextAlign.center,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.login,
              color: Colors.white
            ),
            onPressed: (){
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: Text('Đăng xuất?'),
                  content: Text('Đăng xuất khỏi tài khoản hiện tại?'),
                  actions: [
                    FlatButton(
                      child: Text('OK'),
                      onPressed: (){
                        SharedPreferences.getInstance()
                        .then((pref){
                          pref.setString('username', '').then((_){
                            pref.setString('password', '').then((_){
                              Navigator.pop(context);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => LoginScreen()),
                                (Route<dynamic> route) => false,
                              );
                            });
                          });
                          

                        });
                        

                      },
                    ),
                    FlatButton(
                      child: Text('Bỏ qua'),
                      onPressed: (){
                        Navigator.pop(context);
                      },
                    )
                  ],
                )
              );
            },
          )
        ],
      ),
      body: Center(
        child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.only(top: 15, bottom: 16, left: 6, right: 6),
        width: 600,
        child: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  SizedBox(height: 4),
                  _getHeaderTextUI('Danh sách tải (${_load.length})'),
                  SizedBox(height: 8),
                ]
              )
            ),
            _onTransaction ? SliverList(
              delegate: SliverChildListDelegate(
                [
                  SizedBox(height: 4),
                  Text('Đang cập nhật...'),
                  SizedBox(height: 8),
                ]
              )
            ) : null,
            Container(
              // width: 500,
              child: _getCabinetListUI()
            )
          ].where((element) => element != null).toList()
        ),
      )
      )
    );
  }
}