# Feature Specification: Design System

**Feature Branch**: `059-design-system`

**Created**: 2026-07-11

**Status**: Draft

**Input**: Cross-cutting design infrastructure for all UI views. Defines tokens, theming, typography, components, accessibility, and responsive system.

## Overview

The OSAI design system is a custom design language inspired by Material Design 3's token architecture. It provides a single source of truth for all visual and interaction patterns across the desktop app. Every UI view (specs 018–024) references this system rather than defining its own styling conventions.

## Design Tokens

### Color Palette

Colors are defined as CSS custom properties under the `--os-*` namespace. Two mandatory modes: `light` and `dark`. Optional `high-contrast` mode targets WCAG 2.1 AAA.

#### Semantic Roles (MD3-inspired)

| Token | Light Value | Dark Value | Usage |
|-------|------------|------------|-------|
| `--os-color-primary` | #2563EB (blue-600) | #60A5FA (blue-400) | Primary actions, active states, links |
| `--os-color-on-primary` | #FFFFFF | #1E3A5F | Text/icons on primary backgrounds |
| `--os-color-primary-container` | #DBEAFE (blue-100) | #1E3A5F (blue-900) | Container highlighting primary content |
| `--os-color-on-primary-container` | #1E3A5F | #DBEAFE | Text on primary container |
| `--os-color-secondary` | #7C3AED (violet-600) | #A78BFA (violet-400) | Secondary actions, badges |
| `--os-color-on-secondary` | #FFFFFF | #2D1B4E | Text on secondary backgrounds |
| `--os-color-surface` | #FFFFFF | #0F172A (slate-900) | Main background |
| `--os-color-on-surface` | #0F172A (slate-900) | #F1F5F9 (slate-100) | Primary text on surface |
| `--os-color-surface-variant` | #F8FAFC (slate-50) | #1E293B (slate-800) | Card backgrounds, subtle containers |
| `--os-color-on-surface-variant` | #475569 (slate-600) | #94A3B8 (slate-400) | Secondary text, captions |
| `--os-color-outline` | #CBD5E1 (slate-300) | #475569 (slate-600) | Borders, dividers |
| `--os-color-outline-variant` | #E2E8F0 (slate-200) | #334155 (slate-700) | Subtle borders |
| `--os-color-error` | #DC2626 (red-600) | #F87171 (red-400) | Errors, destructive actions |
| `--os-color-on-error` | #FFFFFF | #3B0A0A | Text on error backgrounds |
| `--os-color-error-container` | #FEE2E2 (red-100) | #3B0A0A (red-900) | Error state backgrounds |
| `--os-color-success` | #16A34A (green-600) | #4ADE80 (green-400) | Success states |
| `--os-color-warning` | #D97706 (amber-600) | #FBBF24 (amber-400) | Warnings |
| `--os-color-info` | #2563EB (blue-600) | #60A5FA (blue-400) | Informational |

#### Node Type Colors (Knowledge Graph)

These are derived from the primary palette with fixed hues for semantic consistency:

| Token | Light | Dark | Node Type |
|-------|-------|------|-----------|
| `--os-color-node-entity` | #6366F1 (indigo) | #818CF8 | Entity nodes |
| `--os-color-node-event` | #94A3B8 (slate) | #64748B | Event nodes |
| `--os-color-node-project` | #22C55E (green) | #4ADE80 | Project nodes |
| `--os-color-node-user` | #EAB308 (yellow) | #FACC15 | User nodes |

### Spacing

4px base grid. All spacing values use `calc(var(--os-spacing-unit) * N)`:

| Token | Value | Usage |
|-------|-------|-------|
| `--os-space-0_5` | 2px | Micro adjustments |
| `--os-space-1` | 4px | Dense padding, icon gaps |
| `--os-space-2` | 8px | Tight padding, button margins |
| `--os-space-3` | 12px | Input padding, card padding (compact) |
| `--os-space-4` | 16px | Standard padding, card padding (default) |
| `--os-space-5` | 20px | Section spacing |
| `--os-space-6` | 24px | Panel padding, section margins |
| `--os-space-8` | 32px | Page padding, modal padding |
| `--os-space-10` | 40px | Large section gaps |
| `--os-space-12` | 48px | Page section separation |
| `--os-space-16` | 64px | Maximum spacing |

### Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `--os-radius-sm` | 4px | Inputs, small badges |
| `--os-radius-md` | 8px | Cards, buttons, dialogs |
| `--os-radius-lg` | 12px | Large panels, modals |
| `--os-radius-xl` | 16px | Sidebar panels, drawers |
| `--os-radius-full` | 9999px | Avatars, pills, toggles |

### Elevation / Shadows

| Token | Y-Offset | Blur | Opacity (Light/Dark) | Usage |
|-------|----------|------|----------------------|-------|
| `--os-shadow-sm` | 1px | 2px | 0.05 / 0.15 | Cards, subtle paper |
| `--os-shadow-md` | 2px | 4px | 0.08 / 0.20 | Dropdowns, elevated cards |
| `--os-shadow-lg` | 4px | 12px | 0.10 / 0.25 | Modals, dialogs |
| `--os-shadow-xl` | 8px | 24px | 0.15 / 0.30 | Toasts, persistent overlays |

### Opacity

| Token | Value | Usage |
|-------|-------|-------|
| `--os-opacity-disabled` | 0.4 | Disabled controls |
| `--os-opacity-dimmed` | 0.2 | Dimmed elements (graph search) |
| `--os-opacity-hover` | 0.08 | Hover overlay on interactive elements |
| `--os-opacity-scrim` | 0.5 | Modal backdrop overlay |

## Theming Engine

### Architecture

The theming engine is a React context provider (`ThemeProvider`) at the app root:

1. **Resolve priority**: Manual toggle > system preference > default (light)
2. **Apply**: CSS custom properties on `:root` / `[data-theme="dark"]`
3. **Persist**: Manual choice saved to `localStorage` key `os-theme`
4. **React**: Class `dark` on `<html>` enables Tailwind dark mode; `high-contrast` enables AA+ mode

### Implementation

```css
:root {
  --os-color-surface: #FFFFFF;
  /* ... all light tokens */
}

[data-theme="dark"] {
  --os-color-surface: #0F172A;
  /* ... all dark tokens */
}

[data-theme="high-contrast"] {
  --os-color-on-surface: #000000;
  --os-color-surface: #FFFFFF;
  /* forced high-contrast overrides */
}
```

Tailwind integration:
```js
// tailwind.config.js
module.exports = {
  darkMode: 'class', // or 'selector'
  theme: {
    extend: {
      colors: {
        os: {
          primary: 'var(--os-color-primary)',
          'on-primary': 'var(--os-color-on-primary)',
          surface: 'var(--os-color-surface)',
          // ...
        },
        'node-entity': 'var(--os-color-node-entity)',
        'node-event': 'var(--os-color-node-event)',
        'node-project': 'var(--os-color-node-project)',
        'node-user': 'var(--os-color-node-user)',
      },
      spacing: {
        'os-0_5': 'var(--os-space-0_5)',
        'os-1': 'var(--os-space-1)',
        // ...
      },
    },
  },
};
```

### FR-001: Theme Provider

- **FR-001.1**: System MUST detect OS dark mode via `prefers-color-scheme` media query
- **FR-001.2**: User MUST be able to toggle between light, dark, high-contrast, and system modes
- **FR-001.3**: Manual preference MUST persist across app restarts
- **FR-001.4**: Theme change MUST apply immediately without page reload
- **FR-001.5**: Transition between themes MUST animate smoothly (0.3s ease-in-out on `background-color` and `color`)

## Typography

### Font Family

| Role | Font | Fallback |
|------|------|----------|
| UI / body | **Inter** (variable) | `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif` |
| Monospace / code | **JetBrains Mono** | `"Fira Code", "Cascadia Code", Consolas, monospace` |

Inter is loaded as a variable font (`Inter-Variable.woff2`) supporting weights 300–700. JetBrains Mono is loaded as a variable font supporting weights 400–600.

### Type Scale

