import 'dart:async';
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
  TasksPage(Key key) : super(key: key);

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Task> _tasks = [];
  bool _tasksLoaded = false;

  StreamSubscription<QuerySnapshot> listener;

  @override
  void initState() {
    loadTasks();

    listener = taskListListener(refreshTasks);

    super.initState();
  }

  @override
  void deactivate() {
    //Cancel listener.
    listener.cancel();
    super.deactivate();
  }

  Future<void> loadTasks() async {
    print("LOADING TASKS");
    List<Task> loadedTasks = await getOrderedTasks();
    //check if TaskPage is still in widget tree before setting state (fixes error)
    if (this.mounted) {
      setState(() {
        _tasks = loadedTasks;
        _tasksLoaded = true;
      });
    }
    print("TASKS LOADED");
  }

  Future<void> refreshTasks() async {
    print('REFRESHING TASK PAGE');
    if (await online()) {
      FirebaseFirestore.instance.enableNetwork();
      await loadTasks();
    } else {
      FirebaseFirestore.instance.disableNetwork();
      loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tasksLoaded) {
      return Scaffold(
          body: RefreshIndicator(
        child: TaskList(
            PageStorageKey("Task Page Key"), false, _tasks, refreshTasks),
        onRefresh: refreshTasks,
      ));
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
