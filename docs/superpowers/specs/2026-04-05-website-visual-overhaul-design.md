# Floatify Website Visual Overhaul Design

**Date:** 2026-04-05
**Status:** Approved
**Scope:** In-place refactor of `website/src/pages/index.astro` and supporting files

## 1. Concept

Visual overhaul of the existing landing page from a Catppuccin terminal aesthetic to a premium neutral dark aesthetic. Inspired by Linear, Vercel, and similar developer tools.

**What stays:** Astro + Tailwind stack, all content, section order, animations (typing effect, scroll behavior, copy buttons), Flowbite dependency, monospace typography everywhere.

**What changes:** Color palette, spacing, border styles, hover effects, icon style. Two new sections added.

## 2. Color Palette

Replace all Catppuccin tokens with neutral dark tokens.

| Token | Old (Catppuccin) | New (Neutral) |
|-------|-------------------|---------------|
| Page background | `#1e1e2e` | `#0a0a0a` |
| Card background | `#1e1e2e` | `#111` |
| Surface elevated | `#181825` | `#1a1a1a` |
| Border default | `#313244` | `#1a1a1a` |
| Border subtle | `#313244/30` | `#1a1a1a` |
| Border hover | `#45475a` | `#262626` |
| Text primary | `#cdd6f4` | `#e5e5e5` |
| Text secondary | `#cdd6f4/70` | `#737373` |
| Text tertiary | `#cdd6f4/60` | `#525252` |
| Text muted | `#cdd6f4/50` | `#404040` |
| Text faint | `#cdd6f4/40` | `#333` |
| Traffic light dots | `#f38ba8` `#f9e2af` `#a6e3a1` | `#404040` `#404040` `#404040` |
| CTA primary | N/A | `#fafafa` bg, `#000` text |
| CTA secondary | `#313244` bg | `#262626` border, `#737373` text |
| Step badge | `bg-purple-600` | `#262626` bg, `#e5e5e5` text |
| Hover glow | `shadow-purple-500/20` | border brightens to `#262626` |

## 3. Section-by-Section Changes

### Navigation

- Logo text: `#e5e5e5`
- GitHub button: bg `#1a1a1a`, border `#262626`, text `#e5e5e5`. Hover bg `#262626`
- Scrolled state: bg `rgba(10, 10, 10, 0.95)`, blur `10px`. Border-bottom `#1a1a1a` on scroll

### Hero

- Background: `#0a0a0a`
- Headline: `#e5e5e5`, `text-5xl md:text-6xl`
- Tagline: `#737373`, `text-xl`
- Terminal window: bg `#1a1a1a`, border `#1a1a1a`, rounded `xl`
- Terminal header: bg `#0a0a0a`
- Terminal dots: all `#404040`
- Typing text: `#e5e5e5`, prompt symbol: `#e5e5e5`
- Cursor: `#e5e5e5`
- "Copied!" feedback: `#737373`
- Remove "Click terminal to copy command" helper text
- Two new CTA buttons below terminal:
  - "Get Started": bg `#fafafa`, text `#000`, rounded `lg`, `px-6 py-3`
  - "View on GitHub": border `1px solid #262626`, text `#737373`, rounded `lg`

### Animated Demo (NEW)

Position: immediately after hero, before features.

A self-contained CSS/JS animation showing a miniature macOS desktop with a Floatify notification panel sliding in from the bottom-right corner.

Implementation:
- Fixed-size container (max-w-2xl, centered)
- Miniature desktop mockup using CSS: dark bg, thin top bar with "macOS" dots, dock bar at bottom
- Notification panel: small rounded rectangle that animates in from bottom-right
  - Animation: fade-in + slide-up, triggered by IntersectionObserver on scroll into view
  - Panel shows: icon, message text, corner indicator
- Loops the animation with a 3-second delay between repeats
- Section label: uppercase `#525252`, `text-xs`, `tracking-wider`, centered, "SEE IT IN ACTION"
- Pure CSS/JS, no animation libraries

### macOS Screenshot (NEW)

Position: immediately after animated demo, before features.

A real screenshot placeholder that you will replace with an actual macOS screenshot of Floatify running.

