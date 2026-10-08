# Design System

<!-- Direction contract (impeccable, seed 66828936, chosen: monochrome product canon, fused with Meal Bazar)
THESIS: Numbers you can trust at a glance. Every figure carries its proof. Refuses the green-card fintech dashboard.
OWN-WORLD: A fine neutral scale from near-white to near-black. Primary actions are filled in ink. One turmeric accent marks "live/today/AI" only. Hairline borders, no gradients, no nested cards. Hind Siliguri at three weights.
STORY: The manager opens the app, reads today's state in one glance, taps meals, sees the totals and their proof update, and is done.
FIRST VIEWPORT (Today): a large Bangla date, the day's meal total as the headline figure with its proof line, the member × meal tally grid, and the quick actions in thumb reach.
FORM: monochrome canon (user-chosen challenger over the assigned "mobile-money slip"); seed key 66828936.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, and DESIGN.md
-->

Material 3 governs structure and components (Android platform). The brand lives in the theme: color roles, type and shape. All tokens live in `app/lib/core/theme/`, and nothing outside that folder may hard-code a color, size or font.

## Principles
1. **A claim comes with its proof.** Any computed figure (meal rate, a balance, a total) shows or reveals a proof line under it in one tap, such as `৳১,৪১০ ÷ ২০.৫ মিল`. This is the product's trust mechanism carried into the visual language.
2. **Monochrome first.** Ink on near-white (or the reverse). Color is reserved for meaning: the accent means live/today/AI, red means due, green means advance. If something is colored, it means something.
3. **Taps, not forms.** The primary interactions are cells, chips and steppers. Forms appear only in bottom sheets, and only for money entry.
4. **Bangla sets the rhythm.** Line heights are tuned for the Bengali matras and conjuncts, and English inherits them.

## Color
Strategy: **Restrained**. Neutrals plus one accent. The use scene is a bachelor mess room under a tube light or late at night with the phone dimmed. Light is the default, dark is a first-class scheme, and System is the default setting.

| Role | Light | Dark | Use |
|---|---|---|---|
| `bg` | `#FAFAF9` | `#0F0F0E` | Scaffold |
| `surface` | `#FFFFFF` | `#181817` | Cards, sheets |
| `surfaceMuted` | `#F3F3F1` | `#201F1E` | Grid header, disabled fields, segmented track |
| `border` | `#E6E5E2` | `#2C2B29` | Hairlines (1 px) |
| `borderStrong` | `#CFCECA` | `#3D3C39` | Input outline, focused cell |
| `ink` | `#141413` | `#F2F1EE` | Primary text, filled primary button |
| `onInk` | `#FAFAF9` | `#141413` | Text on a filled primary |
| `inkSecondary` | `#5C5B57` | `#A9A7A2` | Secondary text (≥ 4.5:1 on bg) |
| `inkTertiary` | `#6F6E6A` | `#8D8B86` | Proof lines, captions (≥ 4.5:1) |
| `accent` | `#C98A0B` | `#E8B33A` | Turmeric: the today marker, the live/syncing dot, AI drafts. Never body text on light. |
| `accentSoft` | `#FBF1DC` | `#3A2E12` | AI draft row background, today column wash |
| `due` | `#B42318` | `#F97066` | Negative balances, errors |
| `advance` | `#067647` | `#47CD89` | Positive balances, success |
| `warning` | `#B54708` | `#FDB022` | Offline-failed, month warnings |

These map to the M3 `ColorScheme` as follows: primary is `ink`, onPrimary is `onInk`, surface is `surface`, outline is `border`, outlineVariant is `borderStrong`, error is `due`, and tertiary is `accent`. Dynamic Color is **off** because the brand is monochrome.

## Type
Font: **Hind Siliguri** (OFL), bundled at 400, 500 and 600. It covers both Bengali and Latin, so one face serves both scripts. Fonts are bundled rather than fetched at runtime, which keeps the app offline-first. All sizes are in sp. Numbers use **tabular figures**.

