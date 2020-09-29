import 'dart:async';
import 'dart:core';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:crypto/crypto.dart';
// Import the firebase_core and cloud_firestore plugin
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  TaskCard(Key key, this.task) : super(key: key);

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _flatButtonPressed = false;
  Timer _taskTimer;
  int _trackedTime;

  // when user presses start arrow and begins timer on task card
  void startTask() async {
    widget.task.epochStart = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      // reset tracking state (artefacts from last tracked time otherwise!)
      _trackedTime = 0;
      _taskTimer = null;
    });
    // save and rebuild widget
    await saveTask(widget.task);
  }

  // when user presses pause button and pauses timer on task card
  void endTask() async {
    widget.task.workPeriods.add({
      'start': widget.task.epochStart,
      'end': DateTime.now().millisecondsSinceEpoch
    });
    widget.task.epochStart = -1;

    _trackedTime = 0;
    _taskTimer.cancel();
    print("Tasktimer of ${widget.task.name} is active? ${_taskTimer.isActive}");
    _taskTimer = null;

    //widget will rebuild after this
    await saveTask(widget.task);
  }

  // set amount of time passed since timer started on task card
  void setTrackedTime() {
    print("Setting time");
    this.setState(() {
      _trackedTime =
          (DateTime.now().millisecondsSinceEpoch - widget.task.epochStart) ~/
              1000;
    });

    if (widget.task.epochStart < 0) {
      endTask();
    }
  }

  // periodically set tracked time to update timer on task card
  void updateRunningTimer() {
    if (widget.task.epochStart >= 0) {
      if (_taskTimer == null) {
        _taskTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          setTrackedTime();
        });
      }
    }
  }

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    // when widget updated start updating timer periodically (it is stopped through deactivation)
    updateRunningTimer();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    // when widget first built start updating timer periodically
    updateRunningTimer();
    super.initState();
  }

  @override
  void deactivate() {
    print("DEACTIVATING");
    if (_taskTimer != null) {
      // if timer running, stop it
      _taskTimer.cancel();
      _taskTimer = null;
    }
    super.deactivate();
  }

  var cardBorder = RoundedRectangleBorder(
      side: BorderSide(color: Colors.black),
      borderRadius: BorderRadius.circular(10));
  @override
  Widget build(BuildContext context) {
    print("BUILDING TASKCARD: ${widget.task.name}");

    // inside card padding
    EdgeInsets cardPadding = EdgeInsets.symmetric(vertical: 0, horizontal: 20);
    // outside card padding
    EdgeInsets cardMargin = EdgeInsets.symmetric(horizontal: 15, vertical: 4);
    // card shadow strength
    double cardElevation = 3;

    // Different card depending on whether task is completed or not
    if (widget.task.epochCompleted < 0) {
      //TASK IN PROGRESS
      return Card(
        color: (widget.task.epochDue < DateTime.now().millisecondsSinceEpoch)
            ? Color.fromARGB(255, 255, 153, 148)
            : Colors.white,
        shape: cardBorder,
        child: InkWell(
            customBorder: cardBorder,
            splashColor: Colors.blue.withAlpha(30),
            onLongPress: () async {
              if (!_flatButtonPressed) {
                //delete when Firestore functions implemented
                widget.task.editTask(context);
              }
            },
            child: Padding(
              padding: cardPadding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LEFT COLUMN
                  Expanded(
                      child: Container(
                          alignment: Alignment.topLeft,
                          decoration: BoxDecoration(
                              border: Border(
                                  right: BorderSide(color: Colors.grey))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Text((widget.task.name != "")
                                    ? widget.task.name
                                    : "No Name")
                              ]),
                              Divider(
                                color: Colors.transparent,
                                height: 5,
                              ),
                              Row(children: [
                                Text((widget.task.epochDue == -1)
                                    ? "No due date"
                                    : "Due ${formatTimeOfDay(context, TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(widget.task.epochDue)))} on ${formatDateTime(DateTime.fromMillisecondsSinceEpoch(widget.task.epochDue))}")
                              ]),
                              Divider(
                                color: Colors.transparent,
                                height: 5,
                              ),
                              Row(children: [
                                Text((widget.task.location != "")
                                    ? "At ${widget.task.location}"
                                    : "")
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (widget.task.epochStart < 0)
                                    FlatButton.icon(
                                      icon: Icon(Icons.play_arrow,
                                          color: Colors.blueGrey),
                                      onPressed: () async {
                                        print("Time Started");
                                        startTask();
                                        _flatButtonPressed = false;
                                      },
                                      label: Text(
                                          "${formatTrackedTime(calcTimeSpent(widget.task.workPeriods))}"),
                                    ),
                                  if (widget.task.epochStart >= 0)
                                    FlatButton.icon(
                                      icon: Icon(Icons.pause,
                                          color: Colors.blueGrey),
                                      onPressed: () {
                                        print("Timer Ended");
                                        endTask();
                                        _flatButtonPressed = false;
                                      },
                                      label: Text((_trackedTime == null ||
                                              _trackedTime <= 0)
                                          ? "Loading"
                                          : formatTrackedTime(_trackedTime)),
                                    ),
                                ],
                              ),
                              Row(
                                children: [
                                  FlatButton.icon(
                                    icon: Icon(Icons.radio_button_unchecked,
                                        color: Colors.green),
                                    label: Text("In Progress"),
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      await showDialog(
                                          context: context,
                                          child: AlertDialog(
                                            content:
                                                Text("Mark task as completed?"),
                                            actions: [
                                              FlatButton(
                                                  child: Text("Confirm"),
                                                  onPressed: () async {
                                                    widget.task
                                                        .epochCompleted = DateTime
                                                            .now()
                                                        .millisecondsSinceEpoch;
                                                    if (widget
                                                            .task.epochStart >=
                                                        0) {
                                                      endTask();
                                                    }
                                                    await saveTask(widget.task);
                                                    Navigator.of(context).pop();
                                                  }),
                                              FlatButton(
                                                  child: Text("Cancel"),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  })
                                            ],
                                          ));
                                      _flatButtonPressed = false;
                                    },
                                  )
                                ],
                              )
                            ],
                          ),
                          // Detect when column is pressed and released to avoid unwanted interaction with inksplash
                          onTapDown: (details) {
                            _flatButtonPressed = true;
                            print("DOWN");
                          },
                          onTapUp: (details) {
                            _flatButtonPressed = false;
                          },
                          onTapCancel: () {
                            _flatButtonPressed = false;
                          },
                          onLongPressStart: (details) {
                            _flatButtonPressed = true;
                            print("START");
                          },
                          onLongPressEnd: (details) {
                            _flatButtonPressed = false;
                            print("END");
                          }))
                ],
              ),
            )),
        elevation: cardElevation,
        margin: cardMargin,
      );
    } else {
      //TASK COMPLETED
      return Card(
        shape: cardBorder,
        color: Color.fromARGB(255, 160, 231, 160),
        child: InkWell(
            customBorder: cardBorder,
            splashColor: Colors.blue.withAlpha(30),
            onLongPress: () async {
              if (!_flatButtonPressed) {
                //delete when Firestore functions implemented
                widget.task.editTask(context);
              }
            },
            child: Padding(
              padding: cardPadding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LEFT COLUMN
                  Expanded(
                      child: Container(
                          alignment: Alignment.topLeft,
                          decoration: BoxDecoration(
                              border: Border(
                                  right: BorderSide(color: Colors.grey))),
                          child: Column(
                            children: [
                              Row(children: [
                                Text((widget.task.name != "")
                                    ? widget.task.name
                                    : "No Name")
                              ]),
                              Divider(
                                color: Colors.transparent,
                                height: 5,
                              ),
                              Row(children: [
                                Text((widget.task.epochDue == -1)
                                    ? "No due date"
                                    : "Due ${formatTimeOfDay(context, TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(widget.task.epochDue)))} on ${formatDateTime(DateTime.fromMillisecondsSinceEpoch(widget.task.epochDue))}")
                              ]),
                              Divider(
                                color: Colors.transparent,
                                height: 5,
                              ),
                              Row(children: [
                                Text((widget.task.location != "")
                                    ? "At ${widget.task.location}"
                                    : "")
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  FlatButton.icon(
                                    onPressed: () {
                                      print("Track - Pressed");
                                      _flatButtonPressed = false;
                                    },
                                    icon: Icon(Icons.timer,
                                        color: Colors.blueGrey),
                                    label: Text(
                                        "${formatTrackedTime(calcTimeSpent(widget.task.workPeriods))}"),
                                  )
                                ],
                              ),
                              Row(
                                children: [
                                  FlatButton.icon(
                                    icon: Icon(Icons.check_circle_outline,
                                        color: Colors.green),
                                    label: Text("Completed"),
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      await showDialog(
                                          context: context,
                                          child: AlertDialog(
                                            content: Text(
                                                "Mark task as incomplete?"),
                                            actions: [
                                              FlatButton(
                                                  child: Text("Confirm"),
                                                  onPressed: () async {
                                                    widget.task.epochCompleted =
                                                        -1;
                                                    await saveTask(widget.task);
                                                    Navigator.of(context).pop();
                                                  }),
                                              FlatButton(
                                                  child: Text("Cancel"),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  })
                                            ],
                                          ));
                                      _flatButtonPressed = false;
                                    },
                                  )
                                ],
                              )
                            ],
                          ),
                          // Detect when column is pressed and released to avoid unwanted interaction with inksplash
                          onTapDown: (details) {
                            _flatButtonPressed = true;
                          },
                          onTapUp: (details) {
                            _flatButtonPressed = false;
                          },
                          onTapCancel: () {
                            _flatButtonPressed = false;
                          },
                          onLongPressStart: (details) {
                            _flatButtonPressed = true;
                          },
                          onLongPressEnd: (details) {
                            _flatButtonPressed = false;
                          }))
                ],
              ),
            )),
        elevation: cardElevation,
        margin: cardMargin,
      );
    }
  }
}

