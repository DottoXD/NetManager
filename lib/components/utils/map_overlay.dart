import 'package:flutter/material.dart';

Widget mapOverlay(
  BuildContext context,
  String speed,
  String cellId,
  String signalStrengthString,
  String signalStrength,
) {
  return Align(
    alignment: Alignment.topCenter,
    child: Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 36.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Speed",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                SizedBox(height: 4),
                Text(speed),
              ],
            ),
            SizedBox(width: 24),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Cell ID",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                SizedBox(height: 4),
                Text(cellId),
              ],
            ),
            SizedBox(width: 24),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  signalStrengthString,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                SizedBox(height: 4),
                Text(signalStrength),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
