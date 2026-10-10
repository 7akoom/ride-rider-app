---
name: Everyday Mobility Iraq
colors:
  surface: '#faf8ff'
  surface-dim: '#d9d9e6'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f2ff'
  surface-container: '#ededfa'
  surface-container-high: '#e7e7f4'
  surface-container-highest: '#e1e1ee'
  on-surface: '#191b24'
  on-surface-variant: '#4d463a'
  inverse-surface: '#2e303a'
  inverse-on-surface: '#f0f0fd'
  outline: '#7e7669'
  outline-variant: '#cfc5b6'
  surface-tint: '#715b2c'
  primary: '#715b2c'
  on-primary: '#ffffff'
  primary-container: '#f3d59a'
  on-primary-container: '#715b2c'
  inverse-primary: '#e0c389'
  secondary: '#5c5e69'
  on-secondary: '#ffffff'
  secondary-container: '#dedfec'
  on-secondary-container: '#60626d'
  tertiary: '#78591c'
  on-tertiary: '#ffffff'
  tertiary-container: '#fcd389'
  on-tertiary-container: '#77591c'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#fddfa3'
  primary-fixed-dim: '#e0c389'
  on-primary-fixed: '#261a00'
  on-primary-fixed-variant: '#584416'
  secondary-fixed: '#e1e2ee'
  secondary-fixed-dim: '#c5c6d2'
  on-secondary-fixed: '#191b24'
  on-secondary-fixed-variant: '#444651'
  tertiary-fixed: '#ffdea7'
  tertiary-fixed-dim: '#e9c179'
  on-tertiary-fixed: '#271900'
  on-tertiary-fixed-variant: '#5d4203'
  background: '#faf8ff'
  on-background: '#191b24'
  surface-variant: '#e1e1ee'
  canvas-base: '#F9F8F5'
  surface-white: '#FFFFFF'
  surface-inset: '#F2EFEB'
  border-hairline: '#E5E2DC'
  ink-secondary: '#5C606E'
  status-success: '#1B5E3B'
  status-success-bg: '#E8F3EC'
  status-warning: '#B35C00'
  status-warning-bg: '#FFF4E5'
  status-error: '#9E1C1C'
  status-error-bg: '#FDF2F2'
typography:
  headline-xl:
    fontFamily: IBM Plex Sans
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: IBM Plex Sans
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: IBM Plex Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: IBM Plex Sans
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: IBM Plex Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: IBM Plex Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: IBM Plex Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: IBM Plex Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: IBM Plex Sans
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 18px
  label-sm:
    fontFamily: IBM Plex Sans
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
  numeral-price:
    fontFamily: IBM Plex Sans
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 22px
    letterSpacing: -0.01em
  plate-display:
    fontFamily: IBM Plex Sans
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 18px
    letterSpacing: 0.08em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

This design system defines an everyday ride-hailing experience across Iraq and the Kurdistan Region (Erbil, Baghdad, Sulaymaniyah, Basra, and connecting urban hubs). Designed for universal accessibility and daily transit—neighborhood errands, airport commutes, daily work travel, and city taxis—the interface balances approachability with clean, calm composure.

- **Brand Personality**: Trustworthy, clear, calm, and dependable. The experience eliminates anxiety around fare accuracy, driver reliability, and navigation in dense traffic corridors without presenting itself as an exclusive or distant service.
- **Target Audience**: Everyday riders across Iraq, ranging from students and commuting professionals to families hailing standard taxis and city-to-airport travelers.
- **Emotional Response**: Dependability, safety, clarity, and ease. Every interaction feels functional, rapid, and grounded.
- **Visual Style**: Clean, modern utility with subtle warm tones. High readability, low glare in direct sunlight, and high contrast for night travel.
- **Script & Cultural Posture**: Right-to-Left (RTL) is the baseline across all viewports. Bidirectional content (Iraqi vehicle license plates, Western Arabic numerals for fares, phone numbers, and location identifiers) maintains strict inline layout discipline.

## Colors

The color palette centers on functional contrast and warm visibility across day and night driving conditions.

- **Primary Accent (`#F3D59A`)**: Solid warm gold. Used consistently across the entire app as the primary action trigger fill.
- **Secondary Ink (`#05070F`)**: Deep obsidian night ink. Deployed for dominant typography, headers, icons, and secondary filled buttons.
- **Accent Structural (`#8A6A2B`)**: Deep antique gold for interactive text links, selected state borders, and active map route paths, meeting WCAG AA requirements over light canvases.
- **Neutral Canvas (`#F9F8F5`)**: Non-fatiguing warm off-white that reduces eye strain under direct daytime sun.
- **Surfaces (`#FFFFFF` & `#F2EFEB`)**: Layer 1 white for floating ride-selection cards and bottom sheets; Layer 2 inset for search fields and inactive control chips.
- **Border Hairline (`#E5E2DC`)**: Neutral structural stroke bounding components without heavy drop shadows.

## Typography

Typography relies on **IBM Plex Sans** accompanied by its native **IBM Plex Sans Arabic** glyph set to deliver a clear, technical, and open reading experience.