String formatDateTime(DateTime dateTime) {
  return DateFormat.yMMMd().format(dateTime);
  // return "${dateTime.day.toString()}-${dateTime.month.toString()}-${dateTime.year.toString()}";
}

String formatTimeOfDay(BuildContext context, TimeOfDay time) {
  return time.format(context);
}

// converts seconds to hh:mm:ss format
String formatTrackedTime(int sec) {
  return "${(sec ~/ 3600).toString().padLeft(2, '0')}:${((sec % 3600) ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}";
}

//calculate time in SECONDS spent working on a task
int calcTimeSpent(List<Map<String, int>> tP) {
  tP.sort((x, y) => (x['start'] < y['start'] ||
          (x['start'] == y['start'] && x['end'] < y['end'])
      ? -1
      : 1));
  tP = tP.where((x) => (x['start'] > 0 && x['end'] > x['start'])).toList();

  if (tP.isEmpty) {
    return 0;
  }

  int totalTime = 0;
  int s = tP[0]['start'];
  int e = tP[0]['end'];
  for (var i = 1; i < tP.length; i++) {
    if (tP[i]['start'] > e) {
      totalTime += e - s;
      s = tP[i]['start'];
      e = tP[i]['end'];
    } else {
      e = tP[i]['end'];
    }
  }
  totalTime += e - s;
  return totalTime ~/ 1000;
}