| Token | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| `--os-type-xs` | 11px | 400 | 16px | Captions, timestamps, legal |
| `--os-type-sm` | 12px | 400 | 16px | Labels, metadata, stats |
| `--os-type-base` | 14px | 400 | 20px | Body text, descriptions |
| `--os-type-md` | 16px | 500 | 24px | Subheadings, card titles |
| `--os-type-lg` | 20px | 600 | 28px | Section headings |
| `--os-type-xl` | 24px | 600 | 32px | Page headings |
| `--os-type-2xl` | 32px | 700 | 40px | Primary headings |
| `--os-type-3xl` | 48px | 700 | 56px | Display / hero |

### Type Utility Classes

All typography is applied via utility classes (Tailwind) or semantic React components — no raw font-size values in application code.

```tsx
// Example components
<h1 className="os-type-2xl">Dashboard</h1>
<p className="os-type-base text-os-on-surface-variant">2 hours active today</p>
<span className="os-type-xs">Just now</span>
```

### Text Size Control

- **FR-002.1**: User MUST be able to adjust base text size in Settings: Small (13px), Default (14px), Large (16px), Extra Large (18px)
- **FR-002.2**: Scaling MUST use relative `rem` units throughout the codebase — a single CSS custom property `--os-type-base-size` changes all text
- **FR-002.3**: Preference MUST persist in `localStorage`
- **FR-002.4**: Font scaling MUST NOT affect monospace/code font size (code stays at 14px) to preserve code readability
- **FR-002.5**: OS-level font size setting MUST be respected as the default baseline

Implementation:
```css
:root {
  --os-type-base-size: 14px;
}
[data-text-size="small"]  { --os-type-base-size: 13px; }
[data-text-size="large"]  { --os-type-base-size: 16px; }
[data-text-size="xlarge"] { --os-type-base-size: 18px; }

/* All type tokens are derived from the base */
--os-type-xs:  calc(var(--os-type-base-size) - 3px);
--os-type-sm:  calc(var(--os-type-base-size) - 2px);
--os-type-base: var(--os-type-base-size);
--os-type-md:  calc(var(--os-type-base-size) + 2px);
--os-type-lg:  calc(var(--os-type-base-size) + 6px);
/* etc. */
```

## Responsive System

### Breakpoints

| Name | Min-Width | Target |
|------|-----------|--------|
| `sm` | 640px | Narrow windows, small screens |
| `md` | 768px | Tablet-width windows |
| `lg` | 1024px | Standard desktop half-screen |
| `xl` | 1280px | Full desktop, wide panels |

These map to Tailwind's default breakpoints. The desktop app uses `sm` and `md` as the primary adaptation targets (sidebar open/closed, panel resizing).

### Layout Rules

- **FR-003.1**: All views MUST function at window widths from 800px to 2560px
- **FR-003.2**: Content MUST NOT overflow or clip at any supported width
- **FR-003.3**: Views MUST respond to sidebar open/closed state — content area expands/contracts without breaking layout
- **FR-003.4**: Minimum window width is 800px; below this, content is scrollable
- **FR-003.5** (deferred): Sidebar collapses to icon-only at widths < 900px (Phase 8 accessibility pass)

### Grid Conventions

Layouts use CSS Grid for page-level structure and Flexbox for component-level alignment. The dashboard widget grid and other multi-column layouts follow:

```css
/* Standard page grid */
.os-page-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--os-space-6);
  max-width: 1200px;  /* content max-width */
  margin: 0 auto;
  padding: var(--os-space-8);
}

/* Multi-column widget grid */
.os-widget-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: var(--os-space-4);
}
```

## Shared Component Library

### Component Catalog

All components live in `packages/ui/` as a shared React library consumed by the desktop app and (future) cloud dashboard. Every component:

- Accepts a `className` prop for Tailwind overrides
- Supports light, dark, and high-contrast modes via tokens
- Includes proper ARIA attributes
- Has documented keyboard interactions

