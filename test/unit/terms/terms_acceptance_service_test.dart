import 'package:app_coordinacion_comunitaria/features/terms/data/services/terms_acceptance_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late TermsAcceptanceService service;

  const uid = 'user-abc';

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await firestore.collection('users').doc(uid).set({
      'email': 'a@b.com',
      'displayName': 'Vecino',
    });
    service = TermsAcceptanceService(firestore: firestore);
  });

  test('accept persiste termsAcceptedVersion y termsAcceptedAt', () async {
    await service.accept(userId: uid, version: 1);

    final doc = await firestore.collection('users').doc(uid).get();
    final data = doc.data()!;
    expect(data['termsAcceptedVersion'], 1);
    expect(data['termsAcceptedAt'], isNotNull);
  });

  test('aceptar de nuevo con una versión superior actualiza el campo',
      () async {
    await service.accept(userId: uid, version: 1);
    await service.accept(userId: uid, version: 2);

    final doc = await firestore.collection('users').doc(uid).get();
    expect(doc.data()!['termsAcceptedVersion'], 2);
  });
}