int timeToMilliseconds(TimeOfDay timeOfDay) {
  return 1000 * (3600 * timeOfDay.hour + 60 * timeOfDay.minute);
}

StreamSubscription<QuerySnapshot> taskListListener(Function toDo) {
  CollectionReference tasks = getTaskCollection();
  return tasks.snapshots().listen((event) {
    toDo();
  });
}

Future<bool> taskExists(String taskUID) async {
  CollectionReference tasks = getTaskCollection();
  QuerySnapshot taskSnapshot =
      await tasks.where("taskUID", isEqualTo: taskUID).get();
  return taskSnapshot.docs.isNotEmpty;
}

CollectionReference getTaskCollection() {
  CollectionReference tasks = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser.uid.toString())
      .collection("tasks");
  return tasks;
}

// CollectionReference getTaskCollectionTest() {
//   CollectionReference tasks = FirebaseFirestore.instance
//       .collection('users')
//       .doc("test-user")
//       .collection("tasks");
//   return tasks;
// }

Future<List<Task>> getOrderedTasks() async {
  print("RETREIVING TASKS FROM FIRESTORE");
  CollectionReference taskColl = getTaskCollection();
  QuerySnapshot taskSnapshot = await taskColl.orderBy('epochDue').get();
  List<Task> tasks = taskSnapshot.docs.map((e) => taskFromDoc(e)).toList();
  tasks.sort((x, y) => taskOrder(x, y));
  return tasks;
}

