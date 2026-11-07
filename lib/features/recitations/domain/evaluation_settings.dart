import 'evaluation.dart';

/// Admin-configurable evaluation points, stored at `evaluation_settings/default`:
/// `{ points: { excellentPlus: 60, ... }, maxExtraPoints: 100 }`.
class EvaluationSettings {
  const EvaluationSettings({required this.points, this.maxExtraPoints = 100});

  factory EvaluationSettings.defaults() => EvaluationSettings(
        points: {for (final e in Evaluation.values) e: e.defaultPoints},
      );

  factory EvaluationSettings.fromMap(Map<String, dynamic>? data) {
    final defaults = EvaluationSettings.defaults();
    if (data == null) return defaults;
    final raw = (data['points'] as Map?)?.cast<String, dynamic>() ?? const {};
    return EvaluationSettings(
      points: {
        for (final e in Evaluation.values)
          e: (raw[e.name] is num) ? (raw[e.name] as num).toInt() : defaults.points[e]!,
      },
      maxExtraPoints: (data['maxExtraPoints'] is num) ? (data['maxExtraPoints'] as num).toInt() : 100,
    );
  }

  final Map<Evaluation, int> points;
  final int maxExtraPoints;

  int pointsFor(Evaluation e) => points[e] ?? e.defaultPoints;

  Map<String, dynamic> toMap() => {
        'points': {for (final e in Evaluation.values) e.name: pointsFor(e)},
        'maxExtraPoints': maxExtraPoints,
      };

  EvaluationSettings copyWith({Map<Evaluation, int>? points, int? maxExtraPoints}) => EvaluationSettings(
        points: points ?? this.points,
        maxExtraPoints: maxExtraPoints ?? this.maxExtraPoints,
      );
}
