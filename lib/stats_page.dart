import 'dart:core';
import 'package:flutter/material.dart';

class StatsPage extends StatefulWidget {
  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      child: ListView(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
          ),
        ],
      ),
      onRefresh: () async {
        await Future.delayed(Duration(seconds: 3), () {
          print("HI");
        });
      },
    );
  }
}
