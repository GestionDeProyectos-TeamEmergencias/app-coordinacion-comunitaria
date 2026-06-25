import 'package:app_coordinacion_comunitaria/core/errors/app_exception.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/data/datasources/incidents_remote_datasource.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late IncidentsRemoteDataSource ds;

  const incidentId = 'inc-1';
  const ownerUid = 'reporter-1';
  const adminUid = 'admin-1';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    ds = IncidentsRemoteDataSource(firestore, MockFirebaseStorage());
    await firestore.collection('incidents').doc(incidentId).set({
      'userId': ownerUid,
      'latitude': 0,
      'longitude': 0,
      'status': 'en_reparacion',
      'sourceType': 'form',
      'timestamp': Timestamp.now(),
    });
  });

  group('updateStatus(solucionado, changedBy)', () {
    test('inicializa closureConfirmation con state=pendiente', () async {
      await ds.updateStatus(incidentId, 'solucionado', changedBy: adminUid);
      final doc = await firestore.collection('incidents').doc(incidentId).get();
      final closure =
          doc.data()!['closureConfirmation'] as Map<String, dynamic>;
      expect(closure['state'], 'pendiente');
      expect(closure['by'], adminUid);
      expect(closure['at'], isNotNull);
      expect(doc.data()!['status'], 'solucionado');
    });

    test('transición a otro status (programado) NO toca closureConfirmation',
        () async {
      await ds.updateStatus(incidentId, 'programado', changedBy: adminUid);
      final doc = await firestore.collection('incidents').doc(incidentId).get();
      expect(doc.data()!.containsKey('closureConfirmation'), isFalse);
    });
  });

  group('confirmOwnClosure', () {
    test('actualiza closureConfirmation a confirmado por dueño', () async {
      await ds.updateStatus(incidentId, 'solucionado', changedBy: adminUid);
      await ds.confirmOwnClosure(eventId: incidentId, ownerUid: ownerUid);
      final doc = await firestore.collection('incidents').doc(incidentId).get();
      final closure =
          doc.data()!['closureConfirmation'] as Map<String, dynamic>;
      expect(closure['state'], 'confirmado');
      expect(closure['by'], ownerUid);
    });
  });

  group('disputeOwnClosure', () {
    test('vuelve status a en_reparacion + closureConfirmation=disputado',
        () async {
      await ds.updateStatus(incidentId, 'solucionado', changedBy: adminUid);
      await ds.disputeOwnClosure(
        eventId: incidentId,
        ownerUid: ownerUid,
        note: 'El bache sigue ahí',
      );
      final doc = await firestore.collection('incidents').doc(incidentId).get();
      expect(doc.data()!['status'], 'en_reparacion');
      final closure =
          doc.data()!['closureConfirmation'] as Map<String, dynamic>;
      expect(closure['state'], 'disputado');
      expect(closure['note'], 'El bache sigue ahí');
      expect(closure['by'], ownerUid);
    });

    test('nota vacía o solo espacios rechaza con FirestoreException', () async {
      await ds.updateStatus(incidentId, 'solucionado', changedBy: adminUid);
      await expectLater(
        () => ds.disputeOwnClosure(
          eventId: incidentId,
          ownerUid: ownerUid,
          note: '   ',
        ),
        throwsA(isA<FirestoreException>()),
      );
      // Status no debe cambiar.
      final doc = await firestore.collection('incidents').doc(incidentId).get();
      expect(doc.data()!['status'], 'solucionado');
    });
  });
}
