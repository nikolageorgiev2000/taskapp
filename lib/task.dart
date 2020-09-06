import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math';
// Import the firebase_core and cloud_firestore plugin
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  // final VoidCallback refreshTasks;
  TaskCard(Key key, this.task) : super(key: key);

  // TaskCard(Key key, this.task, this.refreshTasks) : super(key: key);

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool flatButtonPressed = false;

  var cardBorder =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(15));
  @override
  Widget build(BuildContext context) {
    print("BUILDING TASKCARD: location: ${widget.task.location}");
    return Card(
      shape: cardBorder,
      child: InkWell(
          customBorder: cardBorder,
          splashColor: Colors.blue.withAlpha(30),
          onLongPress: () async {
            if (!flatButtonPressed) {
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

String formatDate(DateTime dateTime) {
  return "${dateTime.day.toString()}-${dateTime.month.toString()}-${dateTime.year.toString()}";
}

String formatTime(TimeOfDay time) {
  return "${time.hour}:${time.minute}";
}

int timeToMilliseconds(TimeOfDay timeOfDay) {
  return 1000 * (3600 * timeOfDay.hour + 60 * timeOfDay.minute);
}

void saveTask(Task task) {
  //save task in Firestore (check if it already exists and update it, otherwise create new document)
  // DocumentReference docRef = FirebaseFirestore.instance.collection("users").doc("test-user").collection("tasks").doc()
}

void deleteTask(Task task) {
  //delete task from Firestore
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

  static blankTask() {
    return Task("", "", 0);
  }

  Task(this.name, this.taskUID, this.epochDue,
      {this.epochLastEdit = -1,
      this.epochCompleted = -1,
      this.description = "",
      this.location = "",
      this.taskCategory = Category.None,
      String eventUID = ""});

  Task clone() {
    return Task(name, taskUID, epochDue,
        epochLastEdit: epochLastEdit,
        epochCompleted: epochCompleted,
        description: description,
        location: location,
        taskCategory: taskCategory,
        eventUID: eventUID);
  }

  bool changedThroughEdit(Task other) {
    return !(this == other);
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
              print(newTask.epochDue);
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
                          onPressed: () {
                            saveTask(newTask);
                            saved = true;
                          }),
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
                            deleteTask(this);
                            editting = false;
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  )),

                  Padding(
                    padding: EdgeInsets.all(5),
                  ),

                  //Task Name
                  TextFormField(
                    initialValue: newTask.name,
                    maxLength: 70,
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
                        onPressed: () {
                          _showDatePicker();
                        },
                        child: Text(formatDate(
                            DateTime.fromMillisecondsSinceEpoch(
                                newTask.epochDue)))),
                    //Time Due
                    FlatButton(
                        onPressed: () {
                          _showTimePicker();
                        },
                        child: Text(formatTime(initTime))),
                  ]),

                  //Location
                  TextFormField(
                    initialValue: newTask.location,
                    maxLength: 70,
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
                                child: Text(Category.values[i]
                                    .toString()
                                    .split('.')
                                    .last),
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
                    onPressed: () {
                      saveTask(newTask);
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

/*TODO: figure out how to: 
    add task, 
    switch between viewing saved/editing task, 
    add task from event page, add task button
*/
