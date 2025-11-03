import 'package:flutter/material.dart';

/// Shimmer loading effect for profile post grid
class ShimmerLoadingGrid extends StatefulWidget {
  final int itemCount;
  final double? childAspectRatio;

  const ShimmerLoadingGrid({
    super.key,
    this.itemCount = 6,
    this.childAspectRatio = 0.75,
  });

  @override
  State<ShimmerLoadingGrid> createState() => _ShimmerLoadingGridState();
}

class _ShimmerLoadingGridState extends State<ShimmerLoadingGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final bottomPadding = bottomSafeArea + 210;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
      itemCount: widget.itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: widget.childAspectRatio ?? 0.75,
      ),
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.grey[850]!,
                            Colors.grey[800]!,
                            Colors.grey[850]!,
                          ]
                        : [
                            Colors.grey[300]!,
                            Colors.grey[200]!,
                            Colors.grey[300]!,
                          ],
                    stops: [
                      _shimmerController.value - 0.3,
                      _shimmerController.value,
                      _shimmerController.value + 0.3,
                    ].map((v) => v.clamp(0.0, 1.0)).toList(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Skeleton loader for profile header
class ProfileHeaderSkeleton extends StatefulWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  State<ProfileHeaderSkeleton> createState() => _ProfileHeaderSkeletonState();
}

class _ProfileHeaderSkeletonState extends State<ProfileHeaderSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Column(
          children: [
            // Cover photo skeleton
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [baseColor, highlightColor, baseColor],
                  stops: [
                    _shimmerController.value - 0.3,
                    _shimmerController.value,
                    _shimmerController.value + 0.3,
                  ].map((v) => v.clamp(0.0, 1.0)).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Avatar skeleton
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [baseColor, highlightColor, baseColor],
                  stops: [
                    _shimmerController.value - 0.3,
                    _shimmerController.value,
                    _shimmerController.value + 0.3,
                  ].map((v) => v.clamp(0.0, 1.0)).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Username skeleton
            Container(
              width: 120,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [baseColor, highlightColor, baseColor],
                  stops: [
                    _shimmerController.value - 0.3,
                    _shimmerController.value,
                    _shimmerController.value + 0.3,
                  ].map((v) => v.clamp(0.0, 1.0)).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
