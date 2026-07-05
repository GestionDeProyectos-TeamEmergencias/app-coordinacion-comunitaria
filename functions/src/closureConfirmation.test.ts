import { isClosureExpired } from "./closureConfirmation";

describe("isClosureExpired", () => {
  const referenceNow = new Date("2026-06-25T12:00:00Z");

  it("no expira si pendingSince es justo ahora", () => {
    expect(isClosureExpired(referenceNow, 7, referenceNow)).toBe(false);
  });

  it("no expira si pasaron menos días que el threshold", () => {
    const pending = new Date("2026-06-22T12:00:00Z"); // 3 días antes
    expect(isClosureExpired(pending, 7, referenceNow)).toBe(false);
  });

  it("expira justo en el threshold (>=)", () => {
    const pending = new Date("2026-06-18T12:00:00Z"); // 7 días exactos
    expect(isClosureExpired(pending, 7, referenceNow)).toBe(true);
  });

  it("expira con holgura", () => {
    const pending = new Date("2026-06-10T12:00:00Z"); // 15 días antes
    expect(isClosureExpired(pending, 7, referenceNow)).toBe(true);
  });

  it("threshold configurable: con 1 día expira en 24h", () => {
    const pending = new Date("2026-06-24T12:00:00Z"); // 24h antes
    expect(isClosureExpired(pending, 1, referenceNow)).toBe(true);
  });

  it("threshold configurable: con 1 día NO expira a las 23h", () => {
    const pending = new Date("2026-06-24T13:00:01Z"); // 22:59:59 antes
    expect(isClosureExpired(pending, 1, referenceNow)).toBe(false);
  });
});
