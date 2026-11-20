import 'package:material_ui/material_ui.dart';

/// Circular avatar with the member's initials.
class MemberAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color? backgroundColor;

  const MemberAvatar({
    super.key,
    required this.name,
    this.radius = 20,
    this.backgroundColor,
  });

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isEmpty ? '?' : parts.first[0].toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        initialsOf(name),
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
