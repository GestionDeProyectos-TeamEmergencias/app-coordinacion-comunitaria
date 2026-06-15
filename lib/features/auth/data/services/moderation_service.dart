import 'package:cloud_firestore/cloud_firestore.dart';

class ModerationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Marca un reporte como falso y bloquea automáticamente al usuario si supera el umbral.
  /// Cumple con: [T-AUTH-07] Criterios de Aceptación 1 y 2.
  Future<void> marcarReporteComoFalso({
    required String incidentId, 
    required String userId,
  }) async {
    
    // Referencias a los documentos en la base de datos
    final DocumentReference incidentRef = _db.collection('incidents').doc(incidentId);
    final DocumentReference userRef = _db.collection('users').doc(userId);

    // Usamos una Transacción para asegurarnos de que la lectura y escritura
    // del contador de reportes falsos se haga de forma segura y atómica.
    return _db.runTransaction((transaction) async {
      
      // 1. Buscamos los datos actuales del usuario en la base de datos
      final DocumentSnapshot userSnap = await transaction.get(userRef);
      
      if (!userSnap.exists) {
        throw Exception("El usuario no existe en la base de datos.");
      }

      // Leemos el contador actual (si no existe, por defecto es 0)
      final Map<String, dynamic> userData = userSnap.data() as Map<String, dynamic>;
      final int currentFalseReports = userData['falseReportsCount'] as int? ?? 0;
      
      // Sumamos 1 al contador por este nuevo reporte falso
      final int newFalseReportsCount = currentFalseReports + 1;
      
      // Definimos el umbral: si llega a 3 reportes falsos, se bloquea automáticamente
      final bool superarUmbral = newFalseReportsCount >= 3;

      // 2. Actualizamos el estado del incidente a "Falso"
      transaction.update(incidentRef, {
        'status': 'falso',
        'moderatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Actualizamos el perfil del vecino
      transaction.update(userRef, {
        'falseReportsCount': newFalseReportsCount,
        // Si superó el umbral, el status pasa a 'blocked' (bloqueado)
        if (superarUmbral) 'status': 'blocked',
      });
    });
  }

  /// Permite al Administrador desbloquear manualmente al usuario.
  /// Cumple con: [T-AUTH-07] Criterio de Aceptación 4.
  Future<void> desbloquearUsuarioManualmente(String userId) async {
    return _db.collection('users').doc(userId).update({
      'status': 'active',          // Lo volvemos a poner como activo
      'falseReportsCount': 0,      // Reseteamos el contador a 0 para darle otra oportunidad
    });
  }
}