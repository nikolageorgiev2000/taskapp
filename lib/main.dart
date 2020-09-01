import 'dart:developer';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math';
// Import the firebase_core and cloud_firestore plugin
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  List<Task> tasks;
  List<Widget> pages;
  CollectionReference data;

  @override
  void initState() {
    tasks = [
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
      Task("Test", "taskUID_TEST", DateTime.now().millisecondsSinceEpoch),
    ];
    pages = [
      // TaskList with refreshing ability
      RefreshIndicator(
          child: TaskList(PageStorageKey("Task Page Key"), false, tasks),
          onRefresh: () {
            return Future(refreshTasks);
          }),
      Text("Events"),
      Text("Stats"),
      Text("Settings")
    ];

    CollectionReference data = FirebaseFirestore.instance.collection('users');
    super.initState();
  }

  void refreshTasks() async {
    setState(() {
      tasks = [
        Task("Test", DateTime.now().millisecondsSinceEpoch.toString(),
            DateTime.now().millisecondsSinceEpoch)
      ];
    });
    _onItemTapped(0);
  }

  List<Widget> floatingButtons = [
    FloatingActionButton(
      child: Icon(Icons.add),
      // label: Text("NEW TASK"),
      backgroundColor: Colors.lightBlueAccent.shade200,
      onPressed: null,
    ),
    null,
    null,
    null
  ];

  void _onItemTapped(int index) {
    setState(() {
      //check if bottomNavMenu icon is tapped more than once
      //keep ability to refresh TaskList
      pages[0] = RefreshIndicator(
          child: TaskList(PageStorageKey("Task Page Key"),
              (index == _selectedIndex), tasks),
          onRefresh: () {
            return Future(refreshTasks);
          });
    });
    _selectedIndex = index;
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
      floatingActionButton: floatingButtons[_selectedIndex],
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
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

class TaskList extends StatefulWidget {
  final bool _doubleTapped;
  final List<Task> _tasks;

  TaskList(Key key, this._doubleTapped, this._tasks) : super(key: key);

  bool get doubleTapped => _doubleTapped;
  List<Task> get tasks => _tasks;

  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  ScrollController scrollController = ScrollController();

  Task getTask(index) {
    return this.widget._tasks[index];
  }

  //Create list of tasks
  @override
  Widget build(BuildContext context) {
    //scroll to top if TaskList icon in menu tapped while already on page
    if (this.widget.doubleTapped) {
      print(scrollController.position.pixels);
      scrollController.animateTo(scrollController.initialScrollOffset,
          duration: Duration(
              milliseconds: min(scrollController.position.pixels ~/ 2, 2000)),
          curve: Curves.easeOutCubic);
    }
    return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        reverse: false,
        controller: scrollController,
        /*Use itermCount (length of list) and itemExtent (height of an item)
        for improved speed switching between tabs (rebuilding list) */
        itemCount: this.widget._tasks.length,
        // itemExtent: 150,
        itemBuilder: (context, index) {
          return TaskCard(this.widget.key, getTask(index));
        });
  }
}

class TaskCard extends StatefulWidget {
  final Task task;
  TaskCard(Key key, this.task) : super(key: key);

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool flatButtonPressed = false;

  String formatDate(DateTime dateTime) {
    return "${dateTime.day.toString()}-${dateTime.month.toString()}-${dateTime.year.toString()}    ${dateTime.millisecondsSinceEpoch}";
  }

  int timeToMilliseconds(TimeOfDay timeOfDay) {
    return 1000 * (3600 * timeOfDay.hour + 60 * timeOfDay.minute);
  }

  void editTask() async {
    // wait for editing to be finished on modal sheet
    await showModalBottomSheet<void>(
        isScrollControlled: true,
        context: context,
        enableDrag: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            // initialize initial date and time task is due
            DateTime initDate =
                DateTime.fromMillisecondsSinceEpoch(this.widget.task.epochDue);
            TimeOfDay initTime = TimeOfDay.fromDateTime(initDate);

            // functions to edit date and time with nice UI
            Future<void> _showDatePicker() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: initDate,
                firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                lastDate: DateTime(2100),
              );
              if (picked != null && picked != initDate) {
                setModalState(() {
                  widget.task.epochDue = picked.millisecondsSinceEpoch +
                      timeToMilliseconds(initTime);
                });
              }
            }

