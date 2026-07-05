import 'dart:typed_data';

import 'package:app_coordinacion_comunitaria/core/errors/app_exception.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/data/services/referent_verification_service.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseStorage storage;
  late ReferentVerificationService service;

  const incidentId = 'inc-1';
  const referentUid = 'ref-1';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    storage = MockFirebaseStorage();
    await firestore.collection('incidents').doc(incidentId).set({
      'userId': 'reporter',
      'latitude': -34.6,
      'longitude': -58.3,
      'status': 'recibido',
    });
    service = ReferentVerificationService(
      firestore: firestore,
      storage: storage,
    );
  });

  test('verify sube foto y persiste referentVerification + history', () async {
    await service.verify(
      incidentId: incidentId,
      state: ReferentVerificationState.confirmed,
      photoBytes: Uint8List.fromList([1, 2, 3, 4, 5]),
      photoName: 'evidence.jpg',
      referentUid: referentUid,
      referentDisplayName: 'Marcela R.',
      note: 'Bache real, ~30cm',
    );

    final doc = await firestore.collection('incidents').doc(incidentId).get();
    final data = doc.data()!;
    final current = data['referentVerification'] as Map<String, dynamic>;
    expect(current['state'], 'confirmed');
    expect(current['by'], referentUid);
    expect(current['byDisplayName'], 'Marcela R.');
    expect(current['note'], 'Bache real, ~30cm');
    expect(current['photoUrl'], isA<String>());
    expect((current['photoUrl'] as String).isNotEmpty, isTrue);

    final history = data['referentVerificationHistory'] as List;
    expect(history, hasLength(1));
  });

  test('re-verificar agrega entrada al historial sin perder la anterior',
      () async {
    await service.verify(
      incidentId: incidentId,
      state: ReferentVerificationState.confirmed,
      photoBytes: Uint8List.fromList([1]),
      photoName: 'a.jpg',
      referentUid: referentUid,
    );
    await service.verify(
      incidentId: incidentId,
      state: ReferentVerificationState.dismissed,
      photoBytes: Uint8List.fromList([2]),
      photoName: 'b.jpg',
      referentUid: referentUid,
      note: 'En realidad ya estaba arreglado',
    );

    final doc = await firestore.collection('incidents').doc(incidentId).get();
    final data = doc.data()!;
    final current = data['referentVerification'] as Map<String, dynamic>;
    expect(current['state'], 'dismissed');

    final history = data['referentVerificationHistory'] as List;
    expect(history, hasLength(2));
  });

  test('verify sin foto rechaza la operación', () async {
    await expectLater(
      () => service.verify(
        incidentId: incidentId,
        state: ReferentVerificationState.confirmed,
        photoBytes: Uint8List(0),
        photoName: 'x.jpg',
        referentUid: referentUid,
      ),
      throwsA(isA<StorageException>()),
    );

    final doc = await firestore.collection('incidents').doc(incidentId).get();
    expect(doc.data()!.containsKey('referentVerification'), isFalse);
  });

  test('nota vacía o solo espacios no se persiste', () async {
    await service.verify(
      incidentId: incidentId,
      state: ReferentVerificationState.confirmed,
      photoBytes: Uint8List.fromList([1, 2]),
      photoName: 'x.jpg',
      referentUid: referentUid,
      note: '   ',
    );

    final doc = await firestore.collection('incidents').doc(incidentId).get();
    final current = doc.data()!['referentVerification'] as Map<String, dynamic>;
    expect(current.containsKey('note'), isFalse);
  });
}
