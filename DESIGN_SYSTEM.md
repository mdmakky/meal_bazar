# Design System

<!-- Direction contract (impeccable, seed 66828936, chosen: monochrome product canon, fused with Meal Bazar)
THESIS: Numbers you can trust at a glance. Every figure carries its proof. Refuses the green-card fintech dashboard.
OWN-WORLD: A fine neutral scale from near-white to near-black. Primary actions are filled in ink. One turmeric accent marks "live/today/AI" only. Hairline borders, no gradients, no nested cards. Hind Siliguri at three weights.
STORY: The manager opens the app, reads today's state in one glance, taps meals, sees the totals and their proof update, and is done.
FIRST VIEWPORT (Today): a large Bangla date, the day's meal total as the headline figure with its proof line, the member × meal tally grid, and the quick actions in thumb reach.
FORM: monochrome canon (user-chosen challenger over the assigned "mobile-money slip"); seed key 66828936.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, and DESIGN.md
PREMIUM v2 (owner: "too generic, no animation or style, must feel premium"): KEEP the identity (monochrome ink #141413 on warm near-white, Hind Siliguri, turmeric only for live/today/AI) and RAISE it with depth (warm page, raised white cards, one ink statement card per screen), heavier display figures, and authored motion: the RollingNumber odometer is the signature, the StampMark is the brand moment. Still refused: decorative gradients, glass/blur, neon, a new palette, continuous animation (except the sync dot while syncing).
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
| `bg` | `#F7F6F3` | `#0F0F0E` | Scaffold (v2: warmed so raised white cards lift) |
| `surface` | `#FFFFFF` | `#181817` | Cards, sheets |
| `surfaceRaised` | `#FFFFFF` | `#1E1E1C` | Raised cards (with `AppElevation.raised`) |
| `surfaceInk` | `#141413` | `#23221F` | The statement card. Dark mode is a raised surface, not an inversion |
| `surfaceInkBorder` | `#2C2B29` | `#3A3936` | Hairline on/inside the statement card (drawn as its outline in dark) |
| `shadow` | `#141413` @ 6% | `#000000` @ 32% | Tint for `AppElevation` shadows |
| `surfaceMuted` | `#F0EFEC` | `#201F1E` | Grid header, disabled fields, segmented track |
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
- **Radius**: `sm 8` (inputs, chips, grid cells) · `md 12` (cards, buttons) · `lg 20` · `xl 24` (statement cards, bottom sheet top corners). The FAB is 16.
- **Depth** (v1; v2 adds raised and statement cards, see Premium v2): flat surfaces separated by hairline borders. A shadow appears only on floating layers (sheets, menus, snackbars), with a y-offset of 4 and a blur of 16 at 8–12% ink. Cards are never nested.
- **Touch**: at least 48 × 48 dp, with 8 dp between targets. Meal grid cells are 52 × 48.

## Components (single implementation each, in `app/lib/core/widgets/`)
| Widget | Spec |
|---|---|
| `AppButton` | Variants: `primary` (filled ink), `secondary` (1 px outline), `text`. Height 48, radius 12. Has a loading state (spinner replaces the label at the same width) and a disabled state at 38% opacity. |
| `AppCard` | A surface with a 1 px border, radius 12 and 16 padding. Optional `onTap` with an ink ripple. |
| `AppSheet.show()` | A modal bottom sheet with a drag handle, a title, a scrollable body and a sticky action row. It respects the keyboard (IME) inset. |
| `Figure` | A large tabular number with a label and an optional **proof line**. Tapping expands the proof. Colored only for due/advance. |
| `Money` | Formats ৳ in Bangla or Latin digits with tabular figures, and colors itself by sign when `signed: true`. |
| Meal stepper grid | `− value +` per cell (28 dp circles in 40 × 56 dp hit areas). A tap on the value cycles 0 → 0.5 → 1 → 1.5 → 2 → 0; −/+ step 0.5 (0–5); long press opens Off / Guest / custom. Values are decimals (০.৫). Name column pinned; meal columns scroll sideways when they do not fit. |
| `MealCell` (read-only views) | A tap cycles 1 → ½ → 0. A long press opens Off / Guest / custom. *Off* renders as a struck-through dash, and *Guest* adds a small `+n`. Today's column carries the accent wash. |
| `SyncBadge` | A dot plus a label. Synced is quiet ink-tertiary with no dot. Syncing shows an accent dot that pulses. Offline shows a hollow dot ("অফলাইনে সেভ হয়েছে"), which is calm and never red. Failed shows a warning dot plus a Retry action. |
| `LoadingView` / `EmptyView` / `ErrorView` | Every screen uses these three. Empty states name the next action ("+ আজকের মিল যোগ করুন"). Errors name the problem and the recovery, with a Retry button. Skeletons are hairline blocks, not shimmer. |
| Snackbar | M3 floating snackbar, ink background. Used for transient feedback such as an undo after a delete. |

## Navigation
An M3 `NavigationBar` with 5 destinations: **হোম (Home, `/today`) · মিল (Meals) · বাজার (Bazar) · হিসাব (Money) · আরও (More)**. Meals are entered on মিল (member × meal stepper grid); হোম shows the day in brief with a "মিল বসান" link. Expenses and deposits live under হিসাব. Quick actions open on হোম and from the মিল FAB as sheets. The system Back gesture is honored everywhere, and the app runs edge-to-edge with insets.

## Motion
- v1 below; **Premium v2** (end of this file) adds the RollingNumber signature, the StampMark, and the navigation motion.
- One authored moment: the **proof reveal**. A figure's proof line rises 8 dp and fades in over 220 ms with an emphasized-decelerate curve.
- Everything else uses M3 defaults: sheets slide up, pages use shared-axis transitions. Cell taps get only a 120 ms value crossfade.
- When the system's *Remove animations* setting is on, all of this becomes an instant cut.

## Copy
Bangla first, in plain spoken Bangla rather than official Sanskritised Bangla: "মিল", "বাজার", "জমা", "বাকি", "অগ্রিম". Controls name their action ("মিল সেভ করুন", not "ঠিক আছে").

## Premium v2

The identity is unchanged; the finish is raised. Everything below lives in `app/lib/core/theme/` (colour, type, elevation) and `app/lib/core/motion/` (motion), and is exported through `core/widgets/widgets.dart`.

### Surfaces and depth
Three surfaces, one rule: **one statement card per screen**, never nested cards.

| Surface | Widget | Look | Use |
|---|---|---|---|
| Plain | `AppCard(...)` | `surface`, 1 px `border`, radius 12 | Lists, settings, secondary groups |
| Raised | `AppCard.raised(...)` | `surfaceRaised`, no outline, `AppElevation.raised`, radius 12 | Primary content cards on the warm page |
| Statement | `AppCard.ink(...)` | `surfaceInk`, radius **24**, padding 24, `AppElevation.raised`; dark adds a `surfaceInkBorder` hairline | The screen's headline figure (today's meals, my balance, the month's rate) |

Inside `AppCard.ink` the whole subtree is re-themed with `AppTheme.statement(brightness)`, built from `AppPalette.statement` (the dark scheme's ink, accent and due/advance on the card's surface). Children use `Theme.of(context).textTheme` and `context.palette` as usual and get legible colours; never hard-code `onInk`. Turmeric on the card still means live/today only.

**Elevation** is layered soft shadows, offsets and blur only (no spread, no zero-offset halos):
- `AppElevation.raised(p)`: `0 1 2` + `0 8 24` at `shadow`.
- `AppElevation.button(p)`: `0 1 2` + `0 4 12`. Light theme only (shadows are invisible on dark; dark relies on surface steps).

**Radius**: `sm 8 · md 12 · lg 20 · xl 24 (statement cards, sheet tops) · fab 16`.

### Type
| Role | Size / line height | Weight | Tracking | Use |
|---|---|---|---|---|
| displayLarge | 44 / 1.05 | 600 | −0.5 (Latin digits), 0 (Bangla digits) | The statement figure |
| displaySmall | 34 / 1.15 | 600 | −0.25 | Secondary hero figures |
| titleLarge | 20 / 1.3 | 600 | −0.1 | Section titles (stronger than v1's titleMedium) |
| `AppType.overline(context)` | 12 | 600 | 0.6 English, 0 Bangla | Labels over a figure inside a card. Not a kicker above a heading. |

Every text role carries **tabular figures**. Tracking breaks Bengali conjuncts, so anything that tracks must reset to 0 for Bangla: `AppType.figure(style, banglaDigits: ...)` does it for figures, and `RollingNumber` does it automatically.

### Motion tokens (`AppMotion`)
| Token | Value | Use |
|---|---|---|
| `fast` | 120 ms | Press-in, value pop, loading cross-fade |
| `base` | 220 ms | State changes, staggered row entrance, proof reveal |
| `slow` | 360 ms | The number roll, the nav dot slide |
| `page` / `tab` | 280 / 210 ms | Shared-axis push / fade-through tabs |
| `chip` / `stamp` | 180 / 260 ms | Chip selection / stamp landing |
| `arrive` | `Easing.emphasizedDecelerate` | Anything entering |
| `state` | `Easing.standard` | Anything changing in place |
| `exit` | `Easing.emphasizedAccelerate`, at `exitOf(d)` = 70% | Anything leaving |

Rules: transform and opacity only (plus clip); `RepaintBoundary` around anything that animates often; no `BackdropFilter`, no `saveLayer`-heavy effects; **no continuous animation** except the sync dot while syncing (the skeleton pulse stops by itself after ~20 s). Every widget reads `AppMotion.of(context, d)` / `AppMotion.reduced(context)`, so the system *Remove animations* setting gives an instant cut everywhere.

### The signature: `RollingNumber`
Numbers you can trust *move* like a counter. When a figure changes, each changed digit rolls in its own clipped cell, odometer style: **up when the value grows, down when it shrinks**, the rightmost digit first and each step left 30 ms later (360 ms + stagger, emphasized decelerate). Signs, ৳, separators, decimals (০.৫) and Bangla digits roll with the rest. Colour (due/advance) cross-fades. At rest it is one plain `Text`; with *Remove animations* the value simply swaps.

```dart
RollingNumber.money(balance, signed: true, banglaDigits: bn, style: t.displayLarge)
RollingNumber(totalMeals, decimals: 1, banglaDigits: bn, style: t.displayLarge)
```
Use it for every headline figure that can change while the screen is open (today's meals, balances, the meal rate). Static lists keep `Money` / `Text`.

### The brand moment: `StampMark`
When something is settled or closed, it gets stamped: `StampMark('পরিশোধিত')`, `StampMark('বন্ধ')`. An outlined ink (or `accent: true` turmeric) stamp, rotated −8°, lands from 1.4× with a slight overshoot in 260 ms and a medium haptic. It plays once on mount; pass `animate: false` when re-showing an already-settled state. Reserve it for these moments only.

### Supporting motion
| Widget | Behaviour |
|---|---|
| `PressableScale(child, haptic:)` | 0.96 while pressed (raw pointers, so the child keeps its tap), optional selection click. `AppButton` uses it. |
| `PopOnChange(value:, child:)` | 1.0 → 1.12 → 1.0 in 120 ms when `value` changes: stepper values, counters. |
| `StaggeredList(child:)` + `StaggeredList.wrap(rows)` / `Stagger(index:)` | First build only: up to 8 rows, 30 ms apart, fade + 8 dp rise. Rows mounted later appear as-is. |
| `AnimatedSyncDot(color:, active:)` | The sync dot; breathes only while active. `SyncBadge` uses it. |
| `SkeletonPulse` / `SkeletonBox` | Calm pulse (opacity .55 ↔ 1, 1200 ms) on muted blocks shaped like the content. `LoadingView` is the default shape. |

### Navigation motion
- **Pushed routes**: shared axis X (`SharedAxisPageTransitionsBuilder`, 280 ms): the new page slides 30 dp in and fades over the old one, which drifts 30 dp back. Installed for Android in `pageTransitionsTheme`; iOS keeps Cupertino for its edge swipe.
- **Tabs**: fade-through (`FadeThroughBranches`, 210 ms): the old tab fades out in the first 35%, the new one fades in from 92% scale. Branch state is kept, inactive tickers are paused.
- **`AppNavBar`**: M3 anatomy (5 destinations, pill over the icon, label below, 80 dp, ≥ 48 dp targets, selected semantics). The active pill fills with ink (180 ms) and **one turmeric dot slides under it** to the new tab (360 ms).

### Components (v2 deltas)
- `AppButton`: presses scale; loading cross-fades label → spinner at the same width; primary is filled ink with `AppElevation.button` on light; secondary is raised white with a hairline.
- Chips (theme): unselected raised white + hairline; selected fills ink with an onInk check that slides in (~180 ms).
- `AppSheet.show`: 24 dp top corners, drag handle 36 × 4, 400 ms emphasized-decelerate entrance (a spring without the bounce), 70% exit.
- `AppSnack.show(context, msg, icon:, actionLabel:, onAction:)`: floating ink pill (stadium) with an icon; content rises 8 dp; action in turmeric.
