import 'package:flutter/material.dart';
import 'package:nutribuddies/screens/authenticate/login.dart';
import 'package:nutribuddies/screens/authenticate/sign_up.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool isSignIn = true;

  void toggleView() {
    setState(() => isSignIn = !isSignIn);
  }

  @override
  Widget build(BuildContext context) {
    if (isSignIn) {
      return Login(isLogin: toggleView);
    } else {
      return SignUp(isSignUp: toggleView);
    }
  }
}
