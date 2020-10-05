import 'package:taskapp/task_loader.dart';

import 'task.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class TasksPage extends StatelessWidget {
  final String taskCategorySpecified;
  // bool for reseting (e.g. list resets by scrolling back to top)
  final bool reset;

  TasksPage(
    Key key,
    this.taskCategorySpecified, {
    this.reset = false,
  });

  @override
  Widget build(BuildContext context) {
    print("---TasksPage REBUILT");
    print("taskCategorySpecified: $taskCategorySpecified");
    return TaskLoader(
      this.key,
      (Key key, List<Task> tasks) {
        return TaskList(key, tasks, this.reset);
      },
      // statsPeriodSpecified must be null, it's filtering is used
      null,
      taskCategorySpecified,
    );
  }
}

class TaskList extends StatefulWidget {
  final bool reset;
  final List<Task> _tasks;

  TaskList(
    Key key,
    this._tasks,
    this.reset,
  ) : super(key: key);

  bool get doubleTapped => reset;
  List<Task> get tasks => _tasks;

  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  ScrollController scrollController = ScrollController();

  //Create list of tasks
  @override
  Widget build(BuildContext context) {
    //scroll to top if Tasks page icon in menu tapped while already on page
    //need to check if scroll controller has clients (aka is attached to a list)
    if (this.widget.doubleTapped && scrollController.hasClients) {
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
      itemCount: this.widget.tasks.length,
      // itemExtent: 150,
      itemBuilder: (context, index) {
        return TaskCard(this.widget.key, widget.tasks[index]);
      },
    );
  }
}