| Component | Description | Priority |
|-----------|-------------|----------|
| **Button** | Variants: primary, secondary, ghost, danger, icon-only. Sizes: sm, md, lg. Loading state. | P1 |
| **Input** | Text input with label, placeholder, error, helper text, leading/trailing icon | P1 |
| **Select** | Native or custom dropdown select with label and error state | P1 |
| **Checkbox** | Checked, indeterminate, disabled states | P1 |
| **Radio** | Radio group with label | P1 |
| **Toggle** | Toggle switch for binary settings | P1 |
| **Modal** | Overlay dialog with title, body, footer. Close on Escape, click outside. Focus trap. | P1 |
| **Toast** | Notification toast. Variants: success, error, warning, info. Auto-dismiss. Stackable. | P1 |
| **Tooltip** | Hover/focus tooltip. Delay: 500ms show, 200ms hide. Arrow positioning. | P1 |
| **Badge** | Status badge. Variants: default, primary, success, warning, error, neutral. Dot mode. | P1 |
| **Card** | Container with optional header, footer, padding presets, hover elevation | P1 |
| **Tabs** | Horizontal tabs with active indicator. Optional scrollable overflow. | P1 |
| **Dropdown** | Menu dropdown triggered by click. Items, dividers, disabled items. | P1 |
| **Avatar** | User avatar. Image fallback to initials. Sizes: sm, md, lg. | P1 |
| **Spinner** | Loading indicator. Sizes. Inline or full-page variant. | P1 |
| **EmptyState** | Illustration + title + description + optional CTA button | P1 |
| **IconButton** | Icon-only button with tooltip. Used in toolbars, sidebar. | P1 |
| **ProgressBar** | Linear progress. Determinate and indeterminate modes. | P2 |
| **Skeleton** | Content skeleton loading placeholder. Multiple shape presets. | P2 |
| **Dialog** | Confirmation dialog with action buttons. Destructive variant. | P2 |
| **List** | Item list with leading icon, title, description, trailing action. Selectable. | P2 |
| **MenuBar** | Horizontal menu bar for top-level navigation. | P2 |
| **Slider** | Range slider with optional labels. | P3 |
| **DatePicker** | Date picker input. | P3 |

### Component API Convention

```tsx
// Every component follows this pattern:
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger' | 'icon-only'
  size?: 'sm' | 'md' | 'lg'
  loading?: boolean
  disabled?: boolean
  className?: string
  children?: React.ReactNode
  onClick?: () => void
}
```

### Component Implementation Principles

- **FR-004.1**: All interactive components MUST have visible focus indicators (2px outline ring in primary color with 2px offset)
- **FR-004.2**: All icon-only components MUST have an `aria-label`
- **FR-004.3**: Components MUST respect the application theme (no hardcoded colors)
- **FR-004.4**: Touch targets MUST be at least 32x32px (44x44px preferred for interactive elements)
- **FR-004.5**: Components MUST use the spacing grid for internal padding/margins (no arbitrary pixel values)

## Icons

**Library**: **Lucide** (`lucide-react`)

### Rationale

- Consistently designed 2px stroke icons across 1500+ icons
- Tree-shakeable — only imported icons are bundled
- First-class React support with TypeScript types
- Actively maintained, MIT licensed
- Already the de facto standard in the Tailwind/Radix ecosystem

### Conventions

| Token | Size | Usage |
|-------|------|-------|
| `--os-icon-xs` | 12px | Inline with captions, badges |
| `--os-icon-sm` | 16px | Inline with body text, button icons (small) |
| `--os-icon-md` | 20px | Button icons (default), list leading icons |
| `--os-icon-lg` | 24px | Section header icons, nav items |
| `--os-icon-xl` | 32px | Empty state illustrations, feature icons |

Wrapper component:
```tsx
// All icons use this wrapper for consistent sizing
<Icon name="Search" size="md" className="text-os-on-surface-variant" />
```

### FR-005: Icon Usage

- **FR-005.1**: All icons MUST be rendered via the `<Icon>` wrapper component
- **FR-005.2**: Icons MUST inherit text color unless explicitly set
- **FR-005.3**: Decorative icons MUST have `aria-hidden="true"`
- **FR-005.4**: Icons used as sole interactive targets MUST have `aria-label`

## Motion & Animation

### Duration Scale

| Token | Value | Usage |
|-------|-------|-------|
| `--os-duration-fast` | 100ms | Micro-interactions, hover effects, tap |
| `--os-duration-normal` | 200ms | Transitions, panel slides, content swaps |
| `--os-duration-slow` | 300ms | Modal open/close, route transitions |
| `--os-duration-xslow` | 500ms | Entrance sequences, page load animations |

