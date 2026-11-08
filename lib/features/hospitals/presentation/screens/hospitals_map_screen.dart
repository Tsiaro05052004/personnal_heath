import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/external_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../di/hospitals_providers.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/health_facility.dart';
import '../../domain/services/facility_search.dart';
import '../viewmodels/hospitals_view_model.dart';
import '../widgets/facility_map.dart';
import '../widgets/facility_sheet.dart';

/// Onglet « Hôpitaux » (maquette 6) : carte, recherche, filtres et fiche
/// de l'établissement choisi.
class HospitalsMapScreen extends ConsumerStatefulWidget {
  const HospitalsMapScreen({super.key});

  @override
  ConsumerState<HospitalsMapScreen> createState() => _HospitalsMapScreenState();
}

class _HospitalsMapScreenState extends ConsumerState<HospitalsMapScreen> {
  final _map = MapController();
  bool _mapReady = false;

  /// Part de l'écran occupée par la fiche (pour placer le bouton
  /// « recentrer » juste au-dessus).
  double _sheetExtent = _sheetInitial;
  static const _sheetMin = 0.22;
  // Assez haut pour voir « Itinéraire » / « Appeler » sur un écran de
  // 360 × 800 dp.
  static const _sheetInitial = 0.52;

  HospitalsViewModel get _vm => ref.read(hospitalsViewModelProvider.notifier);

  void _moveTo(GeoPoint point) {
    if (_mapReady) _map.move(toLatLng(point), 15);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hospitalsViewModelProvider);

    // Centre la carte quand la position arrive (ou change).
    ref.listen(hospitalsViewModelProvider.select((s) => s.position), (
      _,
      position,
    ) {
      if (position != null) _moveTo(position);
    });

    final visible = state.visible;
    final center =
        state.position ??
        (visible.isEmpty ? null : visible.first.facility.location) ??
        defaultMapCenter;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Positioned.fill(
              child: FacilityMap(
                controller: _map,
                center: center,
                position: state.position,
                facilities: visible,
                selectedId: state.selected?.facility.osmId,
                onSelect: _vm.select,
                showTiles: ref.watch(mapTilesEnabledProvider),
                onReady: () => _mapReady = true,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SearchField(onChanged: _vm.setQuery),
                    const SizedBox(height: 12),
                    _FilterChips(
                      selected: state.filter,
                      onSelected: _vm.setFilter,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: constraints.maxHeight * _sheetExtent + 16,
              child: _RecenterButton(
                onPressed: () {
                  final position = state.position;
                  if (position != null) _moveTo(position);
                  _vm.locate();
                },
              ),
            ),
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (n) {
                setState(() => _sheetExtent = n.extent);
                return false;
              },
              child: DraggableScrollableSheet(
                minChildSize: _sheetMin,
                initialChildSize: _sheetInitial,
                maxChildSize: 0.88,
                builder: (context, scroll) => FacilitySheet(
                  state: state,
                  scrollController: scroll,
                  onSelect: (n) {
                    _vm.select(n.facility.osmId);
                    _moveTo(n.facility.location);
                    // Remonte en haut de la fiche : on voit l'établissement choisi.
                    scroll.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  onDirections: _directions,
                  onCall: _call,
                  onLocate: _vm.locate,
                  onOpenAppSettings: _vm.openAppSettings,
                  onOpenLocationSettings: _vm.openLocationSettings,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvre l'application GPS du téléphone vers l'établissement.
  Future<void> _directions(HealthFacility f) async {
    final launcher = ref.read(externalLauncherProvider);
    final lat = f.location.latitude, lon = f.location.longitude;
    final opened =
        await launcher.open(
          Uri.parse(
            'geo:$lat,$lon?q=$lat,$lon(${Uri.encodeComponent(f.name)})',
          ),
        ) ||
        await launcher.open(
          Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon',
          ),
        );
    if (!opened) _snack("Aucune application d'itinéraire n'est disponible.");
  }

  Future<void> _call(HealthFacility f) async {
    final phone = f.phone!.replaceAll(RegExp(r'[^0-9+]'), '');
    // « tel: » ouvre le composeur : l'utilisateur appuie lui-même sur
    // « Appeler » (pas d'appel par erreur).
    final opened = await ref
        .read(externalLauncherProvider)
        .open(Uri(scheme: 'tel', path: phone));
    if (!opened) _snack('Impossible d’ouvrir le téléphone.');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 3,
    shadowColor: Colors.black26,
    borderRadius: BorderRadius.circular(20),
    child: TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Hôpital, clinique ou quartier',
        prefixIcon: const Icon(Icons.search, size: 28),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final FacilityFilter selected;
  final ValueChanged<FacilityFilter> onSelected;

  static const _labels = {
    FacilityFilter.all: 'Tous',
    FacilityFilter.hospitals: 'Hôpitaux',
    FacilityFilter.clinics: 'Cliniques',
  };

  @override
  // Défilement horizontal : les filtres restent sur une ligne et ne
  // cachent pas la carte, même sur un petit écran.
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    clipBehavior: Clip.none,
    child: Row(
      spacing: 8,
      children: [
        for (final MapEntry(key: filter, value: label) in _labels.entries)
          Semantics(
            selected: filter == selected,
            button: true,
            child: Material(
              color: filter == selected ? AppColors.text : AppColors.surface,
              elevation: 2,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onSelected(filter),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: filter == selected ? Colors.white : AppColors.text,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filled(
    onPressed: onPressed,
    tooltip: 'Me localiser',
    style: IconButton.styleFrom(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.water,
      minimumSize: const Size(60, 60),
      elevation: 4,
    ),
    icon: const Icon(Icons.my_location, size: 30),
  );
}
