import 'package:flutter/material.dart';

import '../../domain/entities/dispute_status.dart';

/// Nizo holatini qisqacha ko'rsatuvchi belgi (docs/UI.md, "Holatni
/// shaffof ko'rsatish" tamoyili).
class DisputeStatusBadge extends StatelessWidget {
  const DisputeStatusBadge({required this.status, super.key});

  final DisputeStatus status;

  String get _label => switch (status) {
    DisputeStatus.open => 'Ochiq',
    DisputeStatus.aiAnalyzing => 'AI tahlil qilmoqda',
    DisputeStatus.aiAnalyzed => 'AI tahlili tayyor',
    DisputeStatus.resolved => 'Hal qilindi',
    DisputeStatus.closed => 'Yopilgan',
  };

  Color get _color => switch (status) {
    DisputeStatus.open => Colors.blue,
    DisputeStatus.aiAnalyzing => Colors.orange,
    DisputeStatus.aiAnalyzed => Colors.purple,
    DisputeStatus.resolved => Colors.green,
    DisputeStatus.closed => Colors.blueGrey,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
