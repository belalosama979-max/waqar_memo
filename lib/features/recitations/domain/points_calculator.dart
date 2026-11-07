import 'evaluation.dart';
import 'evaluation_settings.dart';

/// Result of a session points calculation.
class SessionPoints {
  const SessionPoints({required this.evaluationPoints, required this.extraPoints});

  final int evaluationPoints;
  final int extraPoints;

  int get total => evaluationPoints + extraPoints;
}

/// Pure business rule: Total Session Points = Evaluation Points + Extra Points.
abstract final class PointsCalculator {
  static SessionPoints calculate({
    required Evaluation? evaluation,
    required int extraPoints,
    required EvaluationSettings settings,
  }) {
    if (extraPoints < 0) {
      throw ArgumentError.value(extraPoints, 'extraPoints', 'must not be negative');
    }
    if (extraPoints > settings.maxExtraPoints) {
      throw ArgumentError.value(extraPoints, 'extraPoints', 'exceeds ${settings.maxExtraPoints}');
    }
    final evalPoints = evaluation == null ? 0 : settings.pointsFor(evaluation);
    return SessionPoints(evaluationPoints: evalPoints, extraPoints: extraPoints);
  }
}
