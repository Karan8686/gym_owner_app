---
name: FitTrack Owner
colors:
  surface: '#fdf7ff'
  surface-dim: '#ded8e0'
  surface-bright: '#fdf7ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f8f2fa'
  surface-container: '#f2ecf4'
  surface-container-high: '#ece6ee'
  surface-container-highest: '#e6e0e9'
  on-surface: '#1d1b20'
  on-surface-variant: '#494551'
  inverse-surface: '#322f35'
  inverse-on-surface: '#f5eff7'
  outline: '#7a7582'
  outline-variant: '#cbc4d2'
  surface-tint: '#6750a4'
  primary: '#4f378a'
  on-primary: '#ffffff'
  primary-container: '#6750a4'
  on-primary-container: '#e0d2ff'
  inverse-primary: '#cfbcff'
  secondary: '#63597c'
  on-secondary: '#ffffff'
  secondary-container: '#e1d4fd'
  on-secondary-container: '#645a7d'
  tertiary: '#765b00'
  on-tertiary: '#ffffff'
  tertiary-container: '#c9a74d'
  on-tertiary-container: '#503d00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e9ddff'
  primary-fixed-dim: '#cfbcff'
  on-primary-fixed: '#22005d'
  on-primary-fixed-variant: '#4f378a'
  secondary-fixed: '#e9ddff'
  secondary-fixed-dim: '#cdc0e9'
  on-secondary-fixed: '#1f1635'
  on-secondary-fixed-variant: '#4b4263'
  tertiary-fixed: '#ffdf93'
  tertiary-fixed-dim: '#e7c365'
  on-tertiary-fixed: '#241a00'
  on-tertiary-fixed-variant: '#594400'
  background: '#fdf7ff'
  on-background: '#1d1b20'
  surface-variant: '#e6e0e9'
typography:
  display:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
  data-lg:
    fontFamily: JetBrains Mono
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  data-sm:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  container-padding: 24px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
---

## Brand & Style

This design system is built for administrative precision, prioritizing data clarity and utility over decorative flourish. The brand personality is clinical, efficient, and authoritative, designed to instill a sense of order for gym owners managing complex schedules and finances.

The visual style is a rigorous **Minimalism** with a **Functional/Utility** focus. It utilizes flat surfaces, hairline borders, and intentional white space to reduce cognitive load. There are no shadows, gradients, or blurs; depth is communicated solely through color-blocked surfaces and structural outlines. The emotional response is one of calm, professional control.

## Colors

The palette is strictly monochrome to maintain a utility-first focus.
- **Background**: A warm off-white (#F6F6F4) provides a soft foundation for the workspace.
- **Surface**: Pure white (#FFFFFF) is used for cards, inputs, and primary containers to create a clear "work area."
- **Ink Primary**: High-contrast black (#161616) for headers and body text.
- **Ink Secondary**: A muted grey (#7A7A76) for metadata, labels, and secondary information.
- **Signal Red**: Reserved exclusively for critical status indicators (expired memberships, overdue payments) and destructive actions. It must never be used for aesthetic accents or branding.

## Typography

This design system uses a dual-font strategy to separate qualitative labels from quantitative data. 

**Inter** is the primary sans-serif for UI labels, headers, and descriptions, chosen for its humanist legibility and neutral tone. 

**JetBrains Mono** is mandatory for all counts, timestamps, monetary values, and dates. Its tabular spacing ensures that columns of numbers align perfectly in tables and dashboard widgets, facilitating rapid scanning of financial and attendance metrics.

## Layout & Spacing

The layout follows a **Fixed Grid** philosophy on desktop with a 12-column structure, transitioning to a fluid single-column layout on mobile.

- **Grid**: Use 16px gutters and 24px outer margins.
- **Rhythm**: All spacing (margins, padding, gaps) must be multiples of 4px.
- **Density**: The UI should feel airy but structured. Use 16px padding inside cards and 12px vertical padding in table rows to balance data density with readability.
- **Alignment**: Align all monospaced data to the right in table columns to ensure decimal points and units align vertically.

## Elevation & Depth

This system rejects shadows in favor of **Tonal Layering** and **Hairline Outlines**. 
- Depth is suggested by placing white (#FFFFFF) surfaces on top of the background (#F6F6F4).
- All interactive or distinct containers must be defined by a 1px solid border (#E4E4E1).
- Active or focused states are indicated by a weight increase in the border (2px) or a subtle shift in the background color of the element, rather than a shadow or glow.

## Shapes

The shape language is strictly rectangular with a subtle 8px corner radius (`rounded-md`) to soften the "industrial" feel without appearing playful. 

- **Containers & Cards**: 8px corner radius.
- **Buttons**: 8px corner radius. Pill-shaped or fully rounded buttons are prohibited.
- **Borders**: Always 1px solid #E4E4E1, unless an element is in an "active" or "error" state.

## Components

### Buttons
Buttons are strictly rectangular with 8px corners.
- **Primary**: Solid #161616 background with #FFFFFF text.
- **Secondary**: #FFFFFF background with 1px #E4E4E1 border and #161616 text.
- **Destructive**: 1px #D6321F border with #D6321F text (only for final actions).

### Inputs & Fields
Inputs use a #FFFFFF background and the standard 1px #E4E4E1 border. Place the label above the field in `label` typography (Inter, 12px, Uppercase). Monospaced font (JetBrains Mono) is used if the input is for numerical data (e.g., price, weight, minutes).

### Data Tables
The core of the app. Rows are separated by 1px horizontal lines. No vertical lines. Header labels are `label` typography. Member names use `body-lg`. All numbers/dates use `data-sm`.

### Chips / Badges
Small, rectangular containers with 4px radius.
- **Neutral**: Light grey background with `secondary-ink` text.
- **Urgent/Expired**: Light red tint background with `signal-red` text.

### Icons
Icons are restricted to functional necessity. Use simple 1.5px stroke weight chevrons for navigation and checkmarks for success states. Avoid illustrative or decorative iconography.