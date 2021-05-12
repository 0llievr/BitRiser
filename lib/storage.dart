/*
  Oliver Thurston Lynch
  May 11th 2020
  Bitriser
*/

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart';
import 'package:encrypt/encrypt.dart';

class UserStorage {
  FirebaseApp firebaseApp;
  final String uid;

  UserStorage({this.uid});

  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');

  DocumentReference sightingRef;

  var key = Key.fromLength(32);
  var iv = IV.fromLength(16);
  var encrypter;

//SETTERS
  Future<void> setUserData({
    String myName,
    String myEmail,
  }) async {
    return await userCollection
        .doc(uid)
        .set({
          'Name': myName,
          'Email': myEmail,
          'ApiKey': 'Key',
          'SecretKey': 'Secret',
          'amount': '0',
          'image':
              'https://firebasestorage.googleapis.com/v0/b/bitriser.appspot.com/o/nouser.jpg?alt=media&token=048cf3b4-fc96-4ed8-bfc2-524cb2862c11',
          'alarm': '8:00'
        })
        .then((value) => print("FIRESTORE: set user sucessfull"))
        .catchError((error) => print("Failed to set user: $error"));
  }

  Future<void> updateUserData({
    String myName,
    String myApiKey,
    int myAmount,
  }) async {
    return await userCollection
        .doc(uid)
        .update({
          'Name': myName,
          'ApiKey': myApiKey,
          'Amount': myAmount,
        })
        .then((value) => print("FIRESTORE: set user sucessfull"))
        .catchError((error) => print("Failed to set user: $error"));
  }

  Future<void> updateAPIKeys({
    String myApiKey,
    String mySecretKey,
  }) async {
    //encript api keys before sending them to firebase
    encrypter = Encrypter(AES(key));
    return await userCollection
        .doc(uid)
        .update({
          'ApiKey': myApiKey,
          'SecretKey': mySecretKey,
        })
        .then((value) => print("FIRESTORE: Update API keys sucessfull"))
        .catchError((error) => print("Failed to set keys: $error"));
  }

  Future<void> setAmount({String myAmount}) async {
    return await userCollection
        .doc(uid)
        .update({
          'amount': myAmount,
        })
        .then((value) => print("FIRESTORE: set amount sucessfull"))
        .catchError((error) => print("Failed to set amount: $error"));
  }

  Future<void> setAlarm({String myAlarm}) async {
    return await userCollection
        .doc(uid)
        .update({
          'alarm': myAlarm,
        })
        .then((value) => print("FIRESTORE: set alarm sucessfull"))
        .catchError((error) => print("Failed to set alarm: $error"));
  }

  Future<String> uploadImage(File image) async {
    sightingRef = FirebaseFirestore.instance.collection("users").doc(uid);

    firebase_storage.Reference storageReference = firebase_storage
        .FirebaseStorage.instance
        .ref('usrimages/${basename(image.path)}');

    firebase_storage.UploadTask uploadTask = storageReference.putFile(image);

    await uploadTask.whenComplete(() => print("File uploaded"));

    String returnURL;
    await storageReference.getDownloadURL().then((fileURL) {
      returnURL = fileURL;
    });
    return returnURL;
  }

  Future<void> setImage(String url) async {
    return await userCollection
        .doc(uid)
        .update({
          'image': url,
        })
        .then((value) => print("FIRESTORE: set image link sucessfull"))
        .catchError((error) => print("Failed to set alarm: $error"));
  }

//Getters

//Getters
  Future getuid() async {
    return uid;
  }

  Future getKey() async {
    var tmp = await userCollection.doc(uid).get();
    return tmp.data()['ApiKey'];
  }

  Future getSecret() async {
    var tmp = await userCollection.doc(uid).get();
    return tmp.data()['SecretKey'];
  }

  Future getAlarm() async {
    var tmp = await userCollection.doc(uid).get();
    return tmp.data()['alarm'];
  }

  Future getAmount() async {
    var tmp = await userCollection.doc(uid).get();
    return tmp.data()['amount'];
  }

  Future getimage() async {
    var tmp = await userCollection.doc(uid).get();
    return tmp.data()['image'];
  }
}
