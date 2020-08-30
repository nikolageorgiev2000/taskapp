import 'package:flutter/material.dart';
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
    TaskList(PageStorageKey("Task Page Key")),
    Text("Events"),
    Text("Stats")
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: Icon(Icons.ac_unit)),
      //Use PageStorage to save the scroll offset using the ScrollController in TaskList
      body: PageStorage(bucket: _bucket, child: pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.alarm_on), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.today), label: "Events"),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Stats"),
        ],
        iconSize: 30,
        currentIndex: _selectedIndex,
        showUnselectedLabels: false,
        selectedItemColor: Colors.lightBlue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class TaskList extends StatefulWidget {
  TaskList(Key key) : super(key: key);

  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  ScrollController scrollController = ScrollController();

  Widget createTaskCard(int index) {
    return Card(
      child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          onLongPress: () {
            print('Card long-pressed.');
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // LEFT COLUMN
                Expanded(
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: Column(
                          children: [Text(index.toString())],
                          mainAxisSize: MainAxisSize.max,
                        ))),
                // RIGHT COLUMN
                Align(
                    alignment: Alignment.topRight,
                    child: Column(
                      children: [
                        Align(
                            alignment: Alignment.bottomRight,
                            child: Row(
                              children: [
                                IconButton(
                                    icon: Icon(Icons.play_arrow),
                                    onPressed: null),
                                Text("1:05")
                              ],
                            )),
                        Row(
                          children: [
                            IconButton(
                                icon: Icon(Icons.check), onPressed: null),
                            Text("Complete?")
                          ],
                        )
                      ],
                    ))
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
    return ListView.builder(
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
