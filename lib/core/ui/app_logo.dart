import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const AppLogo({
    super.key,
    this.size = 56,
    this.showWordmark = false,
  });

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7E9DC6),
            Color(0xFFAEB9CF),
            Color(0xFFE4D7CB),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7E9DC6).withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.56,
            height: size * 0.56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.18),
            ),
          ),
          Positioned(
            top: size * 0.18,
            right: size * 0.16,
            child: Container(
              width: size * 0.14,
              height: size * 0.14,
              decoration: const BoxDecoration(
                color: Color(0xFF22324F),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: size * 0.25,
            child: Container(
              width: size * 0.04,
              height: size * 0.34,
              decoration: BoxDecoration(
                color: const Color(0xFFAEB9CF).withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: size * 0.25,
            child: Container(
              width: size * 0.04,
              height: size * 0.34,
              decoration: BoxDecoration(
                color: const Color(0xFFE4D7CB).withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Agenda',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
            ),
            Text(
              'Infantil',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF66748B),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
