import 'package:flutter/material.dart';

class TioTabSwitcher extends StatelessWidget {
  const TioTabSwitcher({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        for (var index = 0; index < tabs.length; index++)
          ButtonSegment<int>(value: index, label: Text(tabs[index])),
      ],
      selected: {selectedIndex},
      onSelectionChanged: (selection) => onSelected(selection.first),
    );
  }
}