int taskOrder(Task x, Task y) {
  bool taskFinished(Task t) {
    return t.epochCompleted >= 0;
  }

  if (!taskFinished(x)) {
    if (x.epochCompleted < y.epochCompleted) {
      // x unfinished, y finished
      return -1;
    } else {
      // both unfinished, show task due sooner first
      return (x.epochDue < y.epochDue) ? -1 : 1;
    }
  } else {
    if (!taskFinished(y)) {
      // x finished, y unfinished
      return 1;
    } else {
      // both finished, show task finished recently first
      return (x.epochCompleted < y.epochCompleted) ? 1 : -1;
    }
  }
}

Task taskFromDoc(QueryDocumentSnapshot d) {
  Map<String, dynamic> docDict = d.data();
  Task newTask = Task(docDict['name'], docDict['taskUID'], docDict['epochDue']);
  // Expand with check for the rest of the optional fields...

  if (docDict['description'] != null) {
    newTask.description = docDict['description'];
  } else {
    newTask.description = "";
  }
  if (docDict['location'] != null) {
    newTask.location = docDict['location'];
  } else {
    newTask.location = "";
  }
  if (docDict['taskCategory'] != null) {
    newTask.taskCategory = stringToTaskCategory(docDict['taskCategory']);
  } else {
    newTask.taskCategory = TaskCategory.Other;
  }
  if (docDict['epochCompleted'] != null) {
    newTask.epochCompleted = docDict['epochCompleted'];
  } else {
    newTask.epochCompleted = -1;
  }
  if (docDict['epochLastEdit'] != null) {
    newTask.epochLastEdit = docDict['epochLastEdit'];
  } else {
    newTask.epochLastEdit = -1;
  }
  if (docDict['eventUID'] != null) {
    newTask.eventUID = docDict['eventUID'];
  } else {
    newTask.eventUID = "";
  }
  if (docDict['epochStart'] != null) {
    newTask.epochStart = docDict['epochStart'];
  } else {
    newTask.epochStart = -1;
  }
  if (docDict['workPeriods'] != null) {
    // need to cast elements to Map<String,int> with map, since casting the list
    // does not cast the elements correctly (elements to Map, but not right one)
    newTask.workPeriods = List.from(docDict['workPeriods'])
        .map((e) => Map<String, int>.from(e))
        .toList();
  } else {
    newTask.workPeriods = [];
  }

  // print("ID:${d.id}");
  return newTask;
}

void createTask(context) async {
  // create blank task and edit it
  Task newTask = Task.blankTask();
  await newTask.editTask(context);
}

Future<void> saveTask(Task task, {bool hasErrors}) async {
  //save task in Firestore (check if it already exists and update it, otherwise create new document)
  CollectionReference tasks = getTaskCollection();

  if (await online()) {
    //update fields
    await tasks
        .doc(task.taskUID)
        .set(task.toMapNoArrays(), SetOptions(merge: true));
    //array union of work-time tracked
    await tasks
        .doc(task.taskUID)
        .update({'workPeriods': FieldValue.arrayUnion(task.workPeriods)});
  } else {
    tasks.doc(task.taskUID).set(task.toMapNoArrays(), SetOptions(merge: true));
    //array union of work-time tracked
    tasks
        .doc(task.taskUID)
        .update({'workPeriods': FieldValue.arrayUnion(task.workPeriods)});
  }
  print("Task saved");
}

Future<void> deleteTask(Task task) async {
  //delete task from Firestore
  CollectionReference tasks = getTaskCollection();

  await tasks.doc(task.taskUID).delete();
}

Future<void> duplicateTask(Task task) async {
  Task newTask = task.duplicate();
  await saveTask(newTask);
}

