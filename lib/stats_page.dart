import 'dart:core';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//might have to remove in the future due to ambiguous import error (TextStyle)
//instead import charts_flutter 'as charts' and prefix libs with 'charts.'
import 'package:flutter/src/painting/text_style.dart' as text_style;

import 'package:charts_flutter/flutter.dart';
import 'package:taskapp/task.dart';
import 'package:taskapp/task_loader.dart';

class StatsPage extends StatelessWidget {
  StatsPage(Key key);

  @override
  Widget build(BuildContext context) {
    return TaskLoader((Key key, List<Task> tasks) {
      return StatsList(key, tasks);
    });
  }
}

class StatsList extends StatefulWidget {
  final List<Task> tasks;

  const StatsList(Key key, this.tasks) : super(key: key);

  @override
  _StatsListState createState() => _StatsListState();
}

class _StatsListState extends State<StatsList> {
  // Series<dataType.y, domainType>, where domain is x, measure is y
  // where Series(data: List<dataType>)
  List<Series<String, String>> _tasksMinutesPerCategory = List();
  List<Series<String, String>> _tasksCompletedPerCategory = List();
  List<Series<DateTime, DateTime>> _tasksCompletedOverTime = List();

  bool _animate = true;

  @override
  void initState() {
    // chart 1 series : minutes spent per category
    var minutesPerCategory = Map.fromIterable(TaskCategory.values,
        key: (e) => describeEnum(e), value: (e) => 0);
    for (var task in widget.tasks) {
      minutesPerCategory[describeEnum(task.taskCategory)] +=
          calcTimeSpent(task.workPeriods);
    }
    minutesPerCategory =
        minutesPerCategory.map((key, value) => MapEntry(key, value ~/ 60));
    var minutesPerCategoryValues = minutesPerCategory.keys.toList();
    minutesPerCategoryValues.sort(
        (x, y) => (minutesPerCategory[x] > minutesPerCategory[y] ? -1 : 1));
    _tasksMinutesPerCategory.add(Series(
        id: "",
        domainFn: (String t, _) => t,
        measureFn: (String t, _) => minutesPerCategory[t],
        data: minutesPerCategoryValues));

    // chart 2 series : completed tasks per category

    var completedPerCategory = Map.fromIterable(TaskCategory.values,
        key: (e) => describeEnum(e), value: (e) => 0);
    for (var task in widget.tasks) {
      completedPerCategory[describeEnum(task.taskCategory)] +=
          task.epochCompleted == -1 ? 0 : 1;
    }
    completedPerCategory =
        completedPerCategory.map((key, value) => MapEntry(key, value));
    var completedPerCategoryValues = completedPerCategory.keys.toList();
    completedPerCategoryValues.sort(
        (x, y) => (completedPerCategory[x] > completedPerCategory[y] ? -1 : 1));
    _tasksCompletedPerCategory.add(Series(
        id: "",
        domainFn: (String t, _) => t,
        measureFn: (String t, _) => completedPerCategory[t],
        data: completedPerCategoryValues));

    // chart 3 series : work on tasks over time per category

    var completedOverTime = Map.fromIterable(TaskCategory.values,
        key: (e) => describeEnum(e), value: (e) => List<DateTime>());
    int earliestCompleted = pow(2, 42);
    for (var task in widget.tasks) {
      if (task.epochCompleted != -1) {
        earliestCompleted = min(earliestCompleted, task.epochCompleted);
        completedOverTime[describeEnum(task.taskCategory)]
            .add(DateTime.fromMillisecondsSinceEpoch(task.epochCompleted));
      }
    }
    earliestCompleted -= Duration.millisecondsPerDay;
    for (var l in completedOverTime.keys) {
      completedOverTime[l]
          .add(DateTime.fromMillisecondsSinceEpoch(earliestCompleted));
      completedOverTime[l].sort((x, y) => x.isBefore(y) ? -1 : 1);
    }
    completedOverTime =
        completedOverTime.map((key, value) => MapEntry(key, value));
    var completedOverTimeValues = completedOverTime.keys.toList();
    completedOverTimeValues.sort((x, y) => (completedOverTime[x]
                [completedOverTime[x].length - 1]
            .isAfter(completedOverTime[y][completedOverTime[y].length - 1])
        ? -1
        : 1));
    for (String t in completedOverTimeValues) {
      // print("$t + ${completedOverTime[t]}");
      _tasksCompletedOverTime.add(Series(
          id: t,
          domainFn: (DateTime dt, int i) => dt,
          measureFn: (DateTime dt, int i) => i,
          data: completedOverTime[t]));
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    text_style.TextStyle chartTitle =
        text_style.TextStyle(fontWeight: FontWeight.w500, fontSize: 16);
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
        ),
        // chart 1
        Center(child: Text("Minutes Spent per Category", style: chartTitle)),
        Container(
            padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
            height: 300,
            child: BarChart(
              _tasksMinutesPerCategory,
              domainAxis: OrdinalAxisSpec(
                renderSpec: SmallTickRendererSpec(
                  labelRotation: 30,
                ),
              ),
              animate: _animate,
            )),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
        ),
        // chart 2
        Center(child: Text("Completed Tasks per Category", style: chartTitle)),
        Container(
            padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
            height: 300,
            child: BarChart(
              _tasksCompletedPerCategory,
              domainAxis: OrdinalAxisSpec(
                renderSpec: SmallTickRendererSpec(
                  labelRotation: 30,
                ),
              ),
              animate: _animate,
            )),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
        ),
        // chart 3
        Center(child: Text("Completed Tasks over Time", style: chartTitle)),
        Container(
            padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
            height: 400,
            child: TimeSeriesChart(
              _tasksCompletedOverTime,
              // defaultRenderer:
              //     LineRendererConfig(includeArea: true, stacked: true),
              domainAxis: DateTimeAxisSpec(
                // tickProviderSpec: DateTimeEndPointsTickProviderSpec(),
                renderSpec: SmallTickRendererSpec(
                    // labelRotation: 30,
                    ),
              ),
              animate: _animate,
              behaviors: [
                SeriesLegend(
                    desiredMaxColumns: 3,
                    position: BehaviorPosition.bottom,
                    horizontalFirst: true,
                    entryTextStyle: TextStyleSpec(fontSize: 15)),
              ],
            )),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
        ),
      ],
    );
  }
}

List centeredSort(List l) {
  var cent = List.generate(l.length, (index) => l[0]);
  int mid = cent.length ~/ 2;
  for (var i = 0; i < cent.length; i++) {
    cent[mid + i ~/ 2 * (i % 2 == 1 ? 1 : -1)] = l[i];
  }
  return cent;
}

/*
Stats Ideas:
minutes spent on task per category
total time spent
most worked on task
tasks completed per category
average time spent per task

*/
