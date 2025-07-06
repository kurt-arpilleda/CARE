import 'package:flutter/material.dart';

Future<int?> showAccountTypeDialog(BuildContext context) async {
  return await showDialog<int>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.account_circle, size: 28, color: Colors.blue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Choose Account Type',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildAccountOption(
                      context,
                      icon: Icons.local_shipping,
                      title: 'Driver',
                      color: Colors.teal,
                      value: 0,
                    ),
                    const SizedBox(height: 10),
                    _buildAccountOption(
                      context,
                      icon: Icons.storefront,
                      title: 'Shop Owner',
                      color: Colors.orange,
                      value: 1,
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildAccountOption(
    BuildContext context, {
      required IconData icon,
      required String title,
      required Color color,
      required int value,
    }) {
  return InkWell(
    onTap: () => Navigator.pop(context, value),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(fontSize: 16, color: color),
          ),
        ],
      ),
    ),
  );
}
