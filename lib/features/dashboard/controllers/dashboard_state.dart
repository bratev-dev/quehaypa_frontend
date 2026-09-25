import '../data/mocked_events.dart';

class DashboardState {
  final List<String> userInterests;
  final String selectedCategory;
  final List<MockedEvent> visibleEvents;

  const DashboardState({
    required this.userInterests,
    this.selectedCategory = 'General',
    this.visibleEvents = kMockedEvents,
  });

  DashboardState copyWith({
    List<String>? userInterests,
    String? selectedCategory,
    List<MockedEvent>? visibleEvents,
  }) {
    return DashboardState(
      userInterests: userInterests ?? this.userInterests,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      visibleEvents: visibleEvents ?? this.visibleEvents,
    );
  }
}
