import 'dart:async';
import 'dart:core';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:crypto/crypto.dart';
// Import the firebase_core and cloud_firestore plugin
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  void checkRunningTimer() {
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
    checkRunningTimer();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    checkRunningTimer();
    super.initState();
  }

  @override
  void deactivate() {
    print("DEACTIVATING");
    endTask();
    super.deactivate();
  }

  var cardBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(15));
  @override
  Widget build(BuildContext context) {
    print("BUILDING TASKCARD: ${widget.task.name}");
    if (widget.task.epochCompleted < 0) {
      return Card(
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
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                                Text("name: " + widget.task.name)
                              ]),
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
                                Text("uid: " +
                                    widget.task.taskUID.substring(
                                        0, min(widget.task.taskUID.length, 10)))
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
                                  if (widget.task.epochStart < 0)
                                    FlatButton.icon(
                                      icon: Icon(Icons.play_arrow,
                                          color: Colors.blueGrey),
                                      onPressed: () async {
                                        print("Time Started");
                                        startTask();
                                        _flatButtonPressed = false;
                                      },
                                      label: Text("1:25"),
                                    ),
                                  if (widget.task.epochStart >= 0)
                                    FlatButton.icon(
                                      icon: Icon(Icons.play_arrow,
                                          color: Colors.blueGrey),
                                      onPressed: () {
                                        print("Timer Ended");
                                        endTask();
                                        _flatButtonPressed = false;
                                      },
                                      label: Text(_trackedTime.toString()),
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
        elevation: 3,
        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      );
    } else {
      return Card(
        shape: cardBorder,
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
                            Text("epochDue: " + widget.task.epochDue.toString())
                          ]),
                          Divider(
                            color: Colors.transparent,
                            height: 5,
                          ),
                          Row(children: [
                            Text("uid: " +
                                widget.task.taskUID.substring(
                                    0, min(widget.task.taskUID.length, 10)))
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
                              FlatButton(
                                onPressed: () {
                                  print("Track - Pressed");
                                  _flatButtonPressed = false;
                                },
                                child: Text("1:25"),
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
                                        content:
                                            Text("Mark task as incomplete?"),
                                        actions: [
                                          FlatButton(
                                              child: Text("Confirm"),
                                              onPressed: () async {
                                                widget.task.epochCompleted = -1;
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
        ),
        elevation: 3,
        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      );
    }
  }
}

String formatDate(DateTime dateTime) {
  return "${dateTime.day.toString()}-${dateTime.month.toString()}-${dateTime.year.toString()}";
}

String formatTime(TimeOfDay time) {
  return "${time.hour}:${time.minute}";
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
      .doc("test-user")
      .collection("tasks");
  return tasks;
}

Future<List<Task>> getOrderedTasks() async {
  print("RETREIVING TASKS FROM FIRESTORE");
  CollectionReference tasks = getTaskCollection();
  QuerySnapshot taskSnapshot = await tasks.orderBy('epochDue').get();
  return taskSnapshot.docs.map((e) => taskFromDoc(e)).toList();
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
    newTask.taskCategory = stringToCategory(docDict['taskCategory']);
  } else {
    newTask.taskCategory = Category.None;
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

  print("ID:${d.id}");
  return newTask;
}

void createTask(context) async {
  // create blank task and edit it
  Task newTask = Task.blankTask();
  newTask.epochDue = DateTime.now().millisecondsSinceEpoch;
  await newTask.editTask(context);
}

Future<void> saveTask(Task task) async {
  //save task in Firestore (check if it already exists and update it, otherwise create new document)
  CollectionReference tasks = getTaskCollection();
  //update fields
  await tasks
      .doc(task.taskUID)
      .set(task.toMapNoArrays(), SetOptions(merge: true));
  //array union of work-time tracked
  await tasks
      .doc(task.taskUID)
      .update({'workPeriods': FieldValue.arrayUnion(task.workPeriods)});
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
  Category taskCategory;
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
      this.taskCategory = Category.None,
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
    return Task("", createTaskUID(), DateTime.now().millisecondsSinceEpoch);
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
      "taskCategory": categoryToString(taskCategory),
      "eventUID": eventUID,
      "epochStart": epochStart,
    };
  }

  Future<void> editTask(BuildContext context) async {
    // determines if dialog pops up to confirm/discard/cancel changes when user taps away from modalsheet
    bool editting = true;
    // checks if the current changes have been saved with save button
    bool saved = false;

    Task newTask = this.clone();

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
              print(newTask.taskUID);
              print(newTask.location);
              print(initDate.toString());
              TimeOfDay initTime = TimeOfDay.fromDateTime(initDate);
              Category initCategory = newTask.taskCategory;

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
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Buttons to Save/Cancel Task
                  Center(
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          icon: Icon(Icons.save),
                          onPressed: () async {
                            await saveTask(newTask);
                            saved = true;
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
                  TextFormField(
                    initialValue: newTask.name,
                    maxLength: 30,
                    minLines: 1,
                    maxLines: 1,
                    scrollPadding: EdgeInsets.all(2),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(1),
                          gapPadding: 1),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(1),
                          gapPadding: 1),
                      labelText: 'Task Name',
                      labelStyle: TextStyle(color: Colors.blueGrey),
                      counterText: null,
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: (inputString) {
                      newTask.name = inputString;
                    },
                  ),

                  //Description
                  TextFormField(
                    initialValue: newTask.description,
                    maxLength: 280,
                    minLines: 1,
                    maxLines: 10,
                    scrollPadding: EdgeInsets.all(2),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(1),
                          gapPadding: 1),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(1),
                          gapPadding: 1),
                      labelText: 'Description',
                      labelStyle: TextStyle(color: Colors.blueGrey),
                      counterText: null,
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: (inputString) {
                      newTask.description = inputString;
                    },
                  ),

                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    //Date Due
                    FlatButton(
                        onPressed: () async {
                          await _showDatePicker();
                        },
                        child: Text(formatDate(
                            DateTime.fromMillisecondsSinceEpoch(
                                newTask.epochDue)))),
                    //Time Due
                    FlatButton(
                        onPressed: () async {
                          await _showTimePicker();
                        },
                        child: Text(formatTime(initTime))),
                  ]),

                  //Location
                  TextFormField(
                    initialValue: newTask.location,
                    maxLength: 30,
                    minLines: 1,
                    maxLines: 1,
                    scrollPadding: EdgeInsets.all(2),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(1),
                          gapPadding: 1),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(1),
                          gapPadding: 1),
                      labelText: 'Location',
                      labelStyle: TextStyle(color: Colors.blueGrey),
                      counterText: null,
                    ),
                    textInputAction: TextInputAction.done,
                    onChanged: (inputString) {
                      newTask.location = inputString;
                    },
                  ),

                  //Category selection
                  DropdownButton<Category>(
                      value: initCategory,
                      items: List.generate(
                          Category.values.length,
                          (i) => DropdownMenuItem(
                                value: Category.values[i],
                                child:
                                    Text(categoryToString(Category.values[i])),
                              )),
                      onChanged: (val) {
                        setModalState(() {
                          newTask.taskCategory = val;
                        });
                      }),

                  Padding(
                    padding: EdgeInsets.all(5),
                  ),

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

      // when user presses out of modal sheet, check they've saved
      if (!saved && editting && this.changedThroughEdit(newTask)) {
        await showDialog(
            context: context,
            child: AlertDialog(
              content: Text("Save changes?"),
              actions: [
                FlatButton(
                    child: Text("Confirm"),
                    onPressed: () async {
                      await saveTask(newTask);
                      editting = false;
                      Navigator.of(context).pop();
                    }),
                FlatButton(
                    child: Text("Discard"),
                    onPressed: () {
                      editting = false;
                      Navigator.of(context).pop();
                    }),
                FlatButton(
                    child: Text("Cancel"),
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

enum Category { None, Work, School, Hobby, Health, Social, Family, Chores }

Category stringToCategory(String str) {
  return Category.values.firstWhere((e) => e.toString() == 'Category.' + str);
}

String categoryToString(Category c) {
  return c.toString().split('.').last;
}

/*TODO: figure out how to: 
    use firestore functions offline
*/
