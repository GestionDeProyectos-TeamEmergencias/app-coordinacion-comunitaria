import {
  calculateHaversineDistance,
  isWithinCoverage,
  loadCoverageConfig,
  DEFAULT_COVERAGE_CONFIG,
  CoverageConfig,
} from "./coverageValidation";

// -- Mock de Firestore siguiendo el patron de reputationManager.test.ts --

interface FakeDoc {
  data?: Record<string, unknown>;
}

function buildFakeFirestore(initialDocs: Record<string, FakeDoc> = {}) {
  const store: Record<string, FakeDoc> = { ...initialDocs };

  const firestore = {
    collection(name: string) {
      return {
        doc(uid: string) {
          const path = `${name}/${uid}`;
          return {
            async get() {
              const entry = store[path];
              return {
                exists: !!entry,
                data: () => entry?.data,
              };
            },
          };
        },
      };
    },
  };

  return { firestore };
}

// -- Tests de calculateHaversineDistance --

describe("calculateHaversineDistance", () => {
  it("should calculate a known distance: Obelisco to Casa Rosada (~1140m)", () => {
    // Obelisco de Buenos Aires
    const obeliscoLat = -34.6037;
    const obeliscoLng = -58.3816;
    // Casa Rosada
    const casaRosadaLat = -34.6083;
    const casaRosadaLng = -58.3708;

    const distance = calculateHaversineDistance(
      obeliscoLat, obeliscoLng,
      casaRosadaLat, casaRosadaLng
    );

    // La distancia real es aproximadamente 1100-1200m
    expect(distance).toBeGreaterThan(1000);
    expect(distance).toBeLessThan(1300);
  });

  it("should return 0 for the same point", () => {
    const distance = calculateHaversineDistance(-34.5895, -60.9442, -34.5895, -60.9442);
    expect(distance).toBe(0);
  });

  it("should be symmetric (distance A->B === distance B->A)", () => {
    const d1 = calculateHaversineDistance(-34.6037, -58.3816, -34.6083, -58.3708);
    const d2 = calculateHaversineDistance(-34.6083, -58.3708, -34.6037, -58.3816);
    expect(d1).toBeCloseTo(d2, 6);
  });

  it("should calculate a long distance: Buenos Aires to Cordoba (~650km)", () => {
    // Buenos Aires centro
    const bsAsLat = -34.6037;
    const bsAsLng = -58.3816;
    // Cordoba centro
    const cordobaLat = -31.4201;
    const cordobaLng = -64.1888;

    const distance = calculateHaversineDistance(bsAsLat, bsAsLng, cordobaLat, cordobaLng);

    // La distancia real es aproximadamente 646-660 km
    expect(distance).toBeGreaterThan(640_000);
    expect(distance).toBeLessThan(670_000);
  });
});

// -- Tests de isWithinCoverage --

describe("isWithinCoverage", () => {
  const config: CoverageConfig = {
    centerLat: -34.5895,
    centerLng: -60.9442,
    radiusMeters: 5000,
  };

  it("should return true for a point inside the coverage radius", () => {
    // Punto a ~500m del centro (aprox.)
    const result = isWithinCoverage(-34.5900, -60.9440, config);
    expect(result).toBe(true);
  });

  it("should return true for a point exactly at the center", () => {
    const result = isWithinCoverage(config.centerLat, config.centerLng, config);
    expect(result).toBe(true);
  });

  it("should return false for a point outside the coverage radius", () => {
    // Punto a ~100km del centro
    const result = isWithinCoverage(-35.5, -61.0, config);
    expect(result).toBe(false);
  });

  it("should return true for a point exactly at the boundary (distance <= radiusMeters)", () => {
    // Usamos un punto que sabemos esta justo dentro del radio.
    // La conversion plana metros->grados (m/111320) introduce un error de ~5-6m
    // por la curvatura terrestre. Compensamos eso usando un valor ligeramente
    // menor para garantizar que el punto cae dentro.
    const offsetLat = 4990 / 111_320; // ligeramente dentro del radio
    const nearBoundaryLat = config.centerLat + offsetLat;

    const distance = calculateHaversineDistance(
      nearBoundaryLat, config.centerLng,
      config.centerLat, config.centerLng
    );

    // Verificamos que la distancia esta dentro del radio
    expect(distance).toBeLessThanOrEqual(config.radiusMeters);

    // isWithinCoverage usa <= asi que este punto debe estar incluido
    const result = isWithinCoverage(nearBoundaryLat, config.centerLng, config);
    expect(result).toBe(true);
  });

  it("should return false for a point just beyond the boundary", () => {
    // 5100m del centro — fuera del radio de 5000m
    const offsetLat = 5100 / 111_320;
    const beyondLat = config.centerLat + offsetLat;
    const result = isWithinCoverage(beyondLat, config.centerLng, config);
    expect(result).toBe(false);
  });
});

