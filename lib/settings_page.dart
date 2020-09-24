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
        Align(
          child: FlatButton(
              onPressed: () async {
                await logout();
              },
              child: Text("LOGOUT")),
          alignment: Alignment.centerLeft,
        ),
      ],
    );
  }
}
