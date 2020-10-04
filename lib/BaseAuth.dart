import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:taskapp/task.dart';

User currentUser;
UserCredential userCredential;

Future<UserCredential> signInWithGoogle() async {
  // Trigger the authentication flow
  final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

  // Obtain the auth details from the request
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  // Create a new credential
  final GoogleAuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  // Once signed in, return the UserCredential
  return await FirebaseAuth.instance.signInWithCredential(credential);
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isOnline;
  StreamSubscription<bool> onlineListener;
  Timer onlineChecker;

  @override
  void initState() {
    isOnline = true;
    onlineChecker = Timer.periodic(Duration(seconds: 3), (timer) {
      if (onlineListener != null) {
        onlineListener.cancel();
      }
      onlineListener = online().asStream().listen((event) {
        setState(() {
          isOnline = event;
        });
      });
    });
    super.initState();
  }

  @override
  void deactivate() {
    if (onlineListener != null) {
      onlineListener.cancel();
    }
    if (onlineChecker != null) {
      onlineChecker.cancel();
    }

    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            body: Center(
                child: Column(children: [
      Padding(padding: EdgeInsets.symmetric(vertical: 100)),
      Text(
        "Welcome!",
        style: TextStyle(
          fontSize: 32,
        ),
      ),
      Padding(padding: EdgeInsets.symmetric(vertical: 30)),
      GoogleSignInButton(onPressed: () async {
        await signInWithGoogle();
      }),
      Padding(padding: EdgeInsets.symmetric(vertical: 30)),
      (!isOnline) ? Text("Need to be online to authenticate.") : Text(" "),
    ]))));
  }
}

Future<void> logout() async {
  //signout user from FirebaseAuth
  await FirebaseAuth.instance.signOut();
  //revoke previous authentication so user isn't automatically signed in again
  GoogleSignIn().disconnect();
  currentUser = null;
  userCredential = null;
}
