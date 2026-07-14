// lib/widgets/quick_reply_bar.dart
import 'package:flutter/material.dart';

class QuickReplyBar extends StatelessWidget {
  final List<String> options;
  final void Function(String) onSelected;

  const QuickReplyBar({
    super.key,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = options[index];
          return ActionChip(
            label: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E2A5E)),
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF1E2A5E), width: 1.4),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onPressed: () => onSelected(label),
          );
        },
      ),
    );
  }
}