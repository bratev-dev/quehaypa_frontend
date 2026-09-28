import '../../preferences/domain/entities/event_seed.dart';

enum DashboardStatus { initial, loading, success, error }

class DashboardState {
  final List<String> userInterests;
  final String selectedCategory;
  final List<EventSeed> visibleEvents;
  final DashboardStatus status;
  final String? errorMessage;

  const DashboardState({
    this.userInterests = const [],
    this.selectedCategory = 'General',
    this.visibleEvents = const [],
    this.status = DashboardStatus.initial,
    this.errorMessage,
  });

  DashboardState copyWith({
    List<String>? userInterests,
    String? selectedCategory,
    List<EventSeed>? visibleEvents,
    DashboardStatus? status,
    String? errorMessage,
  }) => DashboardState(
    userInterests: userInterests ?? this.userInterests,
    selectedCategory: selectedCategory ?? this.selectedCategory,
    visibleEvents: visibleEvents ?? this.visibleEvents,
    status: status ?? this.status,
    errorMessage:
        errorMessage ??
        (status == DashboardStatus.loading || status == DashboardStatus.success
            ? null
            : this.errorMessage),
  );
}
