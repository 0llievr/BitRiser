/*
  Oliver Thurston Lynch
  May 11th 2020
  Bitriser
*/

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:bitriser/signin.dart';
import 'package:bitriser/storage.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class UserSettings extends StatefulWidget {
  @override
  _UserSettingsState createState() => _UserSettingsState();
}

class _UserSettingsState extends State<UserSettings> {
  firebase_storage.Reference ref =
      firebase_storage.FirebaseStorage.instance.ref('usrimages');

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _apiFormKey = GlobalKey<FormState>();
  final _amountformKey = GlobalKey<FormState>();
  final _timeFormKey = GlobalKey<FormState>();

  UserStorage storage;

  TextEditingController _alarmController;
  String _myKey, _mySecretKey, _alarmTime;

  double _myAmount;
  var user;

  File _image;
  final picker = ImagePicker();

  String _userImage =
      'https://firebasestorage.googleapis.com/v0/b/bitriser.appspot.com/o/nouser.jpg?alt=media&token=048cf3b4-fc96-4ed8-bfc2-524cb2862c11';

  @override
  void initState() {
    super.initState();

    //Intl.defaultLocale = 'pt_BR';
    String lsHour = TimeOfDay.now().hour.toString().padLeft(2, '0');
    String lsMinute = TimeOfDay.now().minute.toString().padLeft(2, '0');

    _alarmController = TextEditingController(text: '$lsHour:$lsMinute');
    print(lsHour + ":" + lsMinute);

    //print("my user id: " + user.uid);
    _getUID();
    _getAlarm(); //gets innitial value
    _getKeys();
    _getImage();
  }

  Future _getUID() async {
    user = FirebaseAuth.instance.currentUser;
    storage = UserStorage(uid: user.uid);
  }

  void _getImage() async {
    _userImage = await storage.getimage();
    print(_image);
  }

  Future _getKeys() async {
    //decrypt here
    _myKey = await storage.getKey();
    _mySecretKey = await storage.getSecret();
  }

  Future _camera() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _setimage();
        _getImage();
        print(_image);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _getAlarm() async {
    //and amount
    _alarmTime = await storage.getAlarm();

    String tempAmount = await storage.getAmount();
    print(tempAmount);

    setState(() {
      _alarmController.text = _alarmTime;
      _myAmount = double.parse(tempAmount);
    });
  }

  Future<void> _setAmount() async {
    _getUID();
    await storage.setAmount(myAmount: _myAmount.toString());
  }

  Future<void> _setKeys() async {
    //encrypt here
    await storage.updateAPIKeys(myApiKey: _myKey, mySecretKey: _mySecretKey);
  }

  Future<void> _setAlarm() async {
    await storage.setAlarm(myAlarm: _alarmTime);
  }

  Future<void> _setimage() async {
    String imageURL = await storage.uploadImage(_image).then((value) {
      return value;
    });

    print(imageURL);
    storage.setImage(imageURL);
  }

  String validateAmount(String amount) {
    double tmp = double.tryParse(amount);
    if (tmp >= 1) {
      return 'damn son you ritch ritch';
    }
    return null;
  }

  String validateAPI(String value) {
    if (value.isEmpty) {
      return 'Enter your API Key';
    }
    return null;
  }

  bool validateAndSaveAPI() {
    final form = _apiFormKey.currentState;
    if (form.validate()) {
      form.save();
      _setKeys();
      return true;
    }
    return false;
  }

  bool validateAndSaveAmount() {
    final form = _amountformKey.currentState;
    if (form.validate()) {
      form.save();
      _setAmount();
      return true;
    }
    return false;
  }

  List<Widget> apiForm() {
    return [
      TextFormField(
        key: Key('apikeykey'),
        decoration: InputDecoration(labelText: 'Enter your API Key'),
        validator: validateAPI,
        onSaved: (value) => setState(() {
          _myKey = value;
        }),
      ),
      TextFormField(
          key: Key('secretkey'),
          decoration: InputDecoration(labelText: 'Enter your secret Key'),
          validator: validateAPI,
          onSaved: (value) => setState(() {
                _mySecretKey = value;
              })),
      ElevatedButton(
        key: Key('submit'),
        child: Text('Set API keys'),
        onPressed: validateAndSaveAPI,
      ),
    ];
  }

  List<Widget> timeForm() {
    return [
      DateTimePicker(
        type: DateTimePickerType.time,
        controller: _alarmController,
        //initialValue: _initialValue,
        icon: Icon(Icons.access_time),
        timeLabelText: "Alarm",
        use24HourFormat: false,
        locale: Locale('en', 'US'),
        onSaved: (val) => setState(() => _alarmTime = val ?? ''),
      ),
      ElevatedButton(
        onPressed: () {
          final loForm = _timeFormKey.currentState;
          if (loForm?.validate() == true) {
            loForm?.save();
          }
          _setAlarm();
        },
        child: Text('Set alarm'),
      ),
    ];
  }

  List<Widget> amountForm() {
    return [
      TextFormField(
        key: Key('Amount'),
        decoration: InputDecoration(labelText: 'Amount of coin to purchase'),
        keyboardType: TextInputType.number,
        onSaved: (value) => setState(() {
          _myAmount = double.tryParse(value);
        }),
        validator: validateAmount,
      ),
      ElevatedButton(
        key: Key('submit'),
        child: Text('Set amount to purchase'),
        onPressed: validateAndSaveAmount,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Settings Page"),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(20.0),
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {
                _camera();
              },
              onLongPress: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Signin()),
                );
              },
              child: CircleAvatar(
                foregroundImage: NetworkImage(_userImage),
                //backgroundImage: AssetImage("assets/nouser.jpg"),
              ),
            ),
          ),
          Container(
            //height: 70.0,
            //color: Colors.blue[50],
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.all(20),
            child: Text(
              'Key: $_myKey\nSecret: $_mySecretKey\nAmount: $_myAmount\nAlarm: $_alarmTime',
              style: TextStyle(fontSize: 20),
            ),
          ),
          Container(
            padding: EdgeInsets.all(20.0),
            child: Column(children: [
              Form(
                  key: _apiFormKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: apiForm())),
              Form(
                  key: _timeFormKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: timeForm())),
              Form(
                  key: _amountformKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: amountForm())),
            ]),
          )
        ],
      )),
    );
  }
}
