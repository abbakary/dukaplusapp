import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_colors.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: AppColors.border,
    highlightColor: AppColors.divider,
    child: Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

class ShimmerStatCardRow extends StatelessWidget {
  const ShimmerStatCardRow({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: ShimmerBox(width: double.infinity, height: 110, radius: 16)),
      const SizedBox(width: 12),
      Expanded(child: ShimmerBox(width: double.infinity, height: 110, radius: 16)),
    ],
  );
}

class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: AppColors.border,
    highlightColor: AppColors.divider,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Container(height: 11, width: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(height: 14, width: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
        ],
      ),
    ),
  );
}

class ShimmerList extends StatelessWidget {
  final int count;
  const ShimmerList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: count,
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemBuilder: (_, __) => const ShimmerListTile(),
  );
}
