import 'package:flutter/material.dart';

class TrackedItemCard extends StatelessWidget {
  final bool isCompleted;
  final int streak;
  final IconData streakIcon;
  final Color streakColor;
  final String title;
  final String description;
  final List<Widget> infoLines;
  final List<Widget> topRightWidgets;
  final VoidCallback onToggle;
  final VoidCallback? onTapTitle;
  final Color activeBorderColor;
  final Color backgroundColor;

  const TrackedItemCard({
    super.key,
    required this.isCompleted,
    required this.streak,
    required this.streakIcon,
    required this.streakColor,
    required this.title,
    required this.description,
    required this.infoLines,
    required this.topRightWidgets,
    required this.onToggle,
    this.onTapTitle,
    required this.activeBorderColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: isCompleted ? Border.all(color: activeBorderColor, width: 2) : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    streakIcon,
                    color: isCompleted ? streakColor : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "$streak",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isCompleted ? streakColor : Colors.grey,
                    ),
                  ),
                ],
              ),
              Row(children: topRightWidgets),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onTapTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
                if (infoLines.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...infoLines,
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isCompleted
                    ? activeBorderColor
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                isCompleted ? Icons.check : Icons.circle_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
