import { describe, expect, it } from 'vitest';
import { BazarDraftRequest, toBazarDraft, toMealDraft, type MealContext } from '../lib/schemas';

const ctx: MealContext = {
  members: [
    { ref: 'M1', member_id: 'id-rahim', aliases: ['Rahim'] },
    { ref: 'M2', member_id: 'id-karim', aliases: ['Karim'] },
  ],
  meal_types: [{ ref: 'T1', meal_type_id: 'id-lunch', name: 'দুপুর' }],
};
const entry = (o: object) => ({ member: 'M1', meal_type: 'T1', count: 1, guest_count: 0, is_off: false, ...o });

describe('toMealDraft', () => {
  it('maps refs back to real ids', () => {
    const d = toMealDraft({ entries: [entry({ count: 1.5, guest_count: 1 })], unmatched: [], confidence: 0.9 }, ctx);
    expect(d).toEqual({
      entries: [{ member_id: 'id-rahim', meal_type_id: 'id-lunch', count: 1.5, guest_count: 1, is_off: false }],
      unmatched: [],
      confidence: 0.9,
    });
  });

  it('moves bad counts and guests to unmatched', () => {
    const d = toMealDraft({ entries: [entry({ count: 0.3 }), entry({ count: 6 }), entry({ guest_count: 1.5 }), entry({ guest_count: 21 })] }, ctx);
    expect(d.entries).toEqual([]);
    expect(d.unmatched).toEqual(Array(4).fill('Rahim · দুপুর: invalid'));
  });

  it('drops unknown refs into unmatched without leaking ids', () => {
    const d = toMealDraft({ entries: [entry({ member: 'M9' }), entry({ meal_type: 'T7' }), 'junk'], unmatched: ['rat e guest 1'] }, ctx);
    expect(d.entries).toEqual([]);
    expect(d.unmatched).toEqual(['rat e guest 1', '? · দুপুর: invalid', 'Rahim · ?: invalid', '? · ?: invalid']);
  });

  it('forces count 0 when off and defaults confidence', () => {
    const d = toMealDraft({ entries: [entry({ member: 'M2', count: 2, is_off: true })] }, ctx);
    expect(d.entries[0]).toMatchObject({ member_id: 'id-karim', count: 0, is_off: true });
    expect(d.confidence).toBe(0.5);
  });

  it('rejects a wrong top-level shape', () => {
    expect(() => toMealDraft({ entries: 'nope' }, ctx)).toThrow();
    expect(() => toMealDraft([], ctx)).toThrow();
  });
});

describe('toBazarDraft', () => {
  it('computes total_matches_items itself and skips unreadable items', () => {
    const d = toBazarDraft({
      items: [{ name: 'আলু', qty: 2, unit: 'kg', price: 60 }, { name: 'ডাল', price: 60 }, { name: '', price: 'x' }],
      total: 120,
      total_matches_items: false,
    });
    expect(d.items).toHaveLength(2);
    expect(d.items[1]).toEqual({ name: 'ডাল', qty: null, unit: null, price: 60 });
    expect(d.total_matches_items).toBe(true);
    expect(d.notes).toBe('1 unreadable item(s) skipped');
  });

  it('flags a total that does not match', () => {
    expect(toBazarDraft({ items: [{ name: 'চাল', price: 500 }], total: 550 }).total_matches_items).toBe(false);
  });
});

describe('BazarDraftRequest', () => {
  const ok = { mess_id: '11111111-0000-0000-0000-00000000000a', date: '2026-10-08' };
  it('accepts jpeg base64 only', () => {
    expect(BazarDraftRequest.safeParse({ ...ok, image_base64: '/9j/4AAQSkZJRg==' }).success).toBe(true);
    expect(BazarDraftRequest.safeParse({ ...ok, image_base64: 'iVBORw0KGgo=' }).success).toBe(false);
  });
});
