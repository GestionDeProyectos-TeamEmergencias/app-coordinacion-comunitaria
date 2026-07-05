import 'package:app_coordinacion_comunitaria/core/errors/app_exception.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/data/services/incident_admin_service.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late IncidentAdminService service;

  const incidentId = 'inc-1';
  const adminUid = 'admin-1';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('incidents').doc(incidentId).set({
      'userId': 'reporter',
      'latitude': -34.6,
      'longitude': -58.3,
      'status': 'recibido',
      'category': 'vial',
    });
    service = IncidentAdminService(firestore: firestore);
  });

  group('reassignCategory', () {
    test('actualiza category y registra auditoría', () async {
      await service.reassignCategory(
        incidentId: incidentId,
        category: IncidentCategory.sanitario,
        adminUid: adminUid,
      );

      final doc = await firestore.collection('incidents').doc(incidentId).get();
      final data = doc.data()!;
      expect(data['category'], 'sanitario');
      expect(data['categoryChangedBy'], adminUid);
      expect(data['categoryChangedAt'], isNotNull);
    });
  });

  group('addAction', () {
    test('agrega entry al array actions', () async {
      await service.addAction(
        incidentId: incidentId,
        note: 'Derivado a Obras Públicas',
        adminUid: adminUid,
        adminDisplayName: 'Romina A.',
      );

      final doc = await firestore.collection('incidents').doc(incidentId).get();
      final actions = doc.data()!['actions'] as List;
      expect(actions, hasLength(1));
      final entry = actions.first as Map<String, dynamic>;
      expect(entry['note'], 'Derivado a Obras Públicas');
      expect(entry['by'], adminUid);
      expect(entry['byDisplayName'], 'Romina A.');
      expect(entry['at'], isNotNull);
    });

    test('agregar varias acciones conserva el orden temporal', () async {
      await service.addAction(
        incidentId: incidentId,
        note: 'Acción 1',
        adminUid: adminUid,
      );
      await service.addAction(
        incidentId: incidentId,
        note: 'Acción 2',
        adminUid: adminUid,
      );

      final doc = await firestore.collection('incidents').doc(incidentId).get();
      final actions = doc.data()!['actions'] as List;
      expect(actions, hasLength(2));
    });

    test('nota vacía o solo espacios rechaza la operación', () async {
      await expectLater(
        () => service.addAction(
          incidentId: incidentId,
          note: '   ',
          adminUid: adminUid,
        ),
        throwsA(isA<FirestoreException>()),
      );

      final doc = await firestore.collection('incidents').doc(incidentId).get();
      expect(doc.data()!.containsKey('actions'), isFalse);
    });
  });
}