### Easing

| Token | Value | Usage |
|-------|-------|-------|
| `--os-easing-standard` | `cubic-bezier(0.2, 0, 0, 1)` | Most transitions (MD3-inspired, emphasizes finish) |
| `--os-easing-emphasized` | `cubic-bezier(0.3, 0, 0, 1.1)` | Entry animations, spring-like feel |
| `--os-easing-decelerate` | `cubic-bezier(0, 0, 0.2, 1)` | Elements entering screen |
| `--os-easing-accelerate` | `cubic-bezier(0.4, 0, 1, 1)` | Elements leaving screen |

### FR-006: Motion

- **FR-006.1**: All animations MUST respect `prefers-reduced-motion` — disable transitions, keep opacity/visibility changes instant
- **FR-006.2**: Theme transitions (color/background) MUST use 300ms ease-in-out
- **FR-006.3**: Element entrance/exit MUST use fade + slide (8px vertical) at 200ms
- **FR-006.4**: Layout animations (reorder, expand/collapse) MUST use 200ms with `os-easing-standard`
- **FR-006.5**: Loading spinners MAY animate continuously (not affected by reduced-motion)
- **FR-006.6**: Micro-interactions (hover, focus, active) MUST use 100ms with instant easing
- **FR-006.7**: Modal overlay fade MUST use 200ms — never instant appearance

## Accessibility

### Standards

- **FR-007.1**: All UIs MUST meet WCAG 2.1 Level AA minimum
- **FR-007.2**: Color contrast MUST be at least 4.5:1 for normal text and 3:1 for large text (18px+ bold or 24px+ regular)
- **FR-007.3**: All interactive elements MUST be keyboard accessible (Tab, Enter/Space, Escape)
- **FR-007.4**: Focus order MUST follow logical reading order (left-to-right, top-to-bottom)
- **FR-007.5**: Visible focus indicators MUST be present on all interactive elements — 2px outline ring in primary color with 2px offset

### ARIA

- **FR-007.6**: All landmarks MUST be labeled: `<nav aria-label="Main navigation">`, `<main>`, `<aside aria-label="Context sidebar">`
- **FR-007.7**: Dynamic content updates MUST use `aria-live` regions (polite for non-critical, assertive for errors)
- **FR-007.8**: Expanded/collapsed states MUST use `aria-expanded`
- **FR-007.9**: Tab panels MUST follow WAI-ARIA tab pattern (`role="tablist"`, `role="tab"`, `aria-selected`)
- **FR-007.10**: Dialog/Modal MUST use `role="dialog"` with `aria-modal="true"` and `aria-labelledby`

### Screen Reader

- **FR-007.11**: Loading states MUST be announced: `aria-busy="true"` on loading regions
- **FR-007.12**: Toast notifications MUST be announced via `role="status"` with `aria-live="polite"`
- **FR-007.13**: Error messages MUST be associated with inputs via `aria-describedby`
- **FR-007.14**: Icon-only buttons and links MUST have descriptive `aria-label`

### Reduced Motion

- **FR-007.15**: All transitions and animations MUST be disabled when `prefers-reduced-motion: reduce` is active
- **FR-007.16**: The reduced-motion mode MUST still show meaningful state changes (instant instead of animated)
- **FR-007.17**: Pulsing indicators (live session dot) MUST use CSS animation `pulse` which is CSS-animation-based (automatically disabled by `prefers-reduced-motion`)

### High Contrast

- **FR-007.18**: High-contrast mode MUST increase all text contrast to 7:1 minimum
- **FR-007.19**: High-contrast mode MUST add visible borders to all cards, surfaces, and containers
- **FR-007.20**: High-contrast mode MUST NOT rely solely on color to convey state (add icons, text labels, patterns)

## Implementation Plan

### Phase 3 Integration

The design system is implemented alongside Phase 3 UI views in the following order:

1. **Week 1**: Design tokens, theming engine, CSS custom properties, Tailwind config — enables light/dark switching baseline
2. **Week 2**: Typography system (Inter font loading + type scale + text size control)
3. **Week 3-4**: Shared component library (P1 components: Button, Input, Card, Modal, Toast, Badge, Tabs, Dropdown, Avatar, Spinner, EmptyState, Tooltip)
4. **Week 5**: Accessibility pass, Lucide icon wrapper, responsive system
5. **Week 6**: Motion system, high-contrast mode, edge case hardening