| Role (M3) | Size / line height | Weight | Use |
|---|---|---|---|
| displaySmall | 34 / 1.15 | 600 | The headline figure (today's meals, a balance) |
| headlineSmall | 24 / 1.25 | 600 | Screen titles, the date |
| titleMedium | 18 / 1.35 | 600 | Section titles, sheet titles |
| titleSmall | 16 / 1.4 | 600 | List row primary text |
| bodyLarge | 16 / 1.55 | 400 | Body |
| bodyMedium | 14 / 1.5 | 400 | Secondary body, proof lines |
| labelLarge | 15 / 1.3 | 500 | Buttons |
| labelMedium | 13 / 1.3 | 500 | Chips, grid headers |
| labelSmall | 12 / 1.3 | 500 | Captions, sync status |

Headings use sentence case. There are no eyebrows or kickers above headings.

## Space, shape, depth
- **Spacing** (4 dp base): `xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32 · xxxl 48`. The screen gutter is 16. There is more space above a section title than below it (24 above, 12 below).
- **Radius**: `sm 8` (inputs, chips, grid cells) · `md 12` (cards, buttons) · `lg 20` (bottom sheet top corners). The FAB is 16.
- **Depth**: flat surfaces separated by hairline borders. A shadow appears only on floating layers (sheets, menus, snackbars), with a y-offset of 4 and a blur of 16 at 8–12% ink. Cards are never nested.
- **Touch**: at least 48 × 48 dp, with 8 dp between targets. Meal grid cells are 52 × 48.

## Components (single implementation each, in `app/lib/core/widgets/`)
| Widget | Spec |
|---|---|
| `AppButton` | Variants: `primary` (filled ink), `secondary` (1 px outline), `text`. Height 48, radius 12. Has a loading state (spinner replaces the label at the same width) and a disabled state at 38% opacity. |
| `AppCard` | A surface with a 1 px border, radius 12 and 16 padding. Optional `onTap` with an ink ripple. |
| `AppSheet.show()` | A modal bottom sheet with a drag handle, a title, a scrollable body and a sticky action row. It respects the keyboard (IME) inset. |
| `Figure` | A large tabular number with a label and an optional **proof line**. Tapping expands the proof. Colored only for due/advance. |
| `Money` | Formats ৳ in Bangla or Latin digits with tabular figures, and colors itself by sign when `signed: true`. |
| `MealCell` (Phase 2) | A tap cycles 1 → ½ → 0. A long press opens Off / Guest / custom. *Off* renders as a struck-through dash, and *Guest* adds a small `+n`. Today's column carries the accent wash. |
| `SyncBadge` | A dot plus a label. Synced is quiet ink-tertiary with no dot. Syncing shows an accent dot that pulses. Offline shows a hollow dot ("অফলাইনে সেভ হয়েছে"), which is calm and never red. Failed shows a warning dot plus a Retry action. |
| `LoadingView` / `EmptyView` / `ErrorView` | Every screen uses these three. Empty states name the next action ("+ আজকের মিল যোগ করুন"). Errors name the problem and the recovery, with a Retry button. Skeletons are hairline blocks, not shimmer. |
| Snackbar | M3 floating snackbar, ink background. Used for transient feedback such as an undo after a delete. |

## Navigation
An M3 `NavigationBar` with 4 destinations: **আজ (Today) · মিল (Meals) · হিসাব (Money) · আরও (More)**. Bazar, expenses and deposits live under হিসাব. Quick actions open on the Today screen as sheets. The system Back gesture is honored everywhere, and the app runs edge-to-edge with insets.

## Motion
- One authored moment: the **proof reveal**. A figure's proof line rises 8 dp and fades in over 220 ms with an emphasized-decelerate curve.
- Everything else uses M3 defaults: sheets slide up, pages use shared-axis transitions. Cell taps get only a 120 ms value crossfade.
- When the system's *Remove animations* setting is on, all of this becomes an instant cut.

## Copy
Bangla first, in plain spoken Bangla rather than official Sanskritised Bangla: "মিল", "বাজার", "জমা", "বাকি", "অগ্রিম". Controls name their action ("মিল সেভ করুন", not "ঠিক আছে").
