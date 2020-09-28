import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:taskapp/settings.dart';

import 'stats_page.dart';
import 'BaseAuth.dart';
import 'task.dart';
import 'tasks_page.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math';
// Import the firebase_core and cloud_firestore plugin
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Set default `_initialized` and `_error` state to false
  bool _initialized = false;
  bool _error = false;

  // Define an async function to initialize FlutterFire
  Future<void> initFirebase() async {
    try {
      // Wait for Firebase to initialize and set `_initialized` state to true
      await Firebase.initializeApp();
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      // Set `_error` state to true if Firebase initialization fails
      setState(() {
        _error = true;
      });
    }
  }

  @override
  void initState() {
    initFirebase();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Show error message if initialization failed
    if (_error) {
      return MaterialApp(
          home: Dialog(
        child: Text("ERROR LOADING DATA!"),
      ));
    }

    // Show a loader until FlutterFire is initialized
    if (!_initialized) {
      return MaterialApp(
          home: Dialog(
        child: Text("LOADING DATA..."),
      ));
    }

    return MaterialApp(
      title: 'DoCenter Test',
      home: MenuController(),
      theme: ThemeData(primaryColor: Colors.white),
    );
  }
}

class MenuController extends StatefulWidget {
  @override
  _MenuControllerState createState() => _MenuControllerState();
}

class _MenuControllerState extends State<MenuController> {
  int _selectedIndex = 0;
  final _bucket = PageStorageBucket();
  List<Widget> pages;
  List<Widget> floatingButtons;
  StreamSubscription<User> _auth;
  bool _loggedIn = false;
  StatsPeriod statsPeriodSpecified;
  String taskCategorySpecified;

  void initAuthListener() {
    _auth = FirebaseAuth.instance.authStateChanges().listen((User user) {
      if (user == null) {
        print('User is currently signed out!');
        setState(() {
          _loggedIn = false;
        });
      } else {
        print('User is signed in!');
        setState(() {
          _loggedIn = true;
        });
        currentUser = user;
      }
    });
  }

  void refreshPages() {
    pages = [
      // TaskList
      TasksPage(widget.key, taskCategorySpecified),
      StatsPage(widget.key, statsPeriodSpecified)
    ];
  }

  @override
  void initState() {
    initAuthListener();
    floatingButtons = [
      FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.lightBlueAccent.shade200,
        onPressed: () {
          createTask(context);
        },
      ),
      null,
    ];

    statsPeriodSpecified = StatsPeriod.All;
    taskCategorySpecified = TaskCategoryExtension.extendedValues.last;
    refreshPages();

    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("---MAIN REBUILT");
    TextStyle appBarTitleStyle = TextStyle(
        color: Colors.black, fontWeight: FontWeight.w500, fontSize: 21);
    if (_loggedIn) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            (_selectedIndex == 0)
                ? DropdownButton(
                    icon: Icon(Icons.keyboard_arrow_down),
                    style: appBarTitleStyle,
                    // underline: Container(),
                    value: taskCategorySpecified,
                    isDense: true,
                    items: List.generate(
                        TaskCategoryExtension.extendedValues.length,
                        (i) => DropdownMenuItem<String>(
                              value: TaskCategoryExtension.extendedValues[i],
                              child:
                                  Text(TaskCategoryExtension.extendedValues[i]),
                            )),
                    onChanged: (String sp) {
                      setState(() {
                        taskCategorySpecified = sp;
                        refreshPages();
                      });
                    })
                : DropdownButton(
                    icon: Icon(Icons.keyboard_arrow_down),
                    style: appBarTitleStyle,
                    // underline: Container(),
                    value: statsPeriodSpecified,
                    isDense: true,
                    items: List.generate(
                        StatsPeriod.values.length,
                        (i) => DropdownMenuItem(
                              value: StatsPeriod.values[i],
                              child: Text(describeEnum(StatsPeriod.values[i])),
                            )),
                    onChanged: (StatsPeriod sp) {
                      setState(() {
                        statsPeriodSpecified = sp;
                        refreshPages();
                      });
                    }),
            Expanded(
                child: Text(
              (_selectedIndex == 0) ? " Tasks" : " Figures",
              style: appBarTitleStyle,
            ))
          ]),
          actions: [
            IconButton(
              icon: Icon(
                Icons.settings,
              ),
              onPressed: () {
                showSettings(context);
              },
              splashRadius: 25,
            ),
          ],
        ),
        body: SafeArea(
            //Use PageStorage to save the scroll offset using the ScrollController in TaskList
            child: PageStorage(
                //generate key from name of widget
                key: PageStorageKey(pages[_selectedIndex].toString()),
                bucket: _bucket,
                child: pages[_selectedIndex])),
        floatingActionButton: floatingButtons[_selectedIndex],
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.alarm_on), label: "Tasks"),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart), label: "Stats"),
          ],
          iconSize: 30,
          currentIndex: _selectedIndex,
          showUnselectedLabels: false,
          selectedItemColor: Colors.lightBlue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
        ),
      );
    } else {
      return loginPage();
    }
  }
}
