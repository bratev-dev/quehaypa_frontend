/// Estado del catálogo de intereses recibido de la API.
enum PreferencesStatus { initial, loading, success, error }

class PreferencesState {
  final PreferencesStatus status;
  final List<String> catalog;
  final String? errorMessage;

  const PreferencesState({
    this.status = PreferencesStatus.initial,
    this.catalog = const [],
    this.errorMessage,
  });

  PreferencesState copyWith({
    PreferencesStatus? status,
    List<String>? catalog,
    String? errorMessage,
  }) {
    return PreferencesState(
      status: status ?? this.status,
      catalog: catalog ?? this.catalog,
      errorMessage: errorMessage,
    );
  }
}
