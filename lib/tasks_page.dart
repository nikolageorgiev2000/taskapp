import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:taskapp/task_loader.dart';

import 'task.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class TasksPage extends StatelessWidget {
  TasksPage(Key key);

  @override
  Widget build(BuildContext context) {
    return TaskLoader((Key key, List<Task> tasks) {
      return TaskList(key, false, tasks);
    });
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
      },
    );
  }
}