Future<bool> online() async {
  var con = await (Connectivity().checkConnectivity());
  if (con != ConnectivityResult.none) {
    print("ONLINE!");
  } else {
    print("OFFLINE!");
  }
  return con != ConnectivityResult.none;
}

class Task {
  // required parameters
  String name;
  final String taskUID;
  int epochDue;

  // optional parameters
  String description;
  String location;
  TaskCategory taskCategory;
  int epochLastEdit;
  int epochCompleted;
  String eventUID;
  int epochStart;
  List<Map<String, int>> workPeriods = [];

  Task(this.name, this.taskUID, this.epochDue,
      {this.epochLastEdit = -1,
      this.epochCompleted = -1,
      this.description = "",
      this.location = "",
      this.taskCategory = TaskCategory.Other,
      this.eventUID = "",
      this.epochStart = -1,
      workPeriods});

  Task clone() {
    return Task(name, taskUID, epochDue,
        epochLastEdit: epochLastEdit,
        epochCompleted: epochCompleted,
        description: description,
        location: location,
        taskCategory: taskCategory,
        eventUID: eventUID,
        epochStart: epochStart,
        workPeriods: workPeriods);
  }

  // Duplicates a task but updates its TaskUID, creating a perfect copy, but different task
  Task duplicate() {
    return Task(name, createTaskUID(), epochDue,
        epochLastEdit: epochLastEdit,
        epochCompleted: epochCompleted,
        description: description,
        location: location,
        taskCategory: taskCategory,
        eventUID: eventUID,
        epochStart: -1,
        workPeriods: []);
  }

  static Task blankTask() {
    return Task(
        "",
        createTaskUID(),
        DateTime.now().millisecondsSinceEpoch +
            1000 * 60 * TimeOfDay.minutesPerHour * TimeOfDay.hoursPerDay);
  }

  //A Tasks's uniqueness comes from it's UID
  //Created with timestamp of creation and nonce
  static String createTaskUID() {
    int timeStamp = DateTime.now().millisecondsSinceEpoch;
    int nonce = Random.secure().nextInt(pow(2, 32));
    var uid = sha256.convert([timeStamp, nonce]).toString();
    return uid;
  }

  bool changedThroughEdit(Task other) {
    return !(this == other);
  }

  Map<String, dynamic> toMapNoArrays() {
    return {
      "name": name,
      "taskUID": taskUID,
      "epochDue": epochDue,
      "epochLastEdit": epochLastEdit,
      "epochCompleted": epochCompleted,
      "description": description,
      "location": location,
      "taskCategory": describeEnum(taskCategory),
      "eventUID": eventUID,
      "epochStart": epochStart,
    };
  }

