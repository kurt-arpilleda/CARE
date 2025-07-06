import 'package:flutter/material.dart';

Future<int?> showAccountTypeDialog(BuildContext context) async {
  return await showDialog<int>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Select Account Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Driver'),
              onTap: () => Navigator.pop(context, 0),
            ),
            ListTile(
              title: const Text('Shop Owner'),
              onTap: () => Navigator.pop(context, 1),
            ),
          ],
        ),
      );
    },
  );
}