### BiDi & Script Rules
- **Text Alignment**: Default layout flow is strictly Right-to-Left (`dir="rtl"`). All titles, instructions, vehicle descriptions, and navigation hints align right.
- **Numerals & Pricing**: Numerical pricing always renders in Western digits inside `dir="ltr"` inline containers (e.g., `4,500 د.ع`), with the Iraqi Dinar currency mark (`د.ع`) trailing in Arabic reading order.
- **Phone Numbers**: Verification and driver contact numbers (e.g., `+964 750 XXX XXXX`) are isolated in `dir="ltr"` wrappers to prevent punctuation flipping.
- **Distance & ETAs**: Standard format reads numeral first followed by the unit (`5 دقائق`, `3.8 كم`).

## Layout & Spacing

Spacing is anchored to a standard 4px rhythm, calibrated for single-handed mobile navigation on standard smart devices (390px baseline width).

- **Margins & Gutters**: Outer mobile canvas margins are fixed at `20px` (`margin`). Inner card gutters and list margins follow `16px` (`gutter`).
- **Screen Flow**: Fluid column allocation on mobile with safe top padding (48px for status bar and camera cutouts) and bottom safe padding (34px for home indicators).
- **Responsive Tablet Adaptation (768px+)**: The layout docks a 380px fixed-width interaction panel along the right viewport boundary (preserving natural RTL interaction), keeping the rest of the canvas open for map rendering.

## Elevation & Depth

Visual hierarchy uses crisp boundaries and subtle tonal separation rather than heavy or dark dropshadows.

- **Level 0 (Base Canvas)**: Neutral surface `#F9F8F5` and map layer.
- **Level 1 (Docked Containers & Inputs)**: `#FFFFFF` or `#F2EFEB` with a `1px solid #E5E2DC` boundary stroke. No elevation shadow.
- **Level 2 (Active Sheets & Cards)**: Bottom ride drawers and floating address panels use `#FFFFFF`, a `1px solid #E5E2DC` border, and an ambient lift: `0 8px 24px -4px rgba(5, 7, 15, 0.08), 0 2px 6px -1px rgba(5, 7, 15, 0.03)`.
- **Level 3 (Alerts & Confirmations)**: Modal alerts over a `rgba(5, 7, 15, 0.45)` scrim with `backdrop-filter: blur(8px)`.

## Shapes

The design system maintains a structured, friendly geometry using soft, functional radii.

- **Standard Controls (12px - 14px)**: Buttons, inputs, search bars, and selection cards.
- **Bottom Sheets & Floating Trays (20px - 24px)**: Top-right and top-left rounded corners on interactive ride-hailing drawers (`24px 24px 0 0`).
- **Pills (Full Round / 9999px)**: Category tags, ride-type chips, driver status pills, and vehicle registration containers.

## Components

### Top Bar & Onboarding Navigation
- **Onboarding Header (Phone, OTP, Name, Location)**: Strictly minimal. Displays only the back arrow button (an arrow pointing right `→` in RTL) anchored to the right screen edge. No English titles, no logo marks, and no profile avatars are permitted on onboarding flows.
- **Main App Header**: Contextual bar featuring the drawer trigger, active city indicator, and notification alerts.

### Buttons
- **Primary Button (The Core App CTA)**:
  - Fill: Solid gold `#F3D59A` (strictly solid fill, no gradients).
  - Text: Solid `#05070F` in font weight 600 (`label-lg`, 16px).
  - Dimensions: Full width (`w-full`), fixed height `52px`.
  - Border: None.
  - Usage: The standard action across all screens (Confirm Pickup, Request Ride, Verify Code, Continue).
- **Secondary Filled Button**:
  - Fill: Deep midnight ink `#05070F`.
  - Text: `#FFFFFF` (16px, semibold).
  - Dimensions: Full width or auto, height `52px`.
  - Usage: Contextual secondary actions where high contrast is necessary.
- **Secondary Outline Button**:
  - Fill: Surface canvas `#FFFFFF` or transparent.
  - Border: `1px solid #E5E2DC`.
  - Text: `#05070F` (16px, semibold).
  - Dimensions: Height `52px`.
  - Usage: Non-destructive options, cancellation, and scheduling.

### Input Fields & Verification
- Height: 52px, background `#FFFFFF`, border `1px solid #E5E2DC`, radius `12px`.
- Text aligns right (RTL), placeholder in `#5C606E`.
- Active focus state: `1.5px solid #8A6A2B`.
- OTP Input: 4 or 6 discrete square boxes (52px × 52px), centered text in `dir="ltr"`.

### Ride Option Selection Cards
- Surface: `#FFFFFF`, border `1px solid #E5E2DC`, padding `16px`, border-radius `16px`.
- Selected State: Background `#FDF9F2`, border `1.5px solid #8A6A2B`.
- Content Layout: Horizontal split. Right side holds the car category name (e.g., تكسي اقتصادي, تاكسي المطار) and ETA; left side holds the fare rendered in `numeral-price` (`#05070F`).

### License Plate & Vehicle Details
- Container: Clean pill with `#F2EFEB` background and `1px solid #E5E2DC` stroke.
- Content: BiDi split with the Iraqi governorate identifier on the right (`أربيل` / `بغداد`) and the registration number in Latin characters and numerals on the left in `dir="ltr"` (`12 A 34567`).

### Route Stops & Waypoints
- Origin Stop: 8px solid `#05070F` square marker.
- Destination Stop: 8px solid `#8A6A2B` diamond marker.
- Connecting Route Hairline: 2px solid `#E5E2DC` track line aligned to the right side of the card, with stop labels running to the left.