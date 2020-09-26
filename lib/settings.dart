import 'package:flutter/material.dart';
import 'package:taskapp/BaseAuth.dart';

void showSettings(BuildContext context) {
  showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStats) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
              ),
              FlatButton(
                  onPressed: () async {
                    await logout();
                    Navigator.pop(context);
                  },
                  child: Text("LOGOUT")),
            ],
          );
        });
      });
}
