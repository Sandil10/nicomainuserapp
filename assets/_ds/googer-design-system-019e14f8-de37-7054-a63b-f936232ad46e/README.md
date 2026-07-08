# Googer — Design System

> Source: GitHub `Sandil10/googernew` (Next.js + Express + PostgreSQL). The user has access; this design system was extracted from the live codebase, not screenshots.

## What is Googer?

**Googer** is a social-commerce mobile/web app. It combines short-form social posts ("googs"), a marketplace, a wallet with peer-to-peer transfers and coin economy, real-time chat with calls, and a self-serve ads platform — all in one dark, premium-feeling product.

The brand reads as **bold, late-night, mobile-first**. Pure black canvas, white type, a single saturated purple for identity and a sharp blue for utility. The signature typographic move is tiny, black-weight, uppercase labels with very wide tracking — `text-[10px] font-black uppercase tracking-widest` appears everywhere from nav items to receipts.

## Products represented

The codebase ships a single product made of several surfaces. The UI kits in `ui_kits/` cover the most visually distinct ones:

| Surface | Codebase location | What it is |
| --- | --- | --- |
| **Auth** | `app/page.tsx`, `app/register/` | Black card + purple-glow login, OTP reset flow. |
| **Feed (Googs)** | `app/dashboard/page.tsx`, `app/components/googs/GoogCard.tsx` | Vertical feed of text posts with link previews, likes/comments/views/shares. |
| **Shop** | `app/dashboard/shop/`, `app/components/market/` | Product grid, promoted items, second-view modal, cart sidebar. |
| **Wallet** | `app/dashboard/wallet/` | Balance, transfers, coins, top-up, withdrawal, transactions. |
| **Chats** | `app/dashboard/chats/page.tsx` | Conversation list, DMs, presence, audio/video calls. |
| **Ad Campaigns** | `app/dashboard/ad-campaign/` | Photo/video, product promote, profile promote. |

## Sources

- **Codebase:** https://github.com/Sandil10/googernew — branch `main` (commit `55da9ec8…` at time of extraction).
- **Brand assets imported:** `app/page.tsx`, `app/layout.tsx`, `app/globals.css`, `app/components/{IonIcon,Sidebar,Topbar,googs/GoogCard}.tsx`, all images from `public/assets/images/`.

---

## Index — what's in this folder

| File / folder | Purpose |
| --- | --- |
| `README.md` | This file. Brand, content, visual, iconography. |
| `SKILL.md` | Cross-compatible Agent Skill manifest. |
| `colors_and_type.css` | All CSS variables: surfaces, borders, accents, type scale, motion, radii, shadows. |
| `assets/` | Logo, coin renders, ad pattern, favicon, sample reference photo. |
| `fonts/` | Geist Sans / Geist Mono via Google Fonts (no local TTFs — see Visual Foundations). |
| `preview/` | Design-system cards rendered into the Design System tab. |
| `ui_kits/auth/` | Login + OTP reset flow recreation. |
| `ui_kits/feed/` | Goog cards, composer, sidebar, topbar — the social surface. |
| `ui_kits/shop/` | Product grid, product card, cart sidebar. |
| `ui_kits/wallet/` | Balance card, transactions, coins. |

---

## CONTENT FUNDAMENTALS

**Voice.** Googer talks like a confident, slightly utilitarian app. It does not speak in marketing voice. It rarely uses "we" or "you" in product copy — labels are noun-first ("Wallet", "Cart", "Chats", "Posts", "Following", "Followers"). When it does address the user, it's terse and instructional ("Enter Email", "Enter Password", "Send OTP Code", "Verify & Continue", "Update Password").

**Casing.**
- **Title Case** is used for primary CTA labels: `Login`, `Register`, `Send OTP Code`.
- **UPPERCASE + WIDE TRACKING** is the dominant micro-label style for nav, status chips, table headers, transaction types, and overline tags. e.g. `HOME`, `SHOP`, `WALLET`, `CHATS`, `NOTIFICATIONS`, `CLEAR ALL`, `PHOTO AND VIDEO`, `PRODUCT PROMOTE`.
- **Lowercase** is used for handles only (`@username`).

**Tone.** Direct, short, no chit-chat. Empty states are blunt: "No notifications yet", "No messages yet". Errors lean factual: "Login failed. Please check your credentials." Marketing-y language is absent.

**Person.** Mostly the implicit second person via imperatives ("Enter…", "Verify…", "Update…"). No "Welcome back, friend." No exclamation points outside of system success states ("Password Reset Success!").

**Emoji.** Effectively never. The codebase contains zero emoji in UI strings. Iconography is handled by **ionicons** instead.

