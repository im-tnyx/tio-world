import 'package:flutter/material.dart';
import 'package:tio_shared/shared.dart';

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
    this.requiredDestination,
  });

  final String title;
  final IconData icon;
  final WearHomeTileAction action;
  final AppDestination? requiredDestination;
}
