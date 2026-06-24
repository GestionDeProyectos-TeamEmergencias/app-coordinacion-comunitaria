import 'dart:async';

import 'package:app_coordinacion_comunitaria/features/notifications/data/services/fcm_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class _FakeNotificationSettings extends Fake implements NotificationSettings {
  _FakeNotificationSettings(this._status);
  final AuthorizationStatus _status;

  @override
  AuthorizationStatus get authorizationStatus => _status;
}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockFirebaseMessaging messaging;
  late StreamController<String> tokenRefreshController;

  const uid = 'user-abc';
  const token = 'fcm-token-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    messaging = _MockFirebaseMessaging();
    tokenRefreshController = StreamController<String>.broadcast();
    // Doc base del usuario.
    firestore.collection('users').doc(uid).set({
      'email': 'a@b.com',
      'fcmTokens': <String>[],
    });
    when(() => messaging.onTokenRefresh)
        .thenAnswer((_) => tokenRefreshController.stream);
  });

  tearDown(() async {
    await tokenRefreshController.close();
  });

  void stubPermission(AuthorizationStatus status) {
    when(
      () => messaging.requestPermission(
        alert: any(named: 'alert'),
        badge: any(named: 'badge'),
        sound: any(named: 'sound'),
      ),
    ).thenAnswer((_) async => _FakeNotificationSettings(status));
  }

  test('registerForUser persiste el token via arrayUnion', () async {
    stubPermission(AuthorizationStatus.authorized);
    when(() => messaging.getToken()).thenAnswer((_) async => token);

    final service = FcmService(messaging: messaging, firestore: firestore);

    final ok = await service.registerForUser(uid);

    expect(ok, isTrue);
    final doc = await firestore.collection('users').doc(uid).get();
    expect(doc.data()!['fcmTokens'], contains(token));
  });

  test('registerForUser es idempotente para el mismo uid', () async {
    stubPermission(AuthorizationStatus.authorized);
    when(() => messaging.getToken()).thenAnswer((_) async => token);

    final service = FcmService(messaging: messaging, firestore: firestore);

    await service.registerForUser(uid);
    await service.registerForUser(uid);

    // getToken solo debe llamarse una vez (early return en la 2da invocación).
    verify(() => messaging.getToken()).called(1);
  });

  test('registerForUser retorna false si los permisos son denegados', () async {
    stubPermission(AuthorizationStatus.denied);

    final service = FcmService(messaging: messaging, firestore: firestore);

    final ok = await service.registerForUser(uid);

    expect(ok, isFalse);
    final doc = await firestore.collection('users').doc(uid).get();
    expect(doc.data()!['fcmTokens'], isEmpty);
    verifyNever(() => messaging.getToken());
  });

  test('registerForUser retorna false si getToken devuelve null', () async {
    stubPermission(AuthorizationStatus.authorized);
    when(() => messaging.getToken()).thenAnswer((_) async => null);

    final service = FcmService(messaging: messaging, firestore: firestore);

    final ok = await service.registerForUser(uid);

    expect(ok, isFalse);
    final doc = await firestore.collection('users').doc(uid).get();
    expect(doc.data()!['fcmTokens'], isEmpty);
  });

  test('onTokenRefresh persiste el nuevo token', () async {
    stubPermission(AuthorizationStatus.authorized);
    when(() => messaging.getToken()).thenAnswer((_) async => token);

    final service = FcmService(messaging: messaging, firestore: firestore);
    await service.registerForUser(uid);

    tokenRefreshController.add('fcm-token-2');
    // Dejar que el listener procese.
    await Future<void>.delayed(Duration.zero);

    final doc = await firestore.collection('users').doc(uid).get();
    final tokens = List<String>.from(doc.data()!['fcmTokens'] as List);
    expect(tokens, containsAll(<String>['fcm-token-1', 'fcm-token-2']));
  });

  test('unregisterCurrent quita el token actual', () async {
    stubPermission(AuthorizationStatus.authorized);
    when(() => messaging.getToken()).thenAnswer((_) async => token);

    final service = FcmService(messaging: messaging, firestore: firestore);
    await service.registerForUser(uid);
    await service.unregisterCurrent();

    final doc = await firestore.collection('users').doc(uid).get();
    expect(doc.data()!['fcmTokens'], isNot(contains(token)));
  });

  test('unregisterCurrent es no-op si no había registro previo', () async {
    final service = FcmService(messaging: messaging, firestore: firestore);

    // No debe lanzar.
    await service.unregisterCurrent();

    final doc = await firestore.collection('users').doc(uid).get();
    expect(doc.data()!['fcmTokens'], isEmpty);
  });
}
