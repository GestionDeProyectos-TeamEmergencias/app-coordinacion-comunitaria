import 'package:app_coordinacion_comunitaria/features/incidents/data/datasources/incidents_remote_datasource.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/data/models/incident_event_model.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/data/repositories/incidents_repository_impl.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIncidentsRemoteDataSource extends Mock
    implements IncidentsRemoteDataSource {}

IncidentEventModel _makeModel({required String id, required String status}) =>
    IncidentEventModel(
      eventId: id,
      userId: 'uid',
      timestamp: DateTime(2025),
      latitude: -34.6,
      longitude: -58.3,
      sourceType: 'quick',
      status: status,
    );

void main() {
  late MockIncidentsRemoteDataSource mockDs;
  late IncidentsRepositoryImpl repo;

  setUp(() {
    mockDs = MockIncidentsRemoteDataSource();
    repo = IncidentsRepositoryImpl(mockDs);
  });

  group('IncidentsRepositoryImpl.watchActiveIncidents', () {
    test('excluye incidentes con estado solucionado', () async {
      when(() => mockDs.watchIncidents()).thenAnswer(
        (_) => Stream.value([
          _makeModel(id: '1', status: 'recibido'),
          _makeModel(id: '2', status: 'solucionado'),
          _makeModel(id: '3', status: 'en_reparacion'),
        ]),
      );

      final result = await repo.watchActiveIncidents().first;

      expect(result.length, 2);
      expect(
        result.every((i) => i.status != IncidentStatus.solucionado),
        isTrue,
      );
    });

    test('retorna lista vacía si todos los incidentes están solucionados',
        () async {
      when(() => mockDs.watchIncidents()).thenAnswer(
        (_) => Stream.value([
          _makeModel(id: '1', status: 'solucionado'),
        ]),
      );

      final result = await repo.watchActiveIncidents().first;

      expect(result, isEmpty);
    });

    test('retorna todos si ninguno está solucionado', () async {
      when(() => mockDs.watchIncidents()).thenAnswer(
        (_) => Stream.value([
          _makeModel(id: '1', status: 'recibido'),
          _makeModel(id: '2', status: 'programado'),
        ]),
      );

      final result = await repo.watchActiveIncidents().first;

      expect(result.length, 2);
    });

    // El "mapa del barrio" (D-02) muestra incidents públicos activos. Los
    // marcados `falso` o `rechazado_fuera_de_cobertura` son ruido o sanción de
    // moderación: aunque la regla Firestore permita leerlos, el cliente los
    // excluye de la lista pública.
    test('excluye incidentes falsos y fuera de cobertura', () async {
      when(() => mockDs.watchIncidents()).thenAnswer(
        (_) => Stream.value([
          _makeModel(id: '1', status: 'recibido'),
          _makeModel(id: '2', status: 'falso'),
          _makeModel(id: '3', status: 'rechazado_fuera_de_cobertura'),
          _makeModel(id: '4', status: 'en_reparacion'),
        ]),
      );

      final result = await repo.watchActiveIncidents().first;

      expect(result.map((i) => i.eventId), unorderedEquals(['1', '4']));
    });
  });
}
