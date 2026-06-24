import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/fcm_service.dart';

/// Provider singleton del servicio FCM. Vive en un archivo aparte de
/// `fcm_provider.dart` para que módulos como `auth` puedan importarlo sin
/// crear un ciclo con `authStateProvider`. [D-01]
final fcmServiceProvider = Provider<FcmService>((ref) => FcmService());
