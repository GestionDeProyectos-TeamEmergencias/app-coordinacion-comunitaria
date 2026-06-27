import 'package:app_coordinacion_comunitaria/features/admin/data/datasources/coverage_config_remote_datasource.dart';
import 'package:app_coordinacion_comunitaria/features/admin/domain/entities/coverage_config.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Cuadrado (lat,lng) [0..4] x [0..4].
  final square = <CoverageVertex>[
    (lat: 0.0, lng: 0.0),
    (lat: 0.0, lng: 4.0),
    (lat: 4.0, lng: 4.0),
    (lat: 4.0, lng: 0.0),
  ];

  // Polígono cóncavo en forma de "L": el cuadrante superior-derecho
  // (lat 2..4, lng 2..4) queda FUERA.
  final lShape = <CoverageVertex>[
    (lat: 0.0, lng: 0.0),
    (lat: 4.0, lng: 0.0),
    (lat: 4.0, lng: 2.0),
    (lat: 2.0, lng: 2.0),
    (lat: 2.0, lng: 4.0),
    (lat: 0.0, lng: 4.0),
  ];

  group('CoverageConfig.pointInPolygon (ray casting)', () {
    test('interior → dentro', () {
      expect(CoverageConfig.pointInPolygon(2, 2, square), isTrue);
    });

    test('exterior → fuera', () {
      expect(CoverageConfig.pointInPolygon(5, 5, square), isFalse);
      expect(CoverageConfig.pointInPolygon(2, -1, square), isFalse);
    });

    test('vértice exacto → dentro', () {
      expect(CoverageConfig.pointInPolygon(0, 0, square), isTrue);
      expect(CoverageConfig.pointInPolygon(4, 4, square), isTrue);
    });

    test('borde (punto medio de un lado) → dentro', () {
      // Lado inferior (lat=0) y lado izquierdo (lng=0).
      expect(CoverageConfig.pointInPolygon(0, 2, square), isTrue);
      expect(CoverageConfig.pointInPolygon(2, 0, square), isTrue);
    });

    test('primer y último vértice → dentro', () {
      expect(
        CoverageConfig.pointInPolygon(
          square.first.lat,
          square.first.lng,
          square,
        ),
        isTrue,
      );
      expect(
        CoverageConfig.pointInPolygon(
          square.last.lat,
          square.last.lng,
          square,
        ),
        isTrue,
      );
    });

    test('polígono cóncavo: notch fuera, brazos dentro', () {
      // Notch superior-derecho → fuera.
      expect(CoverageConfig.pointInPolygon(3, 3, lShape), isFalse);
      // Brazo vertical (izquierda) y horizontal (abajo) → dentro.
      expect(CoverageConfig.pointInPolygon(3, 1, lShape), isTrue);
      expect(CoverageConfig.pointInPolygon(1, 3, lShape), isTrue);
      expect(CoverageConfig.pointInPolygon(1, 1, lShape), isTrue);
    });
  });

  group('CoverageConfig.isWithinCoverage dispatch', () {
    test('con polígono válido usa point-in-polygon, no el círculo', () {
      // Centro lejos del polígono y radio chico: si usara el círculo, (2,2)
      // daría fuera. El polígono lo incluye.
      final config = CoverageConfig(
        centerLat: -34.5,
        centerLng: -60.9,
        radiusMeters: 10,
        polygonPoints: square,
      );
      expect(config.usesPolygon, isTrue);
      expect(config.isWithinCoverage(2, 2), isTrue);
      expect(config.isWithinCoverage(5, 5), isFalse);
    });

    test('retrocompat: sin polígono valida por círculo', () {
      const config = CoverageConfig(
        centerLat: -34.5895,
        centerLng: -60.9442,
        radiusMeters: 5000,
      );
      expect(config.usesPolygon, isFalse);
      expect(config.isWithinCoverage(-34.5895, -60.9442), isTrue);
      // ~10km al norte → fuera del círculo.
      expect(config.isWithinCoverage(-34.4995, -60.9442), isFalse);
    });

    test('polígono con <3 vértices se ignora (cae a círculo)', () {
      const config = CoverageConfig(
        centerLat: -34.5895,
        centerLng: -60.9442,
        radiusMeters: 5000,
        polygonPoints: [
          (lat: 0.0, lng: 0.0),
          (lat: 0.0, lng: 4.0),
        ],
      );
      expect(config.usesPolygon, isFalse);
      // Valida por círculo: el centro está dentro.
      expect(config.isWithinCoverage(-34.5895, -60.9442), isTrue);
    });
  });

  group('CoverageConfigRemoteDataSource serialización del polígono', () {
    late FakeFirebaseFirestore firestore;
    late CoverageConfigRemoteDataSource ds;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      ds = CoverageConfigRemoteDataSource(firestore);
    });

    test('round-trip: persiste y lee el polígono', () async {
      final config = CoverageConfig(
        centerLat: -34.5,
        centerLng: -60.9,
        radiusMeters: 5000,
        polygonPoints: square,
      );
      await ds.updateCoverageConfig(config);

      final read = await ds.watchCoverageConfig().first;
      expect(read.polygonPoints, isNotNull);
      expect(read.polygonPoints!.length, 4);
      expect(read.polygonPoints!.first.lat, 0.0);
      expect(read.polygonPoints!.first.lng, 0.0);
      expect(read.usesPolygon, isTrue);
    });

    test('sin polígono: polygonPoints queda null al leer', () async {
      const config = CoverageConfig(
        centerLat: -34.5,
        centerLng: -60.9,
        radiusMeters: 5000,
      );
      await ds.updateCoverageConfig(config);

      final read = await ds.watchCoverageConfig().first;
      expect(read.polygonPoints, isNull);
      expect(read.usesPolygon, isFalse);
    });

    test('limpiar polígono: vuelve a círculo (borra el campo)', () async {
      await ds.updateCoverageConfig(CoverageConfig(
        centerLat: -34.5,
        centerLng: -60.9,
        radiusMeters: 5000,
        polygonPoints: square,
      ));
      // Segundo guardado sin polígono → debe borrarlo.
      await ds.updateCoverageConfig(const CoverageConfig(
        centerLat: -34.5,
        centerLng: -60.9,
        radiusMeters: 5000,
      ));

      final read = await ds.watchCoverageConfig().first;
      expect(read.polygonPoints, isNull);
    });
  });
}