**Numbers, currency.**
- Counts on interactions are unitless and abbreviated implicitly by the backend (just `0`, `1`, `42` — no `k`/`m` post-processing seen).
- Money is shown as raw integers next to icons (`coin.png`, `rupee.png`). No `$` symbol.

**Specific copy examples.**
- Login subtitle: `Don't have an account? — Register`
- OTP screen: `We've sent a 6-digit code to <br/> <email>`
- Profile-menu header is just three stat columns: `Posts | Following | Followers` with the count above and the label below in 10px gray.
- Notification empty: `No notifications yet`.
- Chat preview fallback: `Sent an image`, `Call update`, `New message`.

---

## VISUAL FOUNDATIONS

### Palette

| Token | Hex | Where it shows up |
| --- | --- | --- |
| `--bg-0` | `#000000` | Page canvas, auth, modal backdrops. |
| `--bg-1` | `#18181b` | Sidebar, topbar (with `/80` opacity + `backdrop-blur-md`). |
| `--bg-2` | `#121212` | Form inputs. |
| `--bg-3` | `#1e1e24` | Notification dropdown. |
| `--bg-5` | `#162033` | User-menu popover (very slight cool tint). |
| `--border-1` | `#27272a` | Primary horizontal divider. |
| `--accent` | `#a855f7` | Purple-500 — identity (logo glow, auth borders, reset modal). |
| `--utility` | `#2563eb` | Blue-600 — cart open, nav active. |
| `--like` | `#ef4444` | Red-500 — filled heart. |
| `--success` | `#22c55e` | Green-500 — password screen, top-up success. |
| `--pink` | `#ec4899` | Pink-500 — notification unread dot, sits between purple→blue in promo gradient. |

The product is **monochrome by default**. Color is used surgically: a 20%-opacity purple border ringing the auth card, a glow shadow behind it, a blue pill on cart-open, a pink dot on the bell when there are notifications. The promo gradient (`purple-600 → pink-500 → blue-500`) appears only on the user-menu card top bar — it's a deliberate accent, not a wallpaper.

### Type

- **Sans:** Geist (300/400/500/600/700/800/900). **The 800 and 900 weights are heavily used** — Googer leans on weight rather than size for hierarchy.
- **Mono:** Geist Mono — code/transaction IDs.
- **Substitution flagged:** the codebase loads Geist via `next/font/google`, so it's already a Google Font — no TTF swap needed. `fonts/` is intentionally empty; we link Google Fonts directly in `colors_and_type.css`.

The signature pattern: `text-[10px] font-black uppercase tracking-widest text-slate-400`. Use it for nav, chip labels, table headers, overlines.

### Spacing & density

Tailwind defaults (`gap-2`, `gap-3`, `gap-4`) dominate. Container padding lands on `p-4` (16px) for mobile cards and `p-8` (32px) for auth cards. Chat rows and feed cards use `px-5 py-5` to `px-7 py-5`. Density is medium — not the cram of a trading UI, not the airy of a marketing page.

### Backgrounds

- **No imagery in chrome.** No hero photos. No illustration. The canvas is black.
- **Decorative pulse:** modal cards include a single `bg-purple-500/10 blur-3xl rounded-full` orb tucked under the top corner. This is the only "ambient" treatment used.
- **ad_pattern.png** is a subtle dotted texture used only inside the ad center card body.
- **No gradients on backgrounds** — the only gradient is the user-menu top bar (purple→pink→blue).

### Animation

- **Standard fades & rises.** Globals define `fadeIn`, `slideIn` (translateY 20→0), `googerActionBarDrop` (translateY -12 + scale 0.98 → 0), `googerActionBarSheet` (translateY 22 + scale 0.97 → 0), `googerModalRise` (translateY 18 + scale 0.985 → 0). Durations are 300–500ms.
- **No bounce** except `googerWrite` (a subtle rotate wobble for the in-progress "writing a goog" indicator).
- Easing is mostly `ease-out`; the close-X button rotates 90° on hover.

### Interaction states

- **Hover:** `bg-white/5` on dark surfaces; text shifts from `gray-400 → white`. Icons may `scale-110` inside their group. The auth profile-image border lifts from `white/10 → purple-500/50`.
- **Press / active:** **`active:scale-[0.97]`** is the universal press feedback for buttons. Interaction icons (heart, comment, etc.) use a stronger **`active:scale-75`**.
- **Focus:** Caret is hidden globally (`caret-color: transparent`) and only re-enabled on inputs. Focus ring is a 1px `purple-500/50` (auth) or `green-500/50` (new-password) shadow ring — no chunky outline.

