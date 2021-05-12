/*
  Oliver Thurston Lynch
  May 11th 2020
  Bitriser
*/

import 'package:bitriser/settings.dart';
import 'package:bitriser/storage.dart';
import 'package:bitriser/coinbase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bitriser',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'bitriser', storage: UserStorage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title, this.storage}) : super(key: key);

  final String title;
  final UserStorage storage;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _curTime = 'Time',
      _snoozeTime = 'Snooze',
      _alarmTime = 'Time',
      _currency = 'Currency',
      _amount = 'Amount',
      _value = 'Value';
  String _image =
      'https://firebasestorage.googleapis.com/v0/b/bitriser.appspot.com/o/nouser.jpg?alt=media&token=048cf3b4-fc96-4ed8-bfc2-524cb2862c11';

  bool _visible = false;
  bool _snoozed = false;
  UserStorage storage;
  var user;

  var exchange = {
    'name': 'Coinbase',
    'icon': 'assets/coinbase.png',
    'api_key': '',
    'secret': '',
    'data': ''
  };

  final snackBar = SnackBar(
    content: Text('You bought coin!'),
  );

  @override
  void initState() {
    super.initState();

    //starts the check every second to update clock
    Timer.periodic(Duration(seconds: 1), (Timer t) => _getCurTime());
    Timer.periodic(Duration(seconds: 1), (Timer t) => alarm());
    Timer.periodic(Duration(seconds: 10), (Timer t) => _getbalance());
    _getUID();
    _getbalance();
    _getImage();
  }

  Future _getUID() async {
    user = FirebaseAuth.instance.currentUser;
    storage = UserStorage(uid: user.uid);
  }

  void _snooze() async {
    _buycoin();
    setState(() {
      _snoozed = true;
      _visible = false;
      _snoozeTime = DateFormat('kk:mm')
          .format(DateTime.now().add(Duration(minutes: 1)))
          .toString();
    });
  }

  void _wakeUp() async {
    _snoozeTime = 'awake';
    _visible = false;
    _snoozed = false;
  }

  void _getImage() async {
    _image = await storage.getimage();
    print(_image);
  }

  void _getCurTime() {
    final String formattedDateTime =
        DateFormat('kk:mm').format(DateTime.now()).toString();
    setState(() {
      _curTime = formattedDateTime;
    });
  }

  void alarm() async {
    _alarmTime = await storage.getAlarm();

    if (_curTime == _alarmTime && _snoozed == false) {
      setState(() {
        _visible = true;
      });
    } else if (_snoozeTime == _curTime && _snoozed == true) {
      setState(() {
        _visible = true;
      });
    } else {
      setState(() {
        _visible = false;
      });
    }
  }

  void _getbalance() async {
    await _getkeys();
    if (exchange['apiKey'] != 'Key') {
      var balances = await fetchCoinbase(exchange);
      setState(() {
        _currency = balances['currency'];
        _amount = balances['amount'];
        _value = balances['value'];
      });
    } else {
      print('no api keys');
    }
  }

  Future _getkeys() async {
    String key = await storage.getKey();
    String secret = await storage.getSecret();
    exchange['apiKey'] = key;
    exchange['secret'] = secret;
  }

  Future _buycoin() async {
    await _getkeys();
    if (exchange['apiKey'] != 'Key') {
      await purchaseCoin(exchange);
      _getbalance();
    } else {
      print('no api keys');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 100.0,
              //color: Colors.blue[50],
            ),
            Container(
              padding: EdgeInsets.all(20.0),
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => UserSettings()));
                },
                child: CircleAvatar(
                  foregroundImage: NetworkImage(_image),
                ),
              ),
            ),
            Text(
              _curTime,
              style: TextStyle(fontSize: 100),
            ),
            Text(
              '$_currency: $_amount, \$$_value', //.toString(),
            ),
            Text(
              'alarm set for: $_alarmTime', //.toString(),
            ),
            ElevatedButton(
              child: Text('Buy BTC'),
              onPressed: () {
                _buycoin();
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
              style: ElevatedButton.styleFrom(primary: Colors.grey),
            ),
            Container(
              height: 280.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Visibility(
                    visible: _visible,
                    child: ElevatedButton(
                      child: Text('snooze'),
                      onPressed: () {
                        _snooze();
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      },
                      style: ElevatedButton.styleFrom(primary: Colors.red),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Visibility(
                    visible: _visible,
                    child: ElevatedButton(
                      child: Text('wakeup'),
                      onPressed: () {
                        _wakeUp();
                      },
                      style: ElevatedButton.styleFrom(primary: Colors.grey),
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
