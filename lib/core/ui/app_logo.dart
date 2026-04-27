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
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E658F),
            Color(0xFF26978A),
            Color(0xFFF1BE7B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E658F).withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.2),
            ),
          ),
          Positioned(
            top: size * 0.17,
            right: size * 0.15,
            child: Container(
              width: size * 0.15,
              height: size * 0.15,
              decoration: const BoxDecoration(
                color: Color(0xFF17324B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: size * 0.26,
            child: Container(
              width: size * 0.04,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: const Color(0xFF2E658F).withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: size * 0.26,
            child: Container(
              width: size * 0.04,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: const Color(0xFFF1BE7B).withValues(alpha: 0.42),
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
                    letterSpacing: -0.8,
                  ),
            ),
            Text(
              'Online',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667A91),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
