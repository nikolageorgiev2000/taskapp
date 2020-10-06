import 'dart:core';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//might have to remove in the future due to ambiguous import error (TextStyle)
//instead import charts_flutter 'as charts' and prefix libs with 'charts.'
import 'package:flutter/src/painting/text_style.dart' as text_style;

//https://google.github.io/charts/flutter/gallery
import 'package:charts_flutter/flutter.dart';
import 'package:taskapp/settings.dart';
import 'package:taskapp/task.dart';
import 'package:taskapp/task_loader.dart';

class StatsPageSettings {
  static bool reset = false;
}

class StatsPage extends StatelessWidget {
  final Key key;
  final StatsPeriod statsPeriodSpecified;

  StatsPage(
    this.key,
    this.statsPeriodSpecified,
  );

  @override
  Widget build(BuildContext context) {
    return TaskLoader(
      this.key,
      (Key key, List<Task> tasks) {
        return StatsList(
          key,
          tasks,
        );
      },
      statsPeriodSpecified,
      // not specific task cateogry specified
      null,
    );
  }
}

class StatsList extends StatefulWidget {
  final List<Task> _tasks;

  StatsList(
    Key key,
    this._tasks,
  ) : super(key: key);

  List<Task> get tasks => _tasks;

  @override
  _StatsListState createState() => _StatsListState();
}

class _StatsListState extends State<StatsList> {
  // Series<dataType.y, domainType>, where domain is x, measure is y
  // where Series(data: List<dataType>)
  List<Series<String, String>> _tasksMinutesPerCategory = List();
  List<Series<String, String>> _tasksCompletedPerCategory = List();
  List<Series<String, String>> _tasksAvgPerCategory = List();
  List<Series<DateTime, DateTime>> _tasksCompletedOverTime = List();

  ScrollController scrollController = ScrollController();

  bool _animate = true;

  @override
  void initState() {
    refreshCharts();

    super.initState();
  }

  @override
  void didUpdateWidget(covariant StatsList oldWidget) {
    refreshCharts();

    super.didUpdateWidget(oldWidget);
  }

