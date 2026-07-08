import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

const List<String> _defaultImageKeys = <String>[
  'imageUrl',
  'image',
  'imageBase64',
  'photoUrl',
  'logo',
  'coverImage',
];

String resolveImageSource(
  Map<String, dynamic>? data, {
  List<String> preferredKeys = _defaultImageKeys,
}) {
  if (data == null) return '';

  for (final key in preferredKeys) {
    final rawValue = data[key];
    if (rawValue == null) continue;

    final value = rawValue.toString().trim();
    if (value.isEmpty || value.toLowerCase() == 'null') continue;

    return value;
  }

  return '';
}

bool isNetworkImageSource(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  return normalized.startsWith('http://') || normalized.startsWith('https://');
}

Uint8List? tryDecodeImageBytes(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty || isNetworkImageSource(normalized)) {
    return null;
  }

  final pureBase64 =
      normalized.contains(',') ? normalized.split(',').last.trim() : normalized;

  try {
    return base64Decode(pureBase64);
  } catch (_) {
    return null;
  }
}

class AppImage extends StatelessWidget {
  final String imageSource;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget fallback;
  final Widget? placeholder;

  const AppImage({
    super.key,
    required this.imageSource,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final source = imageSource.trim();

    if (isNetworkImageSource(source)) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, __) => placeholder ?? const SizedBox.expand(),
        errorWidget: (_, __, ___) => fallback,
      );
    }

    final bytes = tryDecodeImageBytes(source);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return fallback;
  }
}
