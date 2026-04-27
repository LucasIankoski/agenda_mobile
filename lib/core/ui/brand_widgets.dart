import 'package:flutter/material.dart';

class AppBackdrop extends StatelessWidget {
  final Widget child;

  const AppBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAFD),
            Color(0xFFF5F7FB),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -56,
            left: -48,
            child: _AmbientShape(
              width: 180,
              height: 180,
              color: Color(0xFFDCE7F3),
            ),
          ),
          const Positioned(
            top: 180,
            right: -64,
            child: _AmbientShape(
              width: 170,
              height: 170,
              color: Color(0xFFF8E9CC),
            ),
          ),
          const Positioned(
            bottom: -56,
            left: 24,
            child: _AmbientShape(
              width: 120,
              height: 120,
              color: Color(0xFFE3F0EC),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? tint;
  final Color? borderColor;
  final List<BoxShadow>? shadows;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 24,
    this.tint,
    this.borderColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = tint == null ? Colors.white : Color.lerp(Colors.white, tint, 0.08)!;

    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ??
              (tint == null ? scheme.outline.withValues(alpha: 0.8) : tint!.withValues(alpha: 0.2)),
        ),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: const Color(0xFF16324A).withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: child,
    );
  }
}

class PageHeroCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget? trailing;
  final List<Widget> badges;
  final Widget? footer;

  const PageHeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.trailing,
    this.badges = const [],
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final titleStyle = compact
            ? Theme.of(context).textTheme.titleLarge
            : Theme.of(context).textTheme.headlineSmall;
        final subtitleStyle = compact
            ? Theme.of(context).textTheme.bodyMedium
            : Theme.of(context).textTheme.bodyLarge;

        final headerContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
            ),
            const SizedBox(height: 6),
            Text(title, style: titleStyle),
            const SizedBox(height: 8),
            Text(subtitle, style: subtitleStyle),
          ],
        );

        return SurfaceCard(
          padding: EdgeInsets.all(compact ? 18 : 20),
          tint: accent,
          borderColor: accent.withValues(alpha: 0.16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroIcon(accent: accent, icon: icon, compact: true),
                    const SizedBox(width: 12),
                    Expanded(child: headerContent),
                  ],
                ),
                if (trailing != null) ...[
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: trailing!),
                ],
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroIcon(accent: accent, icon: icon, compact: false),
                    const SizedBox(width: 16),
                    Expanded(child: headerContent),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: badges,
                ),
              ],
              if (footer != null) ...[
                const SizedBox(height: 14),
                footer!,
              ],
            ],
          ),
        );
      },
    );
  }
}

class SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackTrailing = constraints.maxWidth < 420 && trailing != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          eyebrow.toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(title, style: Theme.of(context).textTheme.titleLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!stackTrailing && trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
            if (stackTrailing) ...[
              const SizedBox(height: 12),
              trailing!,
            ],
          ],
        );
      },
    );
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      tint: tint,
      borderColor: tint.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: tint),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final background = Color.lerp(Colors.white, color, 0.12)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 15, color: color)
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EFF7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF255A84)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final bool compact;

  const _HeroIcon({
    required this.accent,
    required this.icon,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 48.0 : 56.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
      ),
      child: Icon(icon, color: accent, size: compact ? 24 : 26),
    );
  }
}

class _AmbientShape extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _AmbientShape({
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(width),
        ),
      ),
    );
  }
}
