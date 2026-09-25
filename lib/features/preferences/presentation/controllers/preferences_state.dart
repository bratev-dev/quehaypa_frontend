/// Estado del catalogo de intereses + preferencias del usuario.
enum PreferencesStatus { initial, loading, success, error }

class PreferencesState {
  final PreferencesStatus status;
  final List<String> catalog;
  final List<String> mine;
  final String? errorMessage;

  const PreferencesState({
    this.status = PreferencesStatus.initial,
    this.catalog = const [],
    this.mine = const [],
    this.errorMessage,
  });

  PreferencesState copyWith({
    PreferencesStatus? status,
    List<String>? catalog,
    List<String>? mine,
    String? errorMessage,
  }) {
    return PreferencesState(
      status: status ?? this.status,
      catalog: catalog ?? this.catalog,
      mine: mine ?? this.mine,
      errorMessage: errorMessage,
    );
  }
}