Implementation:
- Container: max-w-4xl, centered, rounded `xl`
- Image: `public/floatify-screenshot.png` (placeholder path)
- Styling: border `1px solid #1a1a1a`, rounded corners, subtle shadow
- Loading: `loading="lazy"` for performance
- Alt text: "Floatify showing a notification in the bottom-right corner of a macOS desktop"

### Features

- Section heading: `#525252`, uppercase, `text-xs`, `tracking-wider`, centered
- Grid: `grid-cols-1 md:grid-cols-2 lg:grid-cols-3`, gap `6`
- Card: bg `#111`, border `1px solid #1a1a1a`, rounded `lg`, padding `6`
- Card hover: border brightens to `#262626`, slight translateY (-1px)
- Icon: replace emoji with inline SVGs in `#737373` (single color, no fills)
- Title: `#e5e5e5`, `text-lg`, `font-semibold`
- Description: `#737373`, `text-sm`
- Seven icons as SVGs:
  1. Sub-millisecond IPC: lightning bolt
  2. Zero Focus Stealing: lock/shield
  3. Dead Zone Positioning: crosshair/target
  4. Stackable Panels: layers/stack
  5. FIFO Pipe IPC: arrow-right-left or pipe icon
  6. Developer-First: terminal/code icon
  7. Configurable Layout: sliders/settings icon

### How It Works

- Section heading: same style as Features
- Step badge: bg `#262626`, text `#e5e5e5`, rounded `full`
- Connecting lines: bg `#1a1a1a` (the thin horizontal lines between steps)
- Step title: `#e5e5e5`
- Step description: `#737373`

### Code Sections (Config, CLI Reference, Integration)

All three sections share the same treatment:
- Section heading: uppercase `#525252`, `text-xs`, `tracking-wider`
- Code block wrapper: bg `#111`, border `1px solid #1a1a1a`, rounded `lg`
- Code block header: bg `#0a0a0a`, border-bottom `1px solid #1a1a1a`
- Traffic light dots: all `#404040`
- Copy button: bg `#1a1a1a`, text `#525252`. Hover bg `#262626`, text `#737373`
- Code text: `#e5e5e5` (primary), `#525252` (comments/secondary)
- "Copied!" state: text changes to `#737373`

### Installation

- Same neutral treatment as code sections
- Step labels: `#e5e5e5`
- Inline code: bg `#1a1a1a`, text `#737373`
- Checkmark icons: `#525252` (muted, not green)
- "View on GitHub" CTA: border `1px solid #262626`, text `#737373`

### Footer

- Background: `#111`
- Border-top: `1px solid #1a1a1a`
- Copyright text: `#333`, `text-sm`
- MIT badge: bg `#1a1a1a`, border `1px solid #1a1a1a`, text `#525252`
- GitHub link: `#333`, hover `#525252`
- "Back to top": `#333`, hover `#525252`

## 4. Files Changed

| File | Change |
|------|--------|
| `website/src/pages/index.astro` | Full visual overhaul + 2 new sections |
| `website/src/layouts/Layout.astro` | Update body class color tokens |
| `website/src/styles/global.css` | Remove Catppuccin terminal-dot classes, update body color |
| `website/tailwind.config.mjs` | Update terminal color tokens |
| `website/public/floatify-screenshot.png` | New file (placeholder) |

## 5. What Does NOT Change

- Astro version, config, or build settings
- Tailwind version or plugin config (keep Flowbite)
- Section order (except inserting 2 new sections after hero)
- Content text (all headlines, descriptions, code examples stay the same)
- Terminal typing animation JS
- Copy-to-clipboard JS
- Navbar scroll behavior JS
- Font family (SF Mono / Fira Code everywhere)
- Monospace body font

## 6. Design Decisions

| Decision | Choice | Rationale |
|----------|--------|------------|
| Color palette | Neutral only | Premium, sophisticated, matches "no-nonsense" personality |
| Typography | Full monospace | User preference, distinctive, matches tool identity |
| Traffic light dots | Muted gray | Neutral palette consistency |
| Feature icons | Inline SVGs, monochrome | Consistent with neutral palette, scalable |
| Animated demo | Pure CSS/JS | No library dependency, fast loading |
| Screenshot | Static image | Simple, fast, real proof |
| Hover effects | Border brighten only | Subtle, professional, no colored glows |