            Future<void> _showTimePicker() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: initTime,
              );
              if (picked != null && picked != initTime) {
                setModalState(() {
                  print(widget.task.epochDue);
                  widget.task.epochDue = initDate.millisecondsSinceEpoch -
                      timeToMilliseconds(initTime) +
                      timeToMilliseconds(picked);
                  print(widget.task.epochDue);
                });
              }
            }

            // Editable UI
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                //Save/Cancel Task

                //Task Name
                Text("Edit Task"),

                //Description
                TextField(
                  maxLength: 280,
                  minLines: 1,
                  maxLines: 10,
                  scrollPadding: EdgeInsets.all(2),
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(1), gapPadding: 1),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(1), gapPadding: 1),
                    labelText: 'Task Description',
                    counterText: null,
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (inputString) {
                    print("Submitted Text description: " + inputString);
                  },
                ),

                //Date Due
                FlatButton(
                    onPressed: () {
                      _showDatePicker();
                    },
                    child: Text(formatDate(DateTime.fromMillisecondsSinceEpoch(
                        widget.task.epochDue)))),
                //Time Due
                FlatButton(
                    onPressed: () {
                      _showTimePicker();
                    },
                    child: Text(initTime.toString())),

                //Location

                //Category

                //Padding to move modal sheet up with keyboard
                AnimatedPadding(
                  padding: MediaQuery.of(context).viewInsets,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.decelerate,
                  child: new Container(
                    alignment: Alignment.bottomCenter,
                    child: Container(),
                  ),
                ),
              ],
            );
          });
        });

    // Done editing task, now rebuild TaskCard to show changes on TaskList
    setState(() {});
  }

  var cardBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(15));
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: cardBorder,
      child: InkWell(
          customBorder: cardBorder,
          splashColor: Colors.blue.withAlpha(30),
          onLongPress: () {
            print(flatButtonPressed);
            if (!flatButtonPressed) {
              editTask();
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // LEFT COLUMN
                Expanded(
                    child: Container(
                        alignment: Alignment.topLeft,
                        decoration: BoxDecoration(
                            border:
                                Border(right: BorderSide(color: Colors.grey))),
                        child: Column(
                          children: [
                            Row(children: [Text("name: " + widget.task.name)]),
                            Divider(
                              color: Colors.transparent,
                              height: 5,
                            ),
                            Row(children: [
                              Text("epochDue: " +
                                  widget.task.epochDue.toString())
                            ]),
                            Divider(
                              color: Colors.transparent,
                              height: 5,
                            ),
                            Row(children: [
                              Text("uid: " + widget.task.taskUID)
                            ]),
                          ],
                          mainAxisSize: MainAxisSize.max,
                        ))),
                VerticalDivider(color: Colors.grey),
                // RIGHT COLUMN
                Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                FlatButton.icon(
                                  icon: Icon(Icons.play_arrow,
                                      color: Colors.blueGrey),
                                  onPressed: () {
                                    print("Track - Pressed");
                                    flatButtonPressed = false;
                                  },
                                  label: Text("1:25"),
                                )
                              ],
                            ),
                            Row(
                              children: [
                                FlatButton.icon(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  label: Text("Done"),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    print("Done - Pressed");
                                    flatButtonPressed = false;
                                  },
                                )
                              ],
                            )
                          ],
                        ),
                        // Detect when column is pressed and released to avoid unwanted interaction with inksplash
                        onTapDown: (details) {
                          flatButtonPressed = true;
                          print("DOWN");
                        },
                        onTapUp: (details) {
                          flatButtonPressed = false;
                        },
                        onTapCancel: () {
                          flatButtonPressed = false;
                        },
                        onLongPressStart: (details) {
                          flatButtonPressed = true;
                          print("START");
                        },
                        onLongPressEnd: (details) {
                          flatButtonPressed = false;
                          print("END");
                        }))
              ],
            ),
          )),
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    );
  }
}

class Task {
  // required parameters
  String name;
  final String taskUID;
  int epochDue;

  // optional parameters
  String description;
  String location;
  Category taskCategory;
  int epochLastEdit;
  int epochCompleted;
  String eventUID;

  Task(this.name, this.taskUID, this.epochDue,
      {this.epochLastEdit = -1,
      this.epochCompleted = -1,
      this.description = "",
      this.location = "",
      this.taskCategory = Category.None,
      String eventUID = ""});
}

enum Category { None, Work, School, Hobby, Health, Social, Family, Chores }

/*TODO: figure out how to: 
    add task, 
    switch between viewing saved/editing task, 
    add task from event page, add task button
*/
