import 'dart:developer';
import 'dart:io';

import 'task.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math';
// Import the firebase_core and cloud_firestore plugin
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TasksPage extends StatefulWidget {
  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Task> _tasks = [];
  bool _tasksLoaded = false;

  @override
  void initState() {
    loadTasks();
    super.initState();
  }

  Task taskFromDoc(QueryDocumentSnapshot d) {
    Map<String, dynamic> docDict = d.data();
    Task newTask =
        Task(docDict['name'], docDict['taskUID'], docDict['epochDue']);
    // Expand with check for the rest of the optional fields...
    if (docDict['description'] != null) {
      newTask.description = docDict['description'];
    }
    if (docDict['location'] != null) {
      newTask.location = docDict['location'];
    }
    if (docDict['taskCategory'] != null) {
      newTask.taskCategory = stringToCategory(docDict['taskCategory']);
    }
    return newTask;
  }

  void loadTasks() async {
    print("LOADING TASKS");
    CollectionReference tasks = FirebaseFirestore.instance
        .collection('users')
        .doc("test-user")
        .collection("tasks");
    var taskSnapshot = await tasks.get();
    setState(() {
      _tasks = taskSnapshot.docs.map((e) => taskFromDoc(e)).toList();
      _tasksLoaded = true;
    });
    print("TASKS LOADED");
  }

  Future<void> refreshTasks() async {
    print('refreshing');
    loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    if (_tasksLoaded) {
      return RefreshIndicator(
        child: TaskList(
            PageStorageKey("Task Page Key"), false, _tasks, refreshTasks),
        onRefresh: refreshTasks,
      );
    } else {
      return Scaffold();
    }
  }
}

class TaskList extends StatefulWidget {
  final bool _doubleTapped;
  final List<Task> _tasks;
  final VoidCallback refreshTasks;

  TaskList(Key key, this._doubleTapped, this._tasks, this.refreshTasks)
      : super(key: key);

  bool get doubleTapped => _doubleTapped;
  List<Task> get tasks => _tasks;

  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  ScrollController scrollController = ScrollController();

  //Create list of tasks
  @override
  Widget build(BuildContext context) {
    //scroll to top if TaskList icon in menu tapped while already on page
    if (this.widget.doubleTapped) {
      scrollController.animateTo(scrollController.initialScrollOffset,
          duration: Duration(
              milliseconds: min(scrollController.position.pixels ~/ 2, 2000)),
          curve: Curves.easeOutCubic);
    }
    print("BUILDING TASKLIST");
    return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        reverse: false,
        controller: scrollController,
        /*Use itermCount (length of list) and itemExtent (height of an item)
        for improved speed switching between tabs (rebuilding list) */
        itemCount: this.widget._tasks.length,
        // itemExtent: 150,
        itemBuilder: (context, index) {
          return TaskCard(this.widget.key, widget._tasks[index]);
        });
  }
}