  Future<void> editTask(BuildContext context) async {
    // determines if dialog pops up to confirm/discard/cancel changes when user taps away from modalsheet
    bool editting = true;
    // checks if the current changes have been saved with save button
    bool saved = false;

    //create deep copy of task being edited to show changes on modal sheet
    Task newTask = this.clone();

    TextEditingController createdTextEditController(String text) =>
        TextEditingController.fromValue(TextEditingValue(
          text: text,
          // Might have to set selection to end of text if it automatically goes to start (potential bug fix)
          // selection:
          //     TextSelection.fromPosition(TextPosition(offset: text.length))
        ));

    // instantiate controllers outside of editor build otherwise selection bugs happen as mentioned above
    TextEditingController taskNameController =
        createdTextEditController(newTask.name);
    TextEditingController taskDescriptionController =
        createdTextEditController(newTask.description);
    TextEditingController taskLocationController =
        createdTextEditController(newTask.location);

    int maxNameLength = 30;
    int maxDescriptionLength = 280;
    int maxLocationLength = 30;

    // cannot save task edit if there is a mistake in it
    bool editError = false;

    TextStyle editTextStyle = TextStyle(
        fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black);

    while (editting) {
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
                  DateTime.fromMillisecondsSinceEpoch(newTask.epochDue);
              print("Editting: TaskUID ${newTask.taskUID}");
              TimeOfDay initTime = TimeOfDay.fromDateTime(initDate);
              TaskCategory initTaskCategory = newTask.taskCategory;

              InputBorder textFieldBorder = OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), gapPadding: 1);

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
                    newTask.epochDue = picked.millisecondsSinceEpoch +
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
                    newTask.epochDue = initDate.millisecondsSinceEpoch -
                        timeToMilliseconds(initTime) +
                        timeToMilliseconds(picked);
                  });
                }
              }

              // Editable UI
              return Padding(
                  padding: EdgeInsets.all(7.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Buttons to Save/Cancel Task
                      Center(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // replace save button with "fix issues" warning if there is an error with task info (e.g. name too long)
                          (editError)
                              ? new Container(
                                  margin: const EdgeInsets.all(15),
                                  padding: const EdgeInsets.all(5),
                                  decoration: ShapeDecoration(
                                      shape: RoundedRectangleBorder(
                                          side: BorderSide(color: Colors.red),
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10)))),
                                  child: Text("Fix Issues"),
                                )
                              : IconButton(
                                  icon: Icon(Icons.save),
                                  onPressed: () async {
                                    // only save if there is no editError
                                    if (!editError) {
                                      await saveTask(newTask);
                                      saved = true;
                                    }
                                  }),
                          Row(children: [
                            IconButton(
                              icon: Icon(Icons.add_to_photos),
                              onPressed: () async {
                                await showDialog(
                                    context: context,
                                    child: AlertDialog(
                                      content: Text("Duplicate task?"),
                                      actions: [
                                        FlatButton(
                                            child: Text("Confirm"),
                                            onPressed: () async {
                                              await duplicateTask(this);
                                              Navigator.of(context).pop();
                                            }),
                                        FlatButton(
                                            child: Text("Cancel"),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            })
                                      ],
                                    ));
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                bool delete = false;
                                await showDialog(
                                    context: context,
                                    child: AlertDialog(
                                      content: Text("Delete task?"),
                                      actions: [
                                        FlatButton(
                                            child: Text("Confirm"),
                                            onPressed: () {
                                              delete = true;
                                              Navigator.of(context).pop();
                                            }),
                                        FlatButton(
                                            child: Text("Cancel"),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            })
                                      ],
                                    ));
                                // if confirmed deletion, end editing and pop out of modal sheet
                                if (delete) {
                                  await deleteTask(this);
                                  editting = false;
                                  Navigator.of(context).pop();
                                }
                              },
                            )
                          ]),
                        ],
                      )),

                      Padding(
                        padding: EdgeInsets.all(5),
                      ),

                      //Task Name
                      TextField(
                        controller: taskNameController,
                        maxLength: maxNameLength,
                        minLines: 1,
                        maxLines: 1,
                        style: editTextStyle,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          isDense: true,
                          // when task has no name, user cannot see the category drop down,
                          // but can accidentally interact with it (bug)
                          // temp fix : set suffix to null if no text, since dropdown is visible otherwise
                          suffix: (taskNameController.text.length == 0)
                              ? null
                              : DropdownButton<TaskCategory>(
                                  isDense: true,
                                  icon: Icon(Icons.keyboard_arrow_down),
                                  value: initTaskCategory,
                                  style: editTextStyle,
                                  items: List.generate(
                                      TaskCategory.values.length,
                                      (i) => DropdownMenuItem(
                                            value: TaskCategory.values[i],
                                            child: Text(describeEnum(
                                                TaskCategory.values[i])),
                                          )),
                                  onChanged: (val) {
                                    setModalState(() {
                                      newTask.taskCategory = val;
                                    });
                                    saved = false;
                                  }),
                          contentPadding: EdgeInsets.all(20),
                          errorBorder: textFieldBorder,
                          focusedBorder: textFieldBorder,
                          enabledBorder: textFieldBorder,
                          disabledBorder: textFieldBorder,
                          labelText: 'Task Name',
                          labelStyle: TextStyle(color: Colors.blueGrey),
                          counterText: null,
                        ),
                        textInputAction: TextInputAction.done,
                        onChanged: (inputString) {
                          newTask.name = inputString;
                          saved = false;
                          editError =
                              taskNameController.text.length > maxNameLength;
                        },
                      ), //TaskCategory selection

                      //Due DateTime
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Due:",
                              style: editTextStyle,
                            ),
                            //Date Due
                            FlatButton(
                                onPressed: () async {
                                  await _showDatePicker();
                                },
                                child: Text(
                                  formatDateTime(
                                      DateTime.fromMillisecondsSinceEpoch(
                                          newTask.epochDue)),
                                  style: editTextStyle,
                                )),
                            //Time Due
                            FlatButton(
                                onPressed: () async {
                                  await _showTimePicker();
                                },
                                child: Text(
                                  formatTimeOfDay(context, initTime),
                                  style: editTextStyle,
                                )),
                          ]),

                      Padding(
                        padding: EdgeInsets.all(10),
                      ),

                      //Description
                      TextField(
                        controller: taskDescriptionController,
                        maxLength: maxDescriptionLength,
                        minLines: 1,
                        maxLines: 10,
                        style: editTextStyle,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(20),
                          errorBorder: textFieldBorder,
                          focusedBorder: textFieldBorder,
                          enabledBorder: textFieldBorder,
                          disabledBorder: textFieldBorder,
                          labelText: 'Description',
                          labelStyle: TextStyle(color: Colors.blueGrey),
                        ),
                        textInputAction: TextInputAction.done,
                        onChanged: (inputString) {
                          newTask.description = inputString;
                          saved = false;
                          editError = taskDescriptionController.text.length >
                              maxDescriptionLength;
                        },
                      ),

                      Padding(
                        padding: EdgeInsets.all(5),
                      ),

                      //Location
                      TextField(
                        controller: taskLocationController,
                        maxLength: maxLocationLength,
                        minLines: 1,
                        maxLines: 1,
                        style: editTextStyle,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(20),
                          errorBorder: textFieldBorder,
                          focusedBorder: textFieldBorder,
                          enabledBorder: textFieldBorder,
                          disabledBorder: textFieldBorder,
                          labelText: 'Location',
                          labelStyle: TextStyle(color: Colors.blueGrey),
                        ),
                        textInputAction: TextInputAction.done,
                        onChanged: (inputString) {
                          newTask.location = inputString;
                          saved = false;
                          editError = taskLocationController.text.length >
                              maxLocationLength;
                        },
                      ),

                      Padding(
                        padding: EdgeInsets.all(5),
                      ),

                      //Padding to move modal sheet up with keyboard
                      AnimatedPadding(
                        padding: MediaQuery.of(context).viewInsets,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.decelerate,
                        child: new Container(
                          alignment: Alignment.bottomCenter,
                          child: Container(),
                        ),
                      ),
                    ],
                  ));
            });
          });

      // when user presses out of modal sheet, check they've saved
      if (!saved && editting && this.changedThroughEdit(newTask)) {
        await showDialog(
            context: context,
            child: AlertDialog(
              content: Text((editError)
                  ? "Please fix problems with task information entered."
                  : "Save changes?"),
              actions: [
                (!editError)
                    ? FlatButton(
                        child: Text("Confirm"),
                        onPressed: () async {
                          await saveTask(newTask);
                          editting = false;
                          Navigator.of(context).pop();
                        })
                    : null,
                FlatButton(
                    child: Text("Discard"),
                    onPressed: () {
                      editting = false;
                      Navigator.of(context).pop();
                    }),
                FlatButton(
                    child: Text((editError) ? "Fix" : "Cancel"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    })
              ],
            ));
      } else {
        editting = false;
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Task &&
      (other.name == name &&
          other.description == description &&
          other.epochDue == epochDue &&
          other.location == location &&
          other.taskCategory == taskCategory);

  @override
  int get hashCode => this.hashCode;
}

enum TaskCategory {
  Other,
  Work,
  School,
  Hobby,
  Health,
  Social,
  Family,
  Chill,
}

// Extend TaskCategory enum with new categories (e.g. All)
// 'All' NEEDS TO BE LAST (assumed in rest of code that it is appended to end)
class TaskCategoryExtension {
  static List<String> get extendedValues =>
      TaskCategory.values.map((e) => describeEnum(e)).toList() + ["All"];
}

TaskCategory stringToTaskCategory(String str) {
  return TaskCategory.values
      .firstWhere((e) => e.toString() == 'TaskCategory.' + str);
}
