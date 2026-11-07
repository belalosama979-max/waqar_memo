import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../core/theme/app_colors.dart';

/// Recitation evaluation grades. Stored as the enum name in Firestore.
enum Evaluation {
  @JsonValue('excellentPlus')
  excellentPlus,
  @JsonValue('excellent')
  excellent,
  @JsonValue('veryGood')
  veryGood,
  @JsonValue('notRecited')
  notRecited,
  @JsonValue('repeat')
  repeat;

  String get label => switch (this) {
        Evaluation.excellentPlus => 'ممتاز جداً',
        Evaluation.excellent => 'ممتاز',
        Evaluation.veryGood => 'جيد جداً',
        Evaluation.notRecited => 'لم يسمع',
        Evaluation.repeat => 'رجع في التسميع',
      };

  /// Default points before the admin customizes them.
  int get defaultPoints => switch (this) {
        Evaluation.excellentPlus => 60,
        Evaluation.excellent => 40,
        Evaluation.veryGood => 25,
        Evaluation.notRecited => 0,
        Evaluation.repeat => 10,
      };

  Color get color => switch (this) {
        Evaluation.excellentPlus => AppColors.emerald,
        Evaluation.excellent => AppColors.emeraldLight,
        Evaluation.veryGood => AppColors.gold,
        Evaluation.notRecited => AppColors.danger,
        Evaluation.repeat => AppColors.warning,
      };

  IconData get icon => switch (this) {
        Evaluation.excellentPlus => Icons.workspace_premium_rounded,
        Evaluation.excellent => Icons.star_rounded,
        Evaluation.veryGood => Icons.thumb_up_alt_rounded,
        Evaluation.notRecited => Icons.do_not_disturb_on_rounded,
        Evaluation.repeat => Icons.replay_rounded,
      };

  static Evaluation? tryParse(Object? v) {
    for (final e in Evaluation.values) {
      if (e.name == v) return e;
    }
    return null;
  }
}

enum RecitationType {
  @JsonValue('juz')
  juz,
  @JsonValue('surah')
  surah;

  String get label => switch (this) {
        RecitationType.juz => 'جزء',
        RecitationType.surah => 'سورة',
      };
}