### FR-008: Package Structure

```
packages/ui/
  src/
    components/
      Button.tsx
      Input.tsx
      Card.tsx
      Modal.tsx
      Toast.tsx
      Tooltip.tsx
      Badge.tsx
      Tabs.tsx
      Dropdown.tsx
      Avatar.tsx
      Spinner.tsx
      EmptyState.tsx
      Toggle.tsx
      Checkbox.tsx
      Radio.tsx
      Select.tsx
      Icon/
        Icon.tsx          # Icon wrapper component
        index.ts           # Re-exports icons from lucide-react
    hooks/
      useTheme.ts
      useTextSize.ts
      useReducedMotion.ts
    tokens/
      colors.css
      typography.css
      spacing.css
      shadows.css
      animation.css
    ThemeProvider.tsx      # Theme context + provider
    TextSizeProvider.tsx   # Text size context + provider
    index.ts
  package.json
  tailwind.config.ts       # Shared Tailwind preset
```

### FR-009: Consuming the Design System

- **FR-009.1**: The desktop app imports `packages/ui` as a workspace dependency
- **FR-009.2**: All Phase 3 UI views use components from `packages/ui` — no raw HTML elements for interactive components
- **FR-009.3**: Color, spacing, and typography tokens are available as Tailwind utility classes (`text-os-primary`, `bg-os-surface`, `gap-os-4`, `os-type-base`)
- **FR-009.4**: The `ThemeProvider` wraps the `<App />` root — all views automatically respond to theme changes
- **FR-009.5**: The `TextSizeProvider` wraps the `<App />` root — all text scales with the base size

## Key Entities

- **ThemeMode**: `'light' | 'dark' | 'high-contrast' | 'system'`
- **TextSize**: `'small' | 'default' | 'large' | 'xlarge'`
- **DesignToken**: A CSS custom property. Attributes: name, value (light), value (dark), category (color/spacing/typography/shadow).
- **ThemeConfig**: User theme preferences. Attributes: mode (ThemeMode), textSize (TextSize), persistedAt (timestamp).

## Success Criteria

- **SC-001**: Theme toggle switches between light/dark/high-contrast in under 50ms
- **SC-002**: All text elements respond to base size change within 100ms
- **SC-003**: All interactive components pass keyboard navigation (Tab through all controls)
- **SC-004**: Color contrast meets WCAG 2.1 AA (4.5:1 normal, 3:1 large text) — verified by automated tooling
- **SC-005**: No component uses raw color/spacing values outside the token system (lint rule enforces)
- **SC-006**: App renders without visual regressions at all supported widths (800px–2560px)
- **SC-007**: App passes Lighthouse Accessibility audit with 95+ score
- **SC-008**: Component library bundle is under 50KB gzipped (excluding Lucide icons)
- **SC-009**: All interactive elements have visible focus indicators

## Assumptions

- Tailwind CSS is the styling framework (consistent with existing conventions)
- Inter and JetBrains Mono are self-hosted via `fonts/` directory in `packages/ui/`
- CSS custom properties offer sufficient performance (no runtime CSS-in-JS overhead)
- `lucide-react` provides all necessary icons (if a specific icon is missing, a custom SVG can be added)
- The design system is NOT a separate package published to npm — it is internal to the monorepo
- dnd-kit (drag-and-drop) and recharts/Chart.js (charts) continue as chosen libraries — they are wrapped in design-system-aware components but not rewritten
- High-contrast mode is P2 — implement after light/dark are stable

## Dependencies

- **Required by**: Specs 018 (Timeline), 019 (Projects), 020 (Graph), 021 (Command Bar), 022 (Agent Panel), 023 (Context Sidebar), 024 (Dashboard), 010 (Status Tray icon variants)
- **Depends on**: Tailwind CSS, React, lucide-react (all already in monorepo)
- **Also referenced by**: Spec 038 (Cloud Dashboard), 047 (Mobile App), 049 (Community Site) — their responsive/theme requirements cascade from this spec
