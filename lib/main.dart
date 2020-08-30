import 'package:flutter/material.dart';
import 'dart:math';
// Import the firebase_core plugin
import 'package:firebase_core/firebase_core.dart';

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

  List<Widget> pages = [
    TaskList(PageStorageKey("Task Page Key"), false),
    Text("Events"),
    Text("Stats"),
    Text("Settings")
  ];

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
      pages[0] =
          TaskList(PageStorageKey("Task Page Key"), (index == _selectedIndex));
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
      floatingActionButton: floatingButtons[_selectedIndex],
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.alarm_on), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.today), label: "Events"),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Stats"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Options"),
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

  TaskList(Key key, this._doubleTapped) : super(key: key);

  bool get doubleTapped => _doubleTapped;

  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  ScrollController scrollController = ScrollController();

  bool flatButtonPressed = false;

  void createTask() {}

  void editTask(index) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 1000,
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Modal BottomSheet'),
                RaisedButton(
                  child: const Text('Close BottomSheet'),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
        );
      },
      enableDrag: false,
    );
  }

  Widget createTaskCard(int index) {
    // return Stack(
    //   children: [
    //     InkWell(
    //         onLongPress: () {
    //           editTask(index);
    //         },
    //         child: Card(
    //           child: Padding(
    //             padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
    //             child: Row(
    //               mainAxisSize: MainAxisSize.min,
    //               children: [
    //                 // LEFT COLUMN
    //                 Expanded(
    //                     child: Container(
    //                         alignment: Alignment.topLeft,
    //                         decoration: BoxDecoration(
    //                             border: Border(
    //                                 right: BorderSide(color: Colors.grey))),
    //                         child: Column(
    //                           children: [
    //                             Row(children: [Text(index.toString())]),
    //                             Divider(
    //                               color: Colors.transparent,
    //                               height: 5,
    //                             ),
    //                             Row(children: [Text(index.toString())]),
    //                             Divider(
    //                               color: Colors.transparent,
    //                               height: 5,
    //                             ),
    //                             Row(children: [Text(index.toString())]),
    //                           ],
    //                           mainAxisSize: MainAxisSize.max,
    //                         ))),
    //               ],
    //             ),
    //           ),
    //         )),
    //     Padding(
    //       padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
    //       child: Row(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           // RIGHT COLUMN
    //           Align(
    //               alignment: Alignment.topRight,
    //               child: Column(
    //                 children: [
    //                   Row(
    //                     children: [
    //                       FlatButton.icon(
    //                         icon: Icon(Icons.play_arrow),
    //                         onPressed: () {
    //                           print("Track - Pressed");
    //                         },
    //                         label: Text("1:000005"),
    //                       )
    //                     ],
    //                   ),
    //                   Row(
    //                     children: [
    //                       FlatButton.icon(
    //                         icon: Icon(Icons.check),
    //                         label: Text("Done"),
    //                         padding: EdgeInsets.zero,
    //                         onPressed: () {
    //                           print("Done - Pressed");
    //                         },
    //                       )
    //                     ],
    //                   )
    //                 ],
    //               ))
    //         ],
    //       ),
    //     )
    //   ],
    // );

    return Card(
      child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          onLongPress: () {
            print(flatButtonPressed);
            if (!flatButtonPressed) {
              editTask(index);
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
                            Row(children: [Text(index.toString())]),
                            Divider(
                              color: Colors.transparent,
                              height: 5,
                            ),
                            Row(children: [Text(index.toString())]),
                            Divider(
                              color: Colors.transparent,
                              height: 5,
                            ),
                            Row(children: [Text(index.toString())]),
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
                                  icon: Icon(Icons.play_arrow),
                                  onPressed: () {
                                    print("Track - Pressed");
                                    flatButtonPressed = false;
                                  },
                                  label: Text("1:000005"),
                                )
                              ],
                            ),
                            Row(
                              children: [
                                FlatButton.icon(
                                  icon: Icon(Icons.check),
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
        reverse: false,
        controller: scrollController,
        /*Use itermCount (length of list) and itemExtent (height of an item)
        for improved speed switching between tabs (rebuilding list) */
        // itemCount: 100,
        // itemExtent: 150,
        itemBuilder: (context, index) {
          return createTaskCard(index);
        });
  }
}

class Task {
  final String task_uid;
  String name;
  String description;
  double epochDue;
  String location;
  bool done;
  String event_uid;
  Category task_category;
  double epochLastEdit;

  Task(this.task_uid);
}

enum Category { Default, Work, School, Hobby, Health, Social, Family, Daily }

/*
Task document format:
int task-ID
String name
String description
float timeDue epoch
String location
bool completed
int event-ID

enum? category
float timeLastEdited (use most recent time as truth for everything except )
*/

/*TODO: figure out how to: 
    animate list, 
    add task, 
    switch between viewing saved/editing task, 
    add task from event page, add task button
*/
