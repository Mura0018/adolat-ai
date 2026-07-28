import 'package:flutter/material.dart';

import '../../domain/entities/appeal_status.dart';

/// Murojaat holatini qisqacha ko'rsatuvchi belgi (docs/UI.md, "Holatni
/// shaffof ko'rsatish" tamoyili).
class AppealStatusBadge extends StatelessWidget {
  const AppealStatusBadge({required this.status, super.key});

  final AppealStatus status;

  String get _label => switch (status) {
    AppealStatus.draft => 'Qoralama',
    AppealStatus.submitted => 'Yuborildi',
    AppealStatus.inReview => 'Ko\'rib chiqilmoqda',
    AppealStatus.answered => 'Javob berildi',
    AppealStatus.rejected => 'Rad etildi',
    AppealStatus.closed => 'Yopilgan',
  };

  Color _color(BuildContext context) => switch (status) {
    AppealStatus.draft => Colors.grey,
    AppealStatus.submitted => Colors.blue,
    AppealStatus.inReview => Colors.orange,
    AppealStatus.answered => Colors.green,
    AppealStatus.rejected => Colors.red,
    AppealStatus.closed => Colors.blueGrey,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
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
