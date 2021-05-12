/*
  Oliver Thurston Lynch
  May 11th 2020
  Bitriser
*/

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:bitriser/storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

_hmacSha256(String message, String secret) {
  var key = utf8.encode(secret);
  var msg = utf8.encode(message);
  var hmac = new Hmac(sha256, key);
  var signature = hmac.convert(msg).toString();
  return signature;
}

class Coinbase {
  String _apiKey;
  String _secret;
  String _myWallet;
  String _myPayment;
  String _base = 'https://api.coinbase.com';
  String _version = '2021-01-26';
  String _type = 'application/json';
  var response, url;
  String signature;

  Coinbase(String apiKey, String secret) {
    this._apiKey = apiKey;
    this._secret = secret;
  }

  _response2(request) async {
    try {
      var timestamp = await http
          .get(Uri.parse('https://api.coinbase.com/v2/time'))
          .then((res) => json.decode(res.body))
          .then((res) => res['data']['epoch']);
      String query = timestamp.toString() +
          request['method'] +
          request['requestPath'] +
          json.encode(request['body']);

      print(request['body']);

      signature = _hmacSha256(query, this._secret);
      url = _base + request['requestPath'];

      //for posts
      response = await http.post(
        Uri.parse(url),
        body: json.encode(request['body']),
        headers: {
          'CB-ACCESS-KEY': this._apiKey,
          'CB-ACCESS-SIGN': signature,
          'CB-ACCESS-TIMESTAMP': timestamp.toString(),
          'CB-VERSION': _version,
          'Content-Type': _type
        },
      );

      return response;
    } on Exception {
      return null;
    }
  }

  _response(request) async {
    try {
      var timestamp = await http
          .get(Uri.parse('https://api.coinbase.com/v2/time'))
          .then((res) => json.decode(res.body))
          .then((res) => res['data']['epoch']);
      String query = timestamp.toString() +
          request['method'] +
          request['requestPath'] +
          request['body'];

      signature = _hmacSha256(query, this._secret);
      url = _base + request['requestPath'];

      //for gets
      response = await http.get(
        Uri.parse(url),
        headers: {
          'CB-ACCESS-KEY': this._apiKey,
          'CB-ACCESS-SIGN': signature,
          'CB-ACCESS-TIMESTAMP': timestamp.toString(),
          'CB-VERSION': _version,
          'Content-Type': _type
        },
      );

      return response;
    } on Exception {
      return null;
    }
  }

  getBalance() async {
    var request = {'method': 'GET', 'requestPath': '/v2/accounts', 'body': ''};
    var response = await this._response(request);

    if (response != null && response.statusCode == 200) {
      var result = json.decode(response.body)['data'];
      var balance = [];
      for (var res in result) {
        if (double.parse(res['balance']['amount']) > 0) {
          balance.add(res['balance']);
        }
      }
      return balance;
    }
    return null;
  }

  getpayment() async {
    var request = {
      'method': 'GET',
      'requestPath': '/v2/payment-methods',
      'body': ''
    };
    var response = await this._response(request);

    if (response != null && response.statusCode == 200) {
      var result = json.decode(response.body)['data'];
      //print('\n\n $result');
      //print(result[0]['id']);
      _myWallet = result[0]['id'];
    }
    return null;
  }

  getwallet() async {
    var request = {'method': 'GET', 'requestPath': '/v2/accounts', 'body': ''};
    var response = await this._response(request);

    if (response != null && response.statusCode == 200) {
      var result = json.decode(response.body)['data'];
      //print(result[0]['id']);
      _myPayment = result[0]['id'];
    }
    return null;
  }

  buyCoin() async {
    await getwallet();
    await getpayment();

    var user = FirebaseAuth.instance.currentUser;
    var storage = UserStorage(uid: user.uid);

    String amount = await storage.getAmount();
    print(amount);

    var data = {
      "total": amount,
      "currency": "BTC",
      "payment_method": _myWallet,
      "quote": true
    };

    var request = {
      'method': 'POST',
      'requestPath': '/v2/accounts/$_myPayment/buys',
      'body': data
    };
    var response = await this._response2(request);
    print(response.statusCode);
    print(response.body);

    if (response != null && response.statusCode == 200) {
      var result = json.decode(response.body)['data'];
    }
    return null;
  }
}

purchaseCoin(exchange) async {
  final coinbase = new Coinbase(exchange['api_key'], exchange['secret']);
  //coinbase._myWallet = coinbase.getwallet(); //This gets wallet
  //coinbase._myPayment = coinbase.getpayment(); //This gets payment method
  await coinbase.buyCoin(); //mywallet, mypayment);
}

fetchCoinbase(exchange) async {
  final coinbase = new Coinbase(exchange['api_key'], exchange['secret']);

  var balance = await coinbase.getBalance();
  if (balance == null) {
    return null;
  }

  var wallet = {
    'currency': balance[0]['currency'],
    'amount': balance[0]['amount'],
    'value': 0
  };

  try {
    var amount = double.parse(wallet['amount']);

    double currencyPrice = 0;
    double result = 0;

    //get current value
    var response = await http
        .get(Uri.parse(
            'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=bitcoin'))
        .then((res) => json.decode(res.body));

    currencyPrice = double.parse(response[0]['current_price'].toString());

    result += currencyPrice * amount;
    wallet['value'] = result.toStringAsFixed(2);

    return wallet;
  } on Exception {
    return null;
  }
}