// -- Tests de loadCoverageConfig --

describe("loadCoverageConfig", () => {
  it("should return config from Firestore when doc exists with valid data", async () => {
    const customConfig = {
      centerLat: -31.4201,
      centerLng: -64.1888,
      radiusMeters: 10000,
    };

    const { firestore } = buildFakeFirestore({
      "config/coverage": { data: customConfig },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const result = await loadCoverageConfig(firestore as any);

    expect(result.centerLat).toBe(-31.4201);
    expect(result.centerLng).toBe(-64.1888);
    expect(result.radiusMeters).toBe(10000);
  });

  it("should return defaults when doc does not exist", async () => {
    const { firestore } = buildFakeFirestore({});

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const result = await loadCoverageConfig(firestore as any);

    expect(result.centerLat).toBe(DEFAULT_COVERAGE_CONFIG.centerLat);
    expect(result.centerLng).toBe(DEFAULT_COVERAGE_CONFIG.centerLng);
    expect(result.radiusMeters).toBe(DEFAULT_COVERAGE_CONFIG.radiusMeters);
  });

  it("should return defaults when doc has invalid data (missing fields)", async () => {
    const { firestore } = buildFakeFirestore({
      "config/coverage": { data: { centerLat: -34.0 } },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const result = await loadCoverageConfig(firestore as any);

    expect(result.centerLat).toBe(DEFAULT_COVERAGE_CONFIG.centerLat);
    expect(result.centerLng).toBe(DEFAULT_COVERAGE_CONFIG.centerLng);
    expect(result.radiusMeters).toBe(DEFAULT_COVERAGE_CONFIG.radiusMeters);
  });

  it("should return defaults when doc has non-numeric values", async () => {
    const { firestore } = buildFakeFirestore({
      "config/coverage": {
        data: {
          centerLat: "not-a-number",
          centerLng: -60.9442,
          radiusMeters: 5000,
        },
      },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const result = await loadCoverageConfig(firestore as any);

    expect(result.centerLat).toBe(DEFAULT_COVERAGE_CONFIG.centerLat);
  });

  it("should return defaults when radiusMeters is zero or negative", async () => {
    const { firestore } = buildFakeFirestore({
      "config/coverage": {
        data: {
          centerLat: -34.5,
          centerLng: -60.9,
          radiusMeters: 0,
        },
      },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const result = await loadCoverageConfig(firestore as any);

    expect(result.radiusMeters).toBe(DEFAULT_COVERAGE_CONFIG.radiusMeters);
  });

  it("should return defaults when doc has NaN values", async () => {
    const { firestore } = buildFakeFirestore({
      "config/coverage": {
        data: {
          centerLat: NaN,
          centerLng: -60.9442,
          radiusMeters: 5000,
        },
      },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const result = await loadCoverageConfig(firestore as any);

    expect(result.centerLat).toBe(DEFAULT_COVERAGE_CONFIG.centerLat);
  });

  it("should return a defensive copy (not mutate defaults)", async () => {
    const { firestore } = buildFakeFirestore({});

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const result = await loadCoverageConfig(firestore as any);
    result.radiusMeters = 99999;

    expect(DEFAULT_COVERAGE_CONFIG.radiusMeters).toBe(5000);
  });
});
