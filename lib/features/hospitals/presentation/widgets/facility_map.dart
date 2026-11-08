import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/health_facility.dart';
import '../mappers/facility_labels.dart';

/// Antananarivo, quand on ne sait rien de la position.
const defaultMapCenter = GeoPoint(-18.8792, 47.5079);

LatLng toLatLng(GeoPoint p) => LatLng(p.latitude, p.longitude);

/// Carte OpenStreetMap : position de l'utilisateur et établissements.
class FacilityMap extends StatelessWidget {
  const FacilityMap({
    super.key,
    required this.controller,
    required this.center,
    required this.position,
    required this.facilities,
    required this.selectedId,
    required this.onSelect,
    required this.showTiles,
    this.onReady,
  });

  final MapController controller;
  final GeoPoint center;
  final GeoPoint? position;
  final List<NearbyFacility> facilities;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  /// Tuiles réseau (désactivées dans les tests).
  final bool showTiles;
  final VoidCallback? onReady;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: toLatLng(center),
        initialZoom: 14,
        minZoom: 5,
        maxZoom: 18,
        backgroundColor: const Color(0xFFEDE8DF),
        onMapReady: onReady,
        interactionOptions: const InteractionOptions(
          // Pas de rotation : déroutant pour des personnes âgées.
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        if (showTiles)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.personnal_heath',
          ),
        MarkerLayer(
          markers: [
            for (final n in facilities)
              if (n.facility.osmId != selectedId)
                _facilityMarker(n.facility, selected: false),
            if (position != null)
              Marker(
                point: toLatLng(position!),
                width: 44,
                height: 44,
                child: const _UserDot(),
              ),
            // L'établissement choisi est dessiné en dernier (au-dessus).
            for (final n in facilities)
              if (n.facility.osmId == selectedId)
                _facilityMarker(n.facility, selected: true),
          ],
        ),
      ],
    );
  }

  Marker _facilityMarker(HealthFacility f, {required bool selected}) {
    final size = selected ? 56.0 : 44.0;
    return Marker(
      point: toLatLng(f.location),
      width: size,
      height: size,
      child: Semantics(
        button: true,
        label: '${FacilityLabels.type(f.type)} ${f.name}',
        child: GestureDetector(
          onTap: () => onSelect(f.osmId),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.danger,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6),
              ],
            ),
            child: Icon(Icons.add, color: Colors.white, size: size * 0.55),
          ),
        ),
      ),
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Votre position',
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.water.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.water,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.white, width: 3),
        ),
      ),
    ),
  );
}
