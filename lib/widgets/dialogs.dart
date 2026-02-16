import 'package:flutter/material.dart';

class AppEmptyHint extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const AppEmptyHint({
    super.key,
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ),
    );
  }
}
