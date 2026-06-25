import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/incident_event.dart';
import 'incidents_provider.dart';

/// Stream de los incidents propios del user actual, ordenados por fecha desc.
/// Sin filtro de status: incluye recibidos, programados, solucionados, falsos,
/// rechazados, etc. — es el historial completo. [F-01]
///
/// Si el user no está logueado, emite lista vacía.
final myIncidentsStreamProvider = StreamProvider<List<IncidentEvent>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref.watch(incidentsRepositoryProvider).watchMyIncidents(user.userId);
});

/// Notifier que persiste cambios al draft de un reporte propio.
/// Las reglas Firestore validan que el caller es dueño activo y que el
/// incident sigue en `recibido`. [F-01]
class EditOwnIncidentNotifier extends StateNotifier<AsyncValue<void>> {
  EditOwnIncidentNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> save({
    required String eventId,
    required String ownerUid,
    String? description,
    IncidentCategory? category,
    Uint8List? newPhotoBytes,
    String? newPhotoName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(incidentsRepositoryProvider);
      String? photoUrl;
      if (newPhotoBytes != null) {
        photoUrl = await repo.uploadPhoto(
          newPhotoBytes,
          newPhotoName ?? 'photo.jpg',
          ownerUid,
        );
      }
      await repo.updateOwnIncidentDraft(
        eventId,
        description: description,
        category: category,
        photoUrl: photoUrl,
      );
    });
  }
}

final editOwnIncidentNotifierProvider =
    StateNotifierProvider<EditOwnIncidentNotifier, AsyncValue<void>>(
  (ref) => EditOwnIncidentNotifier(ref),
);
