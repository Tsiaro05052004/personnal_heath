import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/health_facility.dart';
import '../../domain/entities/location_result.dart';
import '../../domain/entities/nearby_search.dart';
import '../mappers/facility_labels.dart';
import '../viewmodels/hospitals_view_model.dart';

/// Contenu de la fiche du bas (maquette 6) : l'établissement choisi, ses
/// actions, puis les autres établissements proches.
class FacilitySheet extends StatelessWidget {
  const FacilitySheet({
    super.key,
    required this.state,
    required this.scrollController,
    required this.onSelect,
    required this.onDirections,
    required this.onCall,
    required this.onLocate,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
  });

  final HospitalsUiState state;
  final ScrollController scrollController;
  final ValueChanged<NearbyFacility> onSelect;
  final ValueChanged<HealthFacility> onDirections;
  final ValueChanged<HealthFacility> onCall;
  final VoidCallback onLocate;
  final VoidCallback onOpenAppSettings;
  final VoidCallback onOpenLocationSettings;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final visible = state.visible;
    final selected = state.selected;
    final search = state.search;

    return Material(
      color: AppColors.surface,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Column(
        children: [
          Expanded(child: _list(context, text, visible, selected, search)),
          // Toujours visible, quelle que soit la hauteur de la fiche
          // (conditions d'OpenStreetMap).
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.outline)),
            ),
            child: Text(
              'Données © contributeurs OpenStreetMap, à vérifier avant de '
              'vous déplacer.',
              style: text.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    TextTheme text,
    List<NearbyFacility> visible,
    NearbyFacility? selected,
    NearbySearch? search,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (state.status == HospitalsStatus.noLocation)
          _LocationPrompt(
            problem: state.locationProblem,
            onLocate: onLocate,
            onOpenAppSettings: onOpenAppSettings,
            onOpenLocationSettings: onOpenLocationSettings,
          ),
        if (state.status == HospitalsStatus.loading && search == null)
          const _Info(
            icon: Icons.search,
            text: 'Recherche des établissements proches…',
            loading: true,
          ),
        if (state.status == HospitalsStatus.error)
          _Info(
            icon: Icons.wifi_off,
            text:
                'Impossible de charger les établissements. Vérifiez votre '
                'connexion Internet.',
            action: ('Réessayer', onLocate),
          ),
        if (search != null && search.fromCache)
          _Info(
            icon: Icons.wifi_off,
            text:
                'Hors connexion : liste enregistrée le '
                '${Formatters.shortDate(search.fetchedAt)}.',
          ),
        if (search != null && search.facilities.isEmpty)
          const _Info(
            icon: Icons.location_off_outlined,
            text: 'Aucun établissement de santé trouvé à proximité.',
          )
        else if (search != null && visible.isEmpty)
          const _Info(
            icon: Icons.search_off,
            text: 'Aucun établissement ne correspond à votre recherche.',
          ),
        if (selected != null) ...[
          _Details(
            facility: selected,
            onDirections: () => onDirections(selected.facility),
            onCall: selected.facility.phone == null
                ? null
                : () => onCall(selected.facility),
          ),
        ],
        if (visible.length > 1) ...[
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text(
              'Autres établissements proches',
              style: text.titleMedium,
            ),
          ),
          const SizedBox(height: 4),
          for (final n in visible.take(30))
            if (n.facility.osmId != selected?.facility.osmId)
              ListTile(
                contentPadding: EdgeInsets.zero,
                minTileHeight: 64,
                leading: Icon(
                  Icons.local_hospital_outlined,
                  color: n.facility.type.isHospital
                      ? AppColors.danger
                      : AppColors.primary,
                ),
                title: Text(n.facility.name, style: text.bodyLarge),
                subtitle: Text(
                  [
                    FacilityLabels.type(n.facility.type),
                    if (n.distanceMeters != null)
                      FacilityLabels.distance(n.distanceMeters!),
                  ].join(' · '),
                ),
                onTap: () => onSelect(n),
              ),
        ],
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.facility,
    required this.onDirections,
    required this.onCall,
  });

  final NearbyFacility facility;
  final VoidCallback onDirections;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final f = facility.facility;
    final subtitle = FacilityLabels.subtitle(facility);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            FacilityLabels.type(f.type),
            style: text.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(header: true, child: Text(f.name, style: text.headlineSmall)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: text.bodyLarge?.copyWith(color: AppColors.textMuted),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onDirections,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.navigation_outlined),
                label: const Text('Itinéraire'),
              ),
            ),
            if (onCall != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCall,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Appeler'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Explique pourquoi la position manque et comment y remédier.
class _LocationPrompt extends StatelessWidget {
  const _LocationPrompt({
    required this.problem,
    required this.onLocate,
    required this.onOpenAppSettings,
    required this.onOpenLocationSettings,
  });

  final LocationProblem? problem;
  final VoidCallback onLocate;
  final VoidCallback onOpenAppSettings;
  final VoidCallback onOpenLocationSettings;

  @override
  Widget build(BuildContext context) => switch (problem) {
    LocationProblem.serviceDisabled => _Info(
      icon: Icons.location_disabled,
      text:
          'La localisation du téléphone est désactivée. Activez-la pour '
          'trouver les établissements proches de vous.',
      action: ('Activer la localisation', onOpenLocationSettings),
    ),
    LocationProblem.permissionDeniedForever => _Info(
      icon: Icons.location_off_outlined,
      text:
          "L'accès à votre position a été refusé. Vous pouvez l'autoriser "
          "dans les réglages de l'application.",
      action: ('Ouvrir les réglages', onOpenAppSettings),
    ),
    LocationProblem.unavailable => _Info(
      icon: Icons.gps_not_fixed,
      text: 'Votre position est introuvable pour le moment.',
      action: ('Réessayer', onLocate),
    ),
    _ => _Info(
      icon: Icons.my_location,
      text:
          'Pour afficher les hôpitaux proches de vous, l’application a '
          'besoin de votre position. Elle ne la garde pas et ne la '
          'partage avec personne.',
      action: ('Autoriser la localisation', onLocate),
    ),
  };
}

class _Info extends StatelessWidget {
  const _Info({
    required this.icon,
    required this.text,
    this.action,
    this.loading = false,
  });

  final IconData icon;
  final String text;
  final (String, VoidCallback)? action;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (loading)
                const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              else
                Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: style)),
            ],
          ),
          if (action case (final label, final onPressed)) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onPressed, child: Text(label)),
          ],
        ],
      ),
    );
  }
}
