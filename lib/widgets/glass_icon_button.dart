import 'package:flutter/material.dart';

class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool hover = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => pressed = true),
        onTapUp: (_) {
          setState(() => pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 50,
          height: 50,
          transform: Matrix4.translationValues(
            0,
            pressed ? 0 : hover ? -2 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: hover
                ? const Color.fromRGBO(34, 40, 49, 0.95)
                : const Color.fromRGBO(34, 40, 49, 0.85),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: hover
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.15),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: hover ? 16 : 12,
                offset: Offset(0, pressed ? 2 : 4),
                color: Colors.black.withValues(alpha: 0.3),
              )
            ],
          ),
          child: const Icon(
            Icons.download,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
