import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'settings.dart';
import 'package:taskapp/stats_page.dart';
import 'package:taskapp/task.dart';

class TaskLoader extends StatefulWidget {
  final Function(Key, List<Task>) widgetWithTasks;
  final Function(Key, List<Task>) widgetNoTasks;
  final StatsPeriod statsPeriodSpecified;
  final String taskCategorySpecified;

  const TaskLoader(
    Key key,
    this.widgetWithTasks,
    this.statsPeriodSpecified,
    this.taskCategorySpecified, {
    this.widgetNoTasks,
  }) : super(key: key);

  @override
  _TaskLoaderState createState() => _TaskLoaderState();
}

class _TaskLoaderState extends State<TaskLoader> {
  List<Task> _tasks = [];
  bool _tasksLoaded = false;

  StreamSubscription<QuerySnapshot> listener;

  @override
  void initState() {
    loadTasks();

    listener = taskListListener(refreshTasks);

    super.initState();
  }

  //important for when changing taskCategory, as the widget won't be deactivated+initialized, just updated
  @override
  void didUpdateWidget(covariant TaskLoader oldWidget) {
    refreshTasks();

    super.didUpdateWidget(oldWidget);
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
      //filter task list if a category is specified and is not "All"
      loadedTasks = filterTasks(loadedTasks);
      setState(() {
        _tasks = loadedTasks;
        _tasksLoaded = true;
      });
    }
    print("TASKS LOADED");
  }

  List<Task> filterTasks(List<Task> loadedTasks) {
    print("statsPeriodSpecified :  ${widget.statsPeriodSpecified}");
    List<Task> temp = List.from(loadedTasks);
    // if called from Tasks Page
    if (widget.taskCategorySpecified != null) {
      // filter by category unless "All" is selected
      if (widget.taskCategorySpecified !=
          TaskCategoryExtension.extendedValues.last) {
        temp = temp
            .where((e) =>
                (describeEnum(e.taskCategory) == widget.taskCategorySpecified))
            .toList();
      }
      // filter only most recently completed tasks if user has setting to true
      if (UserPrefs.onlyRecentCompletedTasks) {
        // only get completed tasks from past week
        temp = temp
            .where((e) =>
                e.epochCompleted == -1 ||
                DateTime.fromMillisecondsSinceEpoch(e.epochCompleted)
                    .isAfter(DateTime.now().subtract(Duration(days: 3))))
            .toList();
      }
    }
    // if called from Stats Page
    if (widget.statsPeriodSpecified != null) {
      // only show statistics about completed tasks!!!
      temp = temp.where((e) => (e.epochCompleted != -1)).toList();
      // adjust for period specified
      switch (widget.statsPeriodSpecified) {
        case StatsPeriod.Daily:
          DateTime dayBefore = DateTime.now().subtract(Duration(days: 1));
          temp = temp
              .where((e) =>
                  DateTime.fromMillisecondsSinceEpoch(e.epochCompleted)
                      .isAfter(dayBefore))
              .toList();
          break;
        case StatsPeriod.Weekly:
          DateTime weekBefore = DateTime.now().subtract(Duration(days: 7));
          temp = temp
              .where((e) =>
                  DateTime.fromMillisecondsSinceEpoch(e.epochCompleted)
                      .isAfter(weekBefore))
              .toList();
          break;
        case StatsPeriod.Monthly:
          DateTime monthBefore = DateTime.now().subtract(Duration(days: 30));
          temp = temp
              .where((e) =>
                  DateTime.fromMillisecondsSinceEpoch(e.epochCompleted)
                      .isAfter(monthBefore))
              .toList();
          break;
        case StatsPeriod.Annual:
          DateTime yearBefore = DateTime.now().subtract(Duration(days: 365));
          temp = temp
              .where((e) =>
                  DateTime.fromMillisecondsSinceEpoch(e.epochCompleted)
                      .isAfter(yearBefore))
              .toList();
          break;
        default:
          break;
      }
    }
    return temp;
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
    print("---TaskLoader REBUILT");
    if (_tasksLoaded && _tasks.isNotEmpty) {
      return RefreshIndicator(
        child: widget.widgetWithTasks(widget.key, _tasks),
        onRefresh: refreshTasks,
      );
    } else {
      // check if alternative widget offered for when tasks aren't available
      return (widget.widgetNoTasks != null)
          ? widget.widgetNoTasks(widget.key, _tasks)
          : widget.widgetWithTasks(widget.key, _tasks);
    }
  }
}
