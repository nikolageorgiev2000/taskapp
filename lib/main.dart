import 'dart:developer';
import 'dart:io';

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
  void initializeFlutterFire() async {
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
    initializeFlutterFire();
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

  @override
  void initState() {
    pages = [
      // TaskList
      TasksPage(),
      Text("Events"),
      Text("Stats"),
      Text("Settings")
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
    return Scaffold(
      // appBar: AppBar(
      //     centerTitle: true,
      //     title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      //       Align(alignment: Alignment.center, child: Text("hi")),
      //       Align(alignment: Alignment.centerRight, child: Icon(Icons.settings))
      //     ])),
      body: SafeArea(
          //Use PageStorage to save the scroll offset using the ScrollController in TaskList
          child: PageStorage(bucket: _bucket, child: pages[_selectedIndex])),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.alarm_on), title: Text("Tasks")),
          BottomNavigationBarItem(
              icon: Icon(Icons.today), title: Text("Events")),
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart), title: Text("Stats")),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), title: Text("Options")),
        ],
        iconSize: 30,
        currentIndex: _selectedIndex,
        showUnselectedLabels: false,
        selectedItemColor: Colors.lightBlue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
