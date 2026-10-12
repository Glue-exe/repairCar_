import 'package:flutter/material.dart';
import 'package:my_app/config/app_color.dart';
import 'package:my_app/config/app_config.dart';


class PartImageThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double borderRadius;

  const PartImageThumbnail({
    super.key,
    this.imageUrl,
    this.size = 72,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final fullUrl = AppConfig.getImageUrl(imageUrl);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildContent(fullUrl),
      ),
    );
  }

  Widget _buildContent(String fullUrl) {
    if (fullUrl.isEmpty) {
      return _buildFallback();
    }

    return Image.network(
      fullUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: SizedBox(
            width: size * 0.3,
            height: size * 0.3,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildFallback();
      },
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Icon(
        Icons.build_circle_outlined,
        size: size * 0.42,
        color: AppColors.disabled,
      ),
    );
  }
}
