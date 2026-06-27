import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/router.dart';
import '../../../../core/config/coverage_area.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../admin/presentation/providers/coverage_config_provider.dart';
import '../../../incidents/domain/entities/incident_event.dart';
import '../../../incidents/presentation/providers/incidents_provider.dart';

// RF-ADM-01: mapa de incidencias geolocalizado con marcadores por prioridad y categoría. [T-REP-05]
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? _controller;
  final Set<IncidentCategory> _activeCategories =
      IncidentCategory.values.toSet();

  Set<Marker> _buildMarkers(List<IncidentEvent> incidents) {
    final filtered = incidents.where((i) {
      if (i.category == null) return true;
      return _activeCategories.contains(i.category);
    });
    return filtered.map((incident) {
      final hue = incident.priority == null
          ? BitmapDescriptor.hueAzure
          : switch (incident.priority!) {
              IncidentPriority.urgente => BitmapDescriptor.hueRed,
              IncidentPriority.alta => BitmapDescriptor.hueOrange,
              IncidentPriority.media => BitmapDescriptor.hueYellow,
              IncidentPriority.baja => BitmapDescriptor.hueGreen,
            };

      final categoryLabel = incident.category != null
          ? '${incident.category!.emoji} ${incident.category!.displayName}'
          : AppStrings.mapDefaultCategory;
      final priorityLabel = incident.priority?.displayName ?? '';
      final snippet = [
        if (priorityLabel.isNotEmpty) 'Prioridad: $priorityLabel',
        incident.description ?? incident.status.displayName,
      ].join(' · ');

      return Marker(
        markerId:
            MarkerId(incident.eventId ?? incident.timestamp.toIso8601String()),
        position: LatLng(incident.latitude, incident.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        infoWindow: InfoWindow(
          title: categoryLabel,
          snippet: snippet,
          onTap: incident.eventId != null
              ? () =>
                  context.go(AppRoutes.incidentDetailPath(incident.eventId!))
              : null,
        ),
      );
    }).toSet();
  }

  Set<Circle> _buildCoverageCircle(LatLng center, double radius) => {
        Circle(
          circleId: const CircleId('coverage'),
          center: center,
          radius: radius,
          strokeColor: AppColors.primary,
          strokeWidth: 2,
          fillColor: AppColors.primary.withValues(alpha: 0.08),
        ),
      };

  // Dibuja el polígono de cobertura cuando está configurado. Reemplaza al
  // círculo para que el área mostrada coincida con la que valida. [F-07]
  Set<Polygon> _buildCoveragePolygon(List<LatLng> points) => {
        Polygon(
          polygonId: const PolygonId('coverage'),
          points: points,
          strokeColor: AppColors.primary,
          strokeWidth: 2,
          fillColor: AppColors.primary.withValues(alpha: 0.08),
        ),
      };

  Future<void> _recenter(LatLng center) async {
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: center, zoom: CoverageArea.initialZoom),
      ),
    );
  }

  void _toggleCategory(IncidentCategory category) {
    setState(() {
      if (_activeCategories.contains(category)) {
        _activeCategories.remove(category);
      } else {
        _activeCategories.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(activeIncidentsStreamProvider);
    final coverageAsync = ref.watch(coverageConfigProvider);
    final config = coverageAsync.valueOrNull;

    final center = config != null
        ? LatLng(config.centerLat, config.centerLng)
        : CoverageArea.center;
    final radius = config?.radiusMeters ?? CoverageArea.radiusMeters;

    // Si hay polígono configurado, se dibuja el polígono; si no, el círculo.
    // [F-07]
    final usesPolygon = config?.usesPolygon ?? false;
    final polygonPoints = usesPolygon
        ? config!.polygonPoints!.map((p) => LatLng(p.lat, p.lng)).toList()
        : const <LatLng>[];

    final initialPos = CameraPosition(
      target: center,
      zoom: CoverageArea.initialZoom,
    );

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.mapTitle)),
      body: incidentsAsync.when(
        loading: () => const AppLoading(message: AppStrings.loadingMap),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incidents) => Stack(
          children: [
            GoogleMap(
              initialCameraPosition: initialPos,
              markers: _buildMarkers(incidents),
              circles:
                  usesPolygon ? const {} : _buildCoverageCircle(center, radius),
              polygons:
                  usesPolygon ? _buildCoveragePolygon(polygonPoints) : const {},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (c) => _controller = c,
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: _CategoryFilterBar(
                active: _activeCategories,
                onToggle: _toggleCategory,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FloatingActionButton.small(
            heroTag: 'recenter',
            tooltip: AppStrings.mapRecenter,
            onPressed: () => _recenter(center),
            child: const Icon(Icons.center_focus_strong),
          ),
          const SizedBox(height: 8),
          _LegendButton(),
        ],
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({required this.active, required this.onToggle});

  final Set<IncidentCategory> active;
  final ValueChanged<IncidentCategory> onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: IncidentCategory.values.map((c) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text('${c.emoji} ${c.displayName}'),
                  selected: active.contains(c),
                  onSelected: (_) => onToggle(c),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _LegendButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'legend',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        builder: (_) => const _LegendSheet(),
      ),
      icon: const Icon(Icons.info_outline),
      label: const Text(AppStrings.mapLegend),
    );
  }
}

class _LegendSheet extends StatelessWidget {
  const _LegendSheet();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.mapLegendTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const _LegendItem(
              color: AppColors.priorityUrgent,
              label: AppStrings.priorityUrgent),
          const _LegendItem(
              color: AppColors.priorityHigh, label: AppStrings.priorityHigh),
          const _LegendItem(
              color: AppColors.priorityMedium,
              label: AppStrings.priorityMedium),
          const _LegendItem(
              color: AppColors.priorityLow, label: AppStrings.priorityLow),
          const _LegendItem(
              color: Colors.blue, label: AppStrings.mapNoPriority),
          const Divider(height: 24),
          Text(AppStrings.mapCategoryFilters,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...IncidentCategory.values.map(
            (c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${c.emoji}  ${c.displayName}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
