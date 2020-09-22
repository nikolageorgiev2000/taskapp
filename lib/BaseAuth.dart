import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

SafeArea loginPage() {
  return SafeArea(
      child: Scaffold(
    body: FlatButton.icon(
        onPressed: () async {
          await signInWithGoogle();
        },
        icon: Icon(Icons.login),
        label: Text("Sign In")),
  ));
}

void logout() {
  FirebaseAuth.instance.signOut();
}
