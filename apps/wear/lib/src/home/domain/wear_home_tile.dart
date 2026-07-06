import 'package:flutter/material.dart';

enum WearHomeTileAction {
  workoutRoutine,
  workoutThisWeek,
  addFood,
  addWater,
  viewSummary,
  nutrition,
  settings,
}

class WearHomeTile {
  const WearHomeTile({
    required this.title,
    required this.icon,
    required this.action,
  });

  final String title;
  final IconData icon;
  final WearHomeTileAction action;
}