  void refreshCharts() {
    _tasksMinutesPerCategory = List();
    _tasksCompletedPerCategory = List();
    _tasksAvgPerCategory = List();
    _tasksCompletedOverTime = List();

    // CHART 1 series : minutes spent per category
    Map<String, int> minutesPerCategory = Map.fromIterable(TaskCategory.values,
        key: (e) => describeEnum(e), value: (e) => 0);
    for (var task in widget.tasks) {
      //add onto total time per category
      minutesPerCategory[describeEnum(task.taskCategory)] +=
          calcTimeSpent(task.workPeriods);
    }
    //convert to minutes, since calcTimeSpent returns seconds
    minutesPerCategory =
        minutesPerCategory.map((key, value) => MapEntry(key, value ~/ 60));
    var minutesPerCategoryValues = minutesPerCategory.keys.toList();
    // sort categories in descending order of time spent working on their tasks
    minutesPerCategoryValues.sort(
        (x, y) => (minutesPerCategory[x] > minutesPerCategory[y] ? -1 : 1));
    _tasksMinutesPerCategory.add(Series(
        id: "",
        domainFn: (String t, _) => t,
        measureFn: (String t, _) => minutesPerCategory[t],
        data: minutesPerCategoryValues));

    // CHART 2 series : completed tasks per category

    var completedPerCategory = Map.fromIterable(TaskCategory.values,
        key: (e) => describeEnum(e), value: (e) => 0);
    // count occurences
    for (var task in widget.tasks) {
      completedPerCategory[describeEnum(task.taskCategory)] +=
          task.epochCompleted == -1 ? 0 : 1;
    }

    List<String> completedPerCategoryValues =
        completedPerCategory.keys.toList();
    completedPerCategoryValues.sort(
        (x, y) => (completedPerCategory[x] > completedPerCategory[y] ? -1 : 1));
    _tasksCompletedPerCategory.add(Series(
        id: "",
        domainFn: (String t, _) => t,
        measureFn: (String t, _) => completedPerCategory[t],
        data: completedPerCategoryValues));

    // CHART 3 series : average minutes on task per category

    Map<String, int> avgPerCategory = Map.fromIterable(TaskCategory.values,
        key: (e) => describeEnum(e),
        value: (e) => completedPerCategory[describeEnum(e)] == 0
            ? 0
            : minutesPerCategory[describeEnum(e)] ~/
                completedPerCategory[describeEnum(e)]);
    List<String> avgPerCategoryValues = avgPerCategory.keys.toList();
    avgPerCategoryValues
        .sort((x, y) => (avgPerCategory[x] > avgPerCategory[y] ? -1 : 1));
    _tasksAvgPerCategory.add(Series(
        id: "",
        data: avgPerCategoryValues,
        domainFn: (String t, _) => t,
        measureFn: (String t, _) => avgPerCategory[t]));

    // CHART 4 series : work on tasks over time per category

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
    // shift earliest time a task has been completed by a day so first task shown is not just a vertical line (aesthetics)
    earliestCompleted -= Duration.millisecondsPerDay;
    // for each category, sort task completion times in ascending order
    for (var l in completedOverTime.keys) {
      completedOverTime[l]
          .add(DateTime.fromMillisecondsSinceEpoch(earliestCompleted));
      completedOverTime[l].sort((x, y) => x.isBefore(y) ? -1 : 1);
    }

    // sort categories by most recently completed task
    var completedOverTimeValues = completedOverTime.keys.toList();
    completedOverTimeValues.sort((x, y) => (completedOverTime[x]
                [completedOverTime[x].length - 1]
            .isAfter(completedOverTime[y][completedOverTime[y].length - 1])
        ? -1
        : 1));
    for (String t in completedOverTimeValues) {
      _tasksCompletedOverTime.add(Series(
          id: t,
          domainFn: (DateTime dt, int index) => dt,
          //use array index as cummulative counter of number of completed tasks
          measureFn: (DateTime dt, int index) => index,
          data: completedOverTime[t]));
    }

    setState(() {
      _animate = UserPrefs.animateCharts;
    });
  }

  @override
  Widget build(BuildContext context) {
    //scroll to top if Stats page icon in menu tapped while already on page
    //need to check if scroll controller has clients (aka is attached to a list)
    if (StatsPageSettings.reset && scrollController.hasClients) {
      scrollController.animateTo(scrollController.initialScrollOffset,
          duration: Duration(
              milliseconds: min(scrollController.position.pixels ~/ 2, 2000)),
          curve: Curves.easeOutCubic);
      StatsPageSettings.reset = false;
    }

    text_style.TextStyle chartTitle =
        text_style.TextStyle(fontWeight: FontWeight.w500, fontSize: 16);
    Padding chartPadding = Padding(
      padding: EdgeInsets.symmetric(vertical: 15),
    );
    return ListView(
      key: widget.key,
      controller: scrollController,
      children: [
        chartPadding,
        // CHART 1
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
        chartPadding,
        // CHART 2
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
        chartPadding,
        // CHART 3
        Center(child: Text("Average Minutes per Category", style: chartTitle)),
        Container(
            padding: EdgeInsets.fromLTRB(20, 10, 0, 10),
            height: 300,
            child: BarChart(
              _tasksAvgPerCategory,
              domainAxis: OrdinalAxisSpec(
                renderSpec: SmallTickRendererSpec(
                  labelRotation: 30,
                ),
              ),
              animate: _animate,
            )),
        chartPadding,
        // CHART 4
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
                  // renderSpec: SmallTickRendererSpec(
                  //     // labelRotation: 30,
                  //     ),
                  ),
              animate: _animate,
              behaviors: [
                SeriesLegend(
                    desiredMaxColumns: 4,
                    position: BehaviorPosition.bottom,
                    horizontalFirst: true,
                    entryTextStyle: TextStyleSpec(fontSize: 15)),
              ],
            )),
        chartPadding,
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

enum StatsPeriod { Daily, Weekly, Monthly, Annual, All }

/*
Stats Ideas:
minutes spent on task per category
total time spent
most worked on task
tasks completed per category
average time spent per task

*/
