import { computeReactionAggregates } from "./reactionsAggregator";

const defaultThresholds = { threshold: 0.7, minReactions: 3 };

describe("computeReactionAggregates", () => {
  it("sin votos → score 0, no validado", () => {
    const r = computeReactionAggregates(0, 0, defaultThresholds);
    expect(r.confirmsCount).toBe(0);
    expect(r.disputesCount).toBe(0);
    expect(r.confirmationScore).toBe(0);
    expect(r.communityValidated).toBe(false);
  });

  it("1 voto positivo no alcanza minReactions", () => {
    const r = computeReactionAggregates(1, 0, defaultThresholds);
    expect(r.confirmationScore).toBe(1);
    expect(r.communityValidated).toBe(false);
  });

  it("solo disputes → score 0", () => {
    const r = computeReactionAggregates(0, 5, defaultThresholds);
    expect(r.confirmationScore).toBe(0);
    expect(r.communityValidated).toBe(false);
  });

  it("empate (1 confirm / 1 dispute) → score 0.5, no validado", () => {
    const r = computeReactionAggregates(1, 1, defaultThresholds);
    expect(r.confirmationScore).toBe(0.5);
    expect(r.communityValidated).toBe(false);
  });

  it("3 confirms + 0 disputes → score 1, validado", () => {
    const r = computeReactionAggregates(3, 0, defaultThresholds);
    expect(r.confirmationScore).toBe(1);
    expect(r.communityValidated).toBe(true);
  });

  it("score justo en el umbral (0.70) cuenta como validado", () => {
    // 7 confirms / 10 total = 0.7
    const r = computeReactionAggregates(7, 3, defaultThresholds);
    expect(r.confirmationScore).toBeCloseTo(0.7);
    expect(r.communityValidated).toBe(true);
  });

  it("score apenas por debajo del umbral NO valida", () => {
    // 6 confirms / 10 total = 0.6
    const r = computeReactionAggregates(6, 4, defaultThresholds);
    expect(r.confirmationScore).toBe(0.6);
    expect(r.communityValidated).toBe(false);
  });

  it("score >= threshold pero total < minReactions NO valida", () => {
    // 2 confirms / 2 total = 1.0 pero solo 2 votos
    const r = computeReactionAggregates(2, 0, defaultThresholds);
    expect(r.confirmationScore).toBe(1);
    expect(r.communityValidated).toBe(false);
  });

  it("umbral configurable: con threshold 0.5 y minReactions 1 valida fácil", () => {
    const r = computeReactionAggregates(1, 0, {
      threshold: 0.5,
      minReactions: 1,
    });
    expect(r.communityValidated).toBe(true);
  });
});
