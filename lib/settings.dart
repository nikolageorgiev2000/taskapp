import 'package:flutter/material.dart';
import 'package:taskapp/BaseAuth.dart';

void showSettings(BuildContext context) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setSettings) {
          return Wrap(
              // height: MediaQuery.of(context).size.height * 0.3,
              children: [
                ListView(
                  shrinkWrap: true,
                  // mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    //top padding of settings list
                    Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                    SwitchListTile(
                        title: Text("Animate Charts"),
                        value: UserPrefs.animateCharts,
                        onChanged: (val) {
                          setSettings(() {
                            UserPrefs.animateCharts = val;
                          });
                        }),
                    ListTile(
                      title: GestureDetector(
                        child: Text("Sign Out"),
                        onTap: () async {
                          await logout();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    //bottom padding of settings list
                    Padding(padding: EdgeInsets.symmetric(vertical: 10)),
                  ],
                ),
              ]);
        });
      });
}

class UserPrefs {
  static bool animateCharts = true;
}
