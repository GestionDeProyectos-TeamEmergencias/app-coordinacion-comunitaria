import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../incidents/domain/entities/incident_event.dart';
import '../../../incidents/presentation/providers/incidents_provider.dart';

// RF-ADM-01: mapa de incidencias geolocalizado con marcadores por prioridad. [T-REP-05]
class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  // Centro inicial en Argentina (se centrará en el área de cobertura real).
  static const _initialPosition = CameraPosition(
    target: LatLng(-34.6037, -58.3816), // Buenos Aires
    zoom: 13,
  );

  Set<Marker> _buildMarkers(List<IncidentEvent> incidents) {
    return incidents.map((incident) {
      final color = incident.priority == null
          ? BitmapDescriptor.hueAzure
          : switch (incident.priority!) {
              IncidentPriority.urgente => BitmapDescriptor.hueRed,
              IncidentPriority.alta => BitmapDescriptor.hueOrange,
              IncidentPriority.media => BitmapDescriptor.hueYellow,
              IncidentPriority.baja => BitmapDescriptor.hueGreen,
            };

      return Marker(
        markerId:
            MarkerId(incident.eventId ?? incident.timestamp.toIso8601String()),
        position: LatLng(incident.latitude, incident.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(color),
        infoWindow: InfoWindow(
          title: incident.category?.displayName ?? 'Incidente',
          snippet: incident.description ?? incident.status.displayName,
          onTap: incident.eventId != null
              ? () =>
                  context.go(AppRoutes.incidentDetailPath(incident.eventId!))
              : null,
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(incidentsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.mapTitle)),
      body: incidentsAsync.when(
        loading: () => const AppLoading(message: 'Cargando mapa...'),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incidents) => GoogleMap(
          initialCameraPosition: _initialPosition,
          markers: _buildMarkers(incidents),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        ),
      ),
      // Leyenda de colores
      floatingActionButton: _LegendButton(),
    );
  }
}

class _LegendButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        builder: (_) => const _LegendSheet(),
      ),
      icon: const Icon(Icons.info_outline),
      label: const Text('Leyenda'),
    );
  }
}

class _LegendSheet extends StatelessWidget {
  const _LegendSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Colores por prioridad',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const _LegendItem(color: AppColors.priorityUrgent, label: 'Urgente'),
          const _LegendItem(color: AppColors.priorityHigh, label: 'Alta'),
          const _LegendItem(color: AppColors.priorityMedium, label: 'Media'),
          const _LegendItem(color: AppColors.priorityLow, label: 'Baja'),
          const _LegendItem(color: Colors.blue, label: 'Sin clasificar'),
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
