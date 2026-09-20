class DashboardState {
  final List<String> userInterests;
  final String selectedCategory;

  const DashboardState({
    required this.userInterests,
    this.selectedCategory = 'General',
  });

  DashboardState copyWith({
    List<String>? userInterests,
    String? selectedCategory,
  }) {
    return DashboardState(
      userInterests: userInterests ?? this.userInterests,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}
