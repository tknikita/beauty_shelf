import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The official period-after-opening (PAO) symbol — an open cosmetic jar.
///
/// Rendered from the official vector artwork (`assets/icons/pao_symbol.svg`),
/// tinted to [color]. No months label.
class OpenedJarIcon extends StatelessWidget {
  final double size;
  final Color color;

  const OpenedJarIcon({super.key, this.size = 18, required this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/pao_symbol.svg',
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