### Borders

- Default border on a dark card: `border border-white/10`.
- Inputs: `border border-gray-800` (`#1f2937`).
- Dividers: `border-[#27272a]`.
- Accent borders: `border border-purple-500/20` (auth), `border border-green-500/20` (success state).
- Icon-button avatar wells: `border-4 border-[#162033]` (matches user-menu bg).

### Shadows / glow

- Auth & reset modal carry a custom shadow: `shadow-[0_0_50px_-12px_rgba(168,85,247,0.1)]` — a soft purple halo, never a black drop-shadow.
- Active nav pill: `shadow-lg shadow-white/5` — a barely-there white halo.
- Active cart: `shadow-lg shadow-blue-600/20`.
- Cards use `shadow-2xl` (Tailwind preset) when they pop above the surface (notification dropdown, user menu).

### Transparency & blur

- Topbar: `bg-[#18181b]/80 backdrop-blur-md`.
- Modal backdrop: `bg-black/90 backdrop-blur-md`.
- Inline hover: `bg-white/[0.025]` to `bg-white/[0.07]`.

### Radii

- **Pill / fully-round** for primary buttons (`rounded-full`) and avatars.
- **3xl (24px)** for cards in dialog/auth context.
- **2xl (16px)** for popovers, menu cards, info chips.
- **xl (12px)** for inputs, nav pills, link-preview rows.
- **lg (8px)** for inline menu rows.

### Cards

Two flavors. (1) **Chrome card** — `bg-[#1e1e24]` or `bg-[#111114]` + `border-white/10` + `rounded-2xl` + `shadow-2xl`. Notification dropdowns, profile menu. (2) **Hero card** — pitch black + accented purple border + purple glow shadow + `rounded-3xl`. Auth, reset modal.

### Layout rules

- **Fixed topbar** (`h-16`) and **fixed sidebar** (`w-64` expanded / `w-20` collapsed). The sidebar collapses via a small `-right-3` floating chevron pill — a recognizable Googer detail.
- Content scrolls under the topbar's blur.
- Mobile: bottom search portal + scrollable nav strip; topbar is the only fixed chrome.

### Color vibe of imagery

User-uploaded photos render in their native palette — there's no filter applied. The coin/rupee renders are gold-pink, slightly painterly 3D — they read as "currency" not "tokens". The reference photo (`rp.jpg`) shows the product handles full-color landscape imagery without grading.

---

## ICONOGRAPHY

**The system uses [Ionicons 7.1.0](https://ionic.io/ionicons) loaded from unpkg CDN** (`https://unpkg.com/ionicons@7.1.0/dist/ionicons/ionicons.esm.js`). Every icon in the UI is `<ion-icon name="...">`. There is no local sprite, icon font, or custom SVG library — the codebase wraps `<ion-icon>` in a small client-only React component (`IonIcon.tsx`) to dodge hydration.

**Pattern:** outline by default, filled on active.
- `home-outline` → `home` when the route matches.
- `heart-outline` → `heart` when liked.
- `cart-outline` → `cart` when cart-open.
- `chatbubble-outline` → `chatbubble` on long-press / focus.
- `notifications-outline` → `notifications` when panel open.

**Common icon set used (verbatim from the codebase):** `home`, `bag`, `wallet`, `chatbubbles`, `cart`, `notifications`, `add-circle`, `eye-outline` / `eye-off-outline`, `mail-outline`, `keypad-outline`, `lock-closed-outline`, `close-outline`, `chevron-back-outline` / `chevron-forward-outline` / `chevron-up-outline`, `person-outline`, `log-out-outline`, `heart` / `chatbubble` / `eye` / `share-social`, `images`, `cube`, `play`, `videocam`, `open-outline`, `notifications-off-outline`, `checkmark-circle`, `information-circle`.

**Emoji.** Not used in product UI. Don't introduce any.

**Unicode-as-icon.** The login link uses an em-dash glyph (`— `) as a visual separator between "Don't have an account?" and the Register link. That's the closest the system gets to unicode-as-icon — keep it.

**Custom imagery.** The only non-icon raster art is the **Googer wordmark logo** (`assets/googer.png`) — a black-fill stylized "G" inside a play-triangle silhouette, on transparent background. It's used as a circular avatar mark, never as a wordmark. The `coin.png`, `coin.gif`, `coins.png`, and `rupee.png` are 3D-rendered currency renders used inside the wallet.

**For agents building with this system:** keep using Ionicons via CDN. Match `name-outline` / `name` pairs. Do not draw SVGs by hand and do not introduce emoji. If an icon is missing from Ionicons, flag the gap rather than substitute a different family.
