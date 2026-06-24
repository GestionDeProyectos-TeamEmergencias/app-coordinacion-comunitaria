import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../admin/presentation/providers/coverage_config_provider.dart';

import '../../data/datasources/incidents_remote_datasource.dart';
import '../../data/repositories/incidents_repository_impl.dart';
import '../../domain/entities/incident_event.dart';
import '../../domain/repositories/incidents_repository.dart';
import '../../domain/usecases/submit_form_report_usecase.dart';
import '../../domain/usecases/submit_quick_report_usecase.dart';
import '../../domain/usecases/submit_voice_report_usecase.dart';

// ── Infraestructura ─────────────────────────────────────────────────────────

final _incidentsDataSourceProvider = Provider<IncidentsRemoteDataSource>((ref) {
  return IncidentsRemoteDataSource(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
});

final incidentsRepositoryProvider = Provider<IncidentsRepository>((ref) {
  return IncidentsRepositoryImpl(ref.watch(_incidentsDataSourceProvider));
});

// ── Use cases ────────────────────────────────────────────────────────────────

final submitQuickReportProvider = Provider<SubmitQuickReportUseCase>((ref) {
  return SubmitQuickReportUseCase(ref.watch(incidentsRepositoryProvider));
});

final submitFormReportProvider = Provider<SubmitFormReportUseCase>((ref) {
  return SubmitFormReportUseCase(ref.watch(incidentsRepositoryProvider));
});

final submitVoiceReportProvider = Provider<SubmitVoiceReportUseCase>((ref) {
  return SubmitVoiceReportUseCase(ref.watch(incidentsRepositoryProvider));
});

// ── Stream de incidentes ─────────────────────────────────────────────────────

// Stream del "mapa del barrio" (SRS §3.1.1): incidents públicos activos del
// barrio, sin sancionados (`falso`) ni descartados (`rechazado_fuera_de_cobertura`)
// ni solucionados. Es la única vista pública del MVP — el historial completo
// queda para F-01 (Mis reportes). [D-02]
final activeIncidentsStreamProvider =
    StreamProvider<List<IncidentEvent>>((ref) {
  return ref.watch(incidentsRepositoryProvider).watchActiveIncidents();
});

final incidentByIdProvider =
    StreamProvider.family<IncidentEvent, String>((ref, id) {
  return ref.watch(incidentsRepositoryProvider).watchIncidentById(id);
});

// ── Notifier para envío de reportes ─────────────────────────────────────────

class ReportNotifier extends StateNotifier<AsyncValue<String?>> {
  ReportNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> submitQuick({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final config = await _ref.read(coverageConfigProvider.future);
      if (!config.isWithinCoverage(latitude, longitude)) {
        throw const OutOfCoverageException();
      }
      return _ref.read(submitQuickReportProvider)(
        userId: userId,
        latitude: latitude,
        longitude: longitude,
      );
    });
  }

  Future<void> submitForm({
    required String userId,
    required double latitude,
    required double longitude,
    required String description,
    required IncidentCategory category,
    Uint8List? photoBytes,
    String? photoName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final config = await _ref.read(coverageConfigProvider.future);
      if (!config.isWithinCoverage(latitude, longitude)) {
        throw const OutOfCoverageException();
      }
      String? photoUrl;
      if (photoBytes != null) {
        photoUrl = await _ref.read(_incidentsDataSourceProvider).uploadPhoto(
              photoBytes,
              photoName ?? 'photo.jpg',
              userId,
            );
      }
      return _ref.read(submitFormReportProvider)(
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        description: description,
        category: category,
        photoUrl: photoUrl,
      );
    });
  }

  Future<void> submitVoice({
    required String userId,
    required double latitude,
    required double longitude,
    required String transcribedText,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final config = await _ref.read(coverageConfigProvider.future);
      if (!config.isWithinCoverage(latitude, longitude)) {
        throw const OutOfCoverageException();
      }
      return _ref.read(submitVoiceReportProvider)(
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        transcribedText: transcribedText,
      );
    });
  }
}

final reportNotifierProvider =
    StateNotifierProvider<ReportNotifier, AsyncValue<String?>>(
  (ref) => ReportNotifier(ref),
);

// ── Notifier para actualizar estado de incidente [T-REP-06] ────────────────

class UpdateStatusNotifier extends StateNotifier<AsyncValue<void>> {
  UpdateStatusNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> update({
    required String eventId,
    required IncidentStatus status,
    String? changedBy,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(incidentsRepositoryProvider).updateStatus(
            eventId,
            status,
            changedBy: changedBy,
          ),
    );
  }
}

final updateStatusNotifierProvider =
    StateNotifierProvider<UpdateStatusNotifier, AsyncValue<void>>(
  (ref) => UpdateStatusNotifier(ref),
);
