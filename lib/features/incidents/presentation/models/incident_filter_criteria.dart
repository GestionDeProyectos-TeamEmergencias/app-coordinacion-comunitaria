import '../../domain/entities/incident_event.dart';

enum IncidentSortOption {
  newest,
  oldest,
}

extension IncidentSortOptionX on IncidentSortOption {
  String get displayName {
    return switch (this) {
      IncidentSortOption.newest => 'Más reciente primero',
      IncidentSortOption.oldest => 'Más antiguo primero',
    };
  }
}

class IncidentFilterCriteria {
  final IncidentPriority? priority;
  final IncidentStatus? status;
  final bool onlyVerified;
  final IncidentSortOption sortBy;

  const IncidentFilterCriteria({
    this.priority,
    this.status,
    this.onlyVerified = false,
    this.sortBy = IncidentSortOption.newest,
  });

  IncidentFilterCriteria copyWith({
    IncidentPriority? priority,
    bool clearPriority = false,
    IncidentStatus? status,
    bool clearStatus = false,
    bool? onlyVerified,
    IncidentSortOption? sortBy,
  }) {
    return IncidentFilterCriteria(
      priority: clearPriority ? null : (priority ?? this.priority),
      status: clearStatus ? null : (status ?? this.status),
      onlyVerified: onlyVerified ?? this.onlyVerified,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  int get activeFiltersCount {
    int count = 0;
    if (priority != null) count++;
    if (status != null) count++;
    if (onlyVerified) count++;
    // Omitimos sortBy del conteo visual porque ordenar no 'filtra' contenido.
    return count;
  }
}
