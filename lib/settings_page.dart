import 'dart:core';
import 'package:flutter/material.dart';
import 'package:taskapp/BaseAuth.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text("HELLO"),
        Text("HELLO"),
        Text("HELLO"),
        Text("HELLO"),
        Text("HELLO"),
        Text("HELLO"),
        FlatButton(
            onPressed: () {
              logout();
            },
            child: Text("LOGOUT")),
      ],
    );
  }
}
