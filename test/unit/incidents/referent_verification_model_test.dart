import 'package:app_coordinacion_comunitaria/features/incidents/data/models/incident_event_model.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  test('roundtrip: referentVerificationToMap → fromFirestore → toDomain',
      () async {
    final verification = ReferentVerification(
      state: ReferentVerificationState.confirmed,
      by: 'ref-1',
      byDisplayName: 'Marcela',
      at: DateTime(2026, 1, 2, 10, 30),
      note: 'Bache real',
      photoUrl: 'https://example.com/photo.jpg',
    );
    final map = referentVerificationToMap(verification);

    await firestore.collection('incidents').doc('inc-1').set({
      'userId': 'u',
      'timestamp': Timestamp.now(),
      'latitude': 0,
      'longitude': 0,
      'sourceType': 'quick',
      'status': 'recibido',
      'referentVerification': map,
      'referentVerificationHistory': [map],
    });

    final doc = await firestore.collection('incidents').doc('inc-1').get();
    final domain = IncidentEventModel.fromFirestore(doc).toDomain();

    expect(domain.referentVerification, isNotNull);
    expect(domain.referentVerification!.state,
        ReferentVerificationState.confirmed);
    expect(domain.referentVerification!.by, 'ref-1');
    expect(domain.referentVerification!.byDisplayName, 'Marcela');
    expect(domain.referentVerification!.note, 'Bache real');
    expect(
        domain.referentVerification!.photoUrl, 'https://example.com/photo.jpg');
    expect(domain.referentVerificationHistory, hasLength(1));
  });

  test('verification con state inválido o sin photoUrl se ignora', () async {
    await firestore.collection('incidents').doc('inc-1').set({
      'userId': 'u',
      'timestamp': Timestamp.now(),
      'latitude': 0,
      'longitude': 0,
      'sourceType': 'quick',
      'status': 'recibido',
      'referentVerification': {
        'state': 'invalid',
        'by': 'ref-1',
        'photoUrl': 'x',
      },
    });

    final doc = await firestore.collection('incidents').doc('inc-1').get();
    final domain = IncidentEventModel.fromFirestore(doc).toDomain();

    expect(domain.referentVerification, isNull);
  });

  test('incidents sin verificación devuelven null y lista vacía', () async {
    await firestore.collection('incidents').doc('inc-1').set({
      'userId': 'u',
      'timestamp': Timestamp.now(),
      'latitude': 0,
      'longitude': 0,
      'sourceType': 'quick',
      'status': 'recibido',
    });

    final doc = await firestore.collection('incidents').doc('inc-1').get();
    final domain = IncidentEventModel.fromFirestore(doc).toDomain();

    expect(domain.referentVerification, isNull);
    expect(domain.referentVerificationHistory, isEmpty);
  });
}
