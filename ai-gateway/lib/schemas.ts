import { z } from 'zod';

// ── requests ─────────────────────────────────────────────────────────────
const base = { mess_id: z.guid(), date: z.iso.date() };
export const MealDraftRequest = z.object({ ...base, text: z.string().trim().min(1).max(500) });
// ~400 KB of JPEG ≈ 550k base64 chars. "/9j/" is the base64 of the JPEG magic bytes.
export const BazarDraftRequest = z.object({
  ...base,
  image_base64: z.string().max(560_000).regex(/^\/9j\/[A-Za-z0-9+/]+={0,2}$/, 'jpeg base64'),
});

// ── meal draft ───────────────────────────────────────────────────────────
export type MealContext = {
  members: { ref: string; member_id: string; aliases: string[] }[];
  meal_types: { ref: string; meal_type_id: string; name: string }[];
};
export type MealDraft = {
  entries: { member_id: string; meal_type_id: string; count: number; guest_count: number; is_off: boolean }[];
  unmatched: string[];
  confidence: number;
};

const RawMealDraft = z.object({
  entries: z.array(z.unknown()).default([]),
  unmatched: z.array(z.unknown()).default([]),
  confidence: z.number().min(0).max(1).catch(0.5).default(0.5),
});
const RawEntry = z.object({
  member: z.string(),
  meal_type: z.string(),
  count: z.number().min(0).max(5).refine((n) => Number.isInteger(n * 2), 'half steps'),
  guest_count: z.number().int().min(0).max(20).default(0),
  is_off: z.boolean().default(false),
});

// Throws if the top-level shape is wrong (→ provider fallback). Bad entries go to unmatched.
export function toMealDraft(raw: unknown, ctx: MealContext): MealDraft {
  const draft = RawMealDraft.parse(raw);
  const members = new Map(ctx.members.map((m) => [m.ref, m]));
  const types = new Map(ctx.meal_types.map((t) => [t.ref, t]));
  const out: MealDraft = { entries: [], unmatched: draft.unmatched.map(String).slice(0, 50), confidence: draft.confidence };

  for (const e of draft.entries) {
    const r = RawEntry.safeParse(e);
    const m = r.success ? members.get(r.data.member) : undefined;
    const t = r.success ? types.get(r.data.meal_type) : undefined;
    if (r.success && m && t) {
      out.entries.push({
        member_id: m.member_id,
        meal_type_id: t.meal_type_id,
        count: r.data.is_off ? 0 : r.data.count,
        guest_count: r.data.guest_count,
        is_off: r.data.is_off,
      });
      continue;
    }
    // Describe with real names so the user can fix it; never echo raw refs.
    const o = (e ?? {}) as Record<string, unknown>;
    const who = members.get(String(o.member))?.aliases[0] ?? '?';
    const what = types.get(String(o.meal_type))?.name ?? '?';
    out.unmatched.push(`${who} · ${what}: invalid`);
  }
  return out;
}

// ── bazar draft ──────────────────────────────────────────────────────────
export type BazarDraft = {
  items: { name: string; qty: number | null; unit: string | null; price: number }[];
  total: number | null;
  total_matches_items: boolean;
  notes: string;
};

const money = z.number().min(0).max(10_000_000).transform((n) => Math.round(n * 100) / 100);
const RawBazar = z.object({
  items: z.array(z.unknown()).max(100),
  total: money.nullable().catch(null).default(null),
  notes: z.string().catch('').default(''),
});
const RawItem = z.object({
  name: z.string().trim().min(1).max(60),
  qty: z.number().positive().max(100_000).nullable().catch(null).default(null),
  unit: z.string().trim().min(1).max(15).nullable().catch(null).default(null),
  price: money,
});

// Throws on a wrong top-level shape (→ fallback). Unreadable items are dropped and noted.
// total_matches_items is computed here, not trusted from the model.
export function toBazarDraft(raw: unknown): BazarDraft {
  const b = RawBazar.parse(raw);
  const items = b.items.flatMap((i) => {
    const r = RawItem.safeParse(i);
    return r.success ? [r.data] : [];
  });
  const dropped = b.items.length - items.length;
  const sum = items.reduce((s, i) => s + i.price, 0);
  const notes = [b.notes.slice(0, 300), dropped ? `${dropped} unreadable item(s) skipped` : '']
    .filter(Boolean).join(' · ');
  return {
    items,
    total: b.total,
    total_matches_items: b.total !== null && Math.abs(sum - b.total) < 0.01,
    notes,
  };
}
