import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/incidents_remote_datasource.dart';
import '../../data/repositories/incidents_repository_impl.dart';
import '../../domain/entities/incident_event.dart';
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

final _incidentsRepositoryProvider = Provider<IncidentsRepositoryImpl>((ref) {
  return IncidentsRepositoryImpl(ref.watch(_incidentsDataSourceProvider));
});

// ── Use cases ────────────────────────────────────────────────────────────────

final submitQuickReportProvider = Provider<SubmitQuickReportUseCase>((ref) {
  return SubmitQuickReportUseCase(ref.watch(_incidentsRepositoryProvider));
});

final submitFormReportProvider = Provider<SubmitFormReportUseCase>((ref) {
  return SubmitFormReportUseCase(ref.watch(_incidentsRepositoryProvider));
});

final submitVoiceReportProvider = Provider<SubmitVoiceReportUseCase>((ref) {
  return SubmitVoiceReportUseCase(ref.watch(_incidentsRepositoryProvider));
});

// ── Stream de incidentes ─────────────────────────────────────────────────────

final incidentsStreamProvider = StreamProvider<List<IncidentEvent>>((ref) {
  return ref.watch(_incidentsRepositoryProvider).watchIncidents();
});

final incidentByIdProvider =
    FutureProvider.family<IncidentEvent, String>((ref, id) {
  return ref.watch(_incidentsRepositoryProvider).getIncidentById(id);
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
    state = await AsyncValue.guard(
      () => _ref.read(submitQuickReportProvider)(
        userId: userId,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }

  Future<void> submitForm({
    required String userId,
    required double latitude,
    required double longitude,
    required String description,
    required IncidentCategory category,
    File? photoFile,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      String? photoUrl;
      if (photoFile != null) {
        photoUrl = await _ref
            .read(_incidentsDataSourceProvider)
            .uploadPhoto(photoFile, userId);
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
    state = await AsyncValue.guard(
      () => _ref.read(submitVoiceReportProvider)(
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        transcribedText: transcribedText,
      ),
    );
  }
}

final reportNotifierProvider =
    StateNotifierProvider<ReportNotifier, AsyncValue<String?>>(
  (ref) => ReportNotifier(ref),
);
