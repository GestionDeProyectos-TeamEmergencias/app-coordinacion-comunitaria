import 'package:app_coordinacion_comunitaria/features/incidents/data/services/reactions_service.dart';
import 'package:app_coordinacion_comunitaria/features/incidents/domain/entities/incident_event.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ReactionsService service;

  const incidentId = 'inc-1';
  const userId = 'voter-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = ReactionsService(firestore: firestore);
  });

  test('setReaction persiste type, by y at', () async {
    await service.setReaction(
      incidentId: incidentId,
      userId: userId,
      type: ReactionType.confirm,
    );

    final doc = await firestore
        .collection('incidents')
        .doc(incidentId)
        .collection('reactions')
        .doc(userId)
        .get();

    expect(doc.exists, isTrue);
    expect(doc.data()!['type'], 'confirm');
    expect(doc.data()!['by'], userId);
    expect(doc.data()!['at'], isNotNull);
  });

  test('setReaction sobreescribe (cambio de voto)', () async {
    await service.setReaction(
      incidentId: incidentId,
      userId: userId,
      type: ReactionType.confirm,
    );
    await service.setReaction(
      incidentId: incidentId,
      userId: userId,
      type: ReactionType.dispute,
    );

    final doc = await firestore
        .collection('incidents')
        .doc(incidentId)
        .collection('reactions')
        .doc(userId)
        .get();
    expect(doc.data()!['type'], 'dispute');
  });

  test('removeReaction borra el doc del votante', () async {
    await service.setReaction(
      incidentId: incidentId,
      userId: userId,
      type: ReactionType.confirm,
    );
    await service.removeReaction(incidentId: incidentId, userId: userId);

    final doc = await firestore
        .collection('incidents')
        .doc(incidentId)
        .collection('reactions')
        .doc(userId)
        .get();
    expect(doc.exists, isFalse);
  });

  test('watchMyReaction emite null cuando no hay reacción', () async {
    final stream = service.watchMyReaction(
      incidentId: incidentId,
      userId: userId,
    );
    expect(await stream.first, isNull);
  });

  test('watchMyReaction emite ReactionType.confirm tras setReaction', () async {
    await service.setReaction(
      incidentId: incidentId,
      userId: userId,
      type: ReactionType.confirm,
    );
    final stream = service.watchMyReaction(
      incidentId: incidentId,
      userId: userId,
    );
    expect(await stream.first, ReactionType.confirm);
  });
}
