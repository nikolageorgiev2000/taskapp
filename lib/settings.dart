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
                  padding: EdgeInsets.symmetric(horizontal: 15),
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
                    SwitchListTile(
                        title: Text("Most recent completed tasks only"),
                        value: UserPrefs.onlyRecentCompletedTasks,
                        onChanged: (val) {
                          setSettings(() {
                            UserPrefs.onlyRecentCompletedTasks = val;
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
                    ListTile(
                      title: Center(
                          child: Text(
                        "Created my free logo at LogoMakr.com.",
                        style: TextStyle(fontSize: 14),
                      )),
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
  static bool onlyRecentCompletedTasks = true;
}
