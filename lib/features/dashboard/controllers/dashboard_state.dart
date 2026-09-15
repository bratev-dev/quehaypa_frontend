class DashboardState {
  final List<String> userInterests;
  final String selectedCategory;
  final int revolverRotationOffset;

  const DashboardState({
    required this.userInterests,
    this.selectedCategory = 'General',
    this.revolverRotationOffset = 0,
  });

  DashboardState copyWith({
    List<String>? userInterests,
    String? selectedCategory,
    int? revolverRotationOffset,
  }) {
    return DashboardState(
      userInterests: userInterests ?? this.userInterests,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      revolverRotationOffset:
          revolverRotationOffset ?? this.revolverRotationOffset,
    );
  }
}
