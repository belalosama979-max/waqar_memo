import 'package:flutter/material.dart';

/// Brand palette for "الوقار". See docs/BRAND.md.
abstract final class AppColors {
  static const emerald = Color(0xFF0E4D3C);
  static const emeraldDeep = Color(0xFF08362A);
  static const emeraldLight = Color(0xFF1F7A5E);
  static const mint = Color(0xFFDCEFE6);
  static const gold = Color(0xFFC9A24B);
  static const goldLight = Color(0xFFE6C878);
  static const goldSoft = Color(0xFFF6EBCD);
  static const ivory = Color(0xFFFAF6EC);
  static const sand = Color(0xFFF1EADB);
  static const ink = Color(0xFF16211D);
  static const inkSoft = Color(0xFF55615C);
  static const danger = Color(0xFFB3261E);
  static const warning = Color(0xFFB7791F);
  static const success = Color(0xFF2E7D4F);
  static const info = Color(0xFF2B6CB0);

  // Podium medals
  static const silver = Color(0xFFA8B2B8);
  static const bronze = Color(0xFFB87333);

  static const brandGradient = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [emeraldLight, emeraldDeep],
  );
}
