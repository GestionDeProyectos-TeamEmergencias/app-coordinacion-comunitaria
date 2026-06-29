import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../incidents/presentation/providers/incidents_provider.dart';

/// URI de "Cómo llegar" en Google Maps hacia una coordenada. Pública y pura
/// para testearla sin depender del platform view del mapa.
Uri buildDirectionsUri(double lat, double lng) => Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

/// Mini-mapa in-app centrado en la ubicación de un incidente. Se abre desde el
/// detalle (botón "Ver en el mapa") para visualizar el punto en vez de solo
/// mostrar lat/long. Reusa `incidentByIdProvider` para no agregar otra fuente
/// de datos.
class IncidentLocationMapPage extends ConsumerWidget {
  const IncidentLocationMapPage({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentAsync = ref.watch(incidentByIdProvider(incidentId));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.incidentLocationTitle)),
      body: incidentAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incident) {
          final pos = LatLng(incident.latitude, incident.longitude);
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: pos, zoom: 16),
                markers: {
                  Marker(markerId: const MarkerId('incident'), position: pos),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: FilledButton.icon(
                  onPressed: () => launchUrl(
                    buildDirectionsUri(incident.latitude, incident.longitude),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.directions),
                  label: const Text(AppStrings.openInExternalMaps),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
