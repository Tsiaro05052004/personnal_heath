import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/hospitals_providers.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/health_facility.dart';
import '../../domain/entities/location_result.dart';
import '../../domain/entities/nearby_search.dart';
import '../../domain/services/facility_search.dart';

/// Où en est l'écran.
enum HospitalsStatus {
  /// Recherche de la position ou des établissements.
  loading,
  ready,

  /// Position indisponible (voir [HospitalsUiState.locationProblem]).
  noLocation,

  /// Ni réseau ni liste enregistrée.
  error,
}

class HospitalsUiState {
  const HospitalsUiState({
    this.status = HospitalsStatus.loading,
    this.position,
    this.locationProblem,
    this.search,
    this.filter = FacilityFilter.all,
    this.query = '',
    this.selectedId,
  });

  final HospitalsStatus status;
  final GeoPoint? position;
  final LocationProblem? locationProblem;

  /// Établissements trouvés (ou la dernière liste enregistrée).
  final NearbySearch? search;
  final FacilityFilter filter;
  final String query;
  final String? selectedId;

  /// Établissements affichés, du plus proche au plus lointain.
  List<NearbyFacility> get visible => FacilitySearch.apply(
    facilities: search?.facilities ?? const [],
    from: position,
    filter: filter,
    query: query,
  );

  /// Établissement de la fiche : celui choisi, sinon le plus proche.
  NearbyFacility? get selected {
    final list = visible;
    if (list.isEmpty) return null;
    return list.where((n) => n.facility.osmId == selectedId).firstOrNull ??
        list.first;
  }

  HospitalsUiState copyWith({
    HospitalsStatus? status,
    GeoPoint? position,
    LocationProblem? Function()? locationProblem,
    NearbySearch? search,
    FacilityFilter? filter,
    String? query,
    String? Function()? selectedId,
  }) => HospitalsUiState(
    status: status ?? this.status,
    position: position ?? this.position,
    locationProblem: locationProblem != null
        ? locationProblem()
        : this.locationProblem,
    search: search ?? this.search,
    filter: filter ?? this.filter,
    query: query ?? this.query,
    selectedId: selectedId != null ? selectedId() : this.selectedId,
  );
}

final hospitalsViewModelProvider =
    NotifierProvider<HospitalsViewModel, HospitalsUiState>(
      HospitalsViewModel.new,
    );

/// ViewModel de la carte : position, établissements proches, filtres,
/// recherche et établissement choisi.
class HospitalsViewModel extends Notifier<HospitalsUiState> {
  @override
  HospitalsUiState build() {
    // Premier chargement sans rien demander : l'autorisation est demandée
    // après explication, par un bouton.
    Future.microtask(() => _load(request: false));
    return const HospitalsUiState();
  }

  /// « Autoriser la localisation » / « Réessayer » / bouton recentrer.
  Future<void> locate() => _load(request: true);

  Future<void> _load({required bool request}) async {
    state = state.copyWith(status: HospitalsStatus.loading);
    final gateway = ref.read(locationGatewayProvider);
    final location = request
        ? await gateway.requestAndLocate()
        : await gateway.currentPosition();

    final position = location.position;
    if (position == null) {
      // Sans position : on montre au moins la dernière liste connue.
      final cached = await ref.read(getCachedFacilitiesProvider)();
      state = state.copyWith(
        status: HospitalsStatus.noLocation,
        locationProblem: () => location.problem,
        search: cached,
      );
      return;
    }

    state = state.copyWith(position: position, locationProblem: () => null);
    try {
      final search = await ref.read(findNearbyFacilitiesProvider)(position);
      state = state.copyWith(
        status: HospitalsStatus.ready,
        search: search,
        selectedId: () => null,
      );
    } catch (_) {
      state = state.copyWith(status: HospitalsStatus.error);
    }
  }

  Future<void> openAppSettings() =>
      ref.read(locationGatewayProvider).openAppSettings();

  Future<void> openLocationSettings() =>
      ref.read(locationGatewayProvider).openLocationSettings();

  void setFilter(FacilityFilter filter) =>
      state = state.copyWith(filter: filter, selectedId: () => null);

  void setQuery(String query) =>
      state = state.copyWith(query: query, selectedId: () => null);

  void select(String osmId) => state = state.copyWith(selectedId: () => osmId);
}
