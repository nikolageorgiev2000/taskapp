import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:taskapp/task.dart';

class TaskLoader extends StatefulWidget {
  final Function(Key, List<Task>) widgetWithTasks;
  final Function(Key, List<Task>) widgetNoTasks;
  const TaskLoader(this.widgetWithTasks, {Key key, this.widgetNoTasks})
      : super(key: key);

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
