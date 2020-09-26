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

  @override
  void initState() {
    initAuthListener();
    pages = [
      // TaskList
      TasksPage(widget.key),
      StatsPage()
    ];
    floatingButtons = [
      FloatingActionButton(
        child: Icon(Icons.add),
        // label: Text("NEW TASK"),
        backgroundColor: Colors.lightBlueAccent.shade200,
        onPressed: () {
          createTask(context);
        },
      ),
      null,
    ];

    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text((_selectedIndex == 0) ? "All Tasks" : "Your Task Stats"),
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
