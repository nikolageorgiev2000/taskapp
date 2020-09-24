import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';

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
  return SafeArea(child: Scaffold(body: GoogleSignInButton(onPressed: () async {
    await signInWithGoogle();
  })));
}

Future<void> logout() async {
  //signout user from FirebaseAuth
  await FirebaseAuth.instance.signOut();
  //revoke previous authentication so user isn't automatically signed in again
  GoogleSignIn().disconnect();
  userCredential = null;
}
