import '../../domain/entities/plan.dart';

enum PlansStatus { initial, loading, success, error }

class PlansState {
  final PlansStatus status;
  final List<Plan> plans;
  final String? errorMessage;

  const PlansState({
    this.status = PlansStatus.initial,
    this.plans = const [],
    this.errorMessage,
  });

  PlansState copyWith({
    PlansStatus? status,
    List<Plan>? plans,
    String? errorMessage,
  }) {
    return PlansState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      errorMessage: errorMessage,
    );
  }
}
