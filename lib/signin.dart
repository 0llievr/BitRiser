import 'package:flutter/material.dart';
import 'package:bitriser/authentication.dart';

class Signin extends StatefulWidget {
  @override
  _SigninState createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("signin"),
      ),
      body: LoginForm(),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  var _emailController = TextEditingController();
  var _passwordController = TextEditingController();
  var _nameController = TextEditingController();

  final AuthenticationProvider _auth = AuthenticationProvider();

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: 'Enter your Name (register only)'),
                    controller: _nameController,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Enter your Email'),
                    controller: _emailController,
                  ),
                  TextFormField(
                    decoration:
                        InputDecoration(labelText: 'Enter your Password'),
                    controller: _passwordController,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    child: Text("Login"),
                    onPressed: () async {
                      dynamic result = await _auth.signIn(
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                      // if result is good
                      if (result != null) Navigator.pop(context);
                      print(result);
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    child: Text("register"),
                    onPressed: () async {
                      dynamic result = await _auth.signUp(
                        name: _nameController.text,
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                      print(result);
                      if (result != null) Navigator.pop(context);
                      print(result);
                    },
                  ),
                ),
              ],
            ),
          ],
        ));
  }
}
