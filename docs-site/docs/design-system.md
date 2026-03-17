# Design System & Styling

Our application prioritizes a premium, "wow" aesthetic using modern web and mobile design patterns.

## Color Palette

We use a curated, harmonious color palette featuring vibrant gradients and dark mode optimizations.

| Category | Primary Color | Secondary / Gradient |
|----------|---------------|----------------------|
| **Core** | `#2E3192` (Deep Blue) | `#1BFFFF` (Electric Teal) |
| **Accent** | `#764BA2` (Deep Purple) | `#667EEA` (Soft Blue) |
| **Neutral** | `#121212` (Eerie Black) | `#E0E0E0` (Platinum) |

### Gradient Patterns
Most interactive surfaces use linear gradients:
- **Primary**: `linear-gradient(135deg, #764BA2 0%, #667EEA 100%)`
- **Success**: `linear-gradient(135deg, #11998e 0%, #38ef7d 100%)`

## Typography

We use Google Fonts to ensure a modern, polished look across all platforms.

- **Primary (Headings)**: `Outfit` - Geometric, premium feel.
- **Secondary (Body)**: `Inter` - Highly readable for chat and long-form text.

## UI Patterns

### Glassmorphism
The signature "frosted glass" effect is used for chat bubbles and floating cards.

**Implementation Logic**:
- Background: `Colors.white.withValues(alpha: 0.1)`
- Blur: `BackdropFilter` with `sigmaX: 10, sigmaY: 10`
- Border: Subtile 1px border with `0.2` opacity.

### Chat Input
- **Container**: Floating at the bottom with a gradient border.
- **Constraints**: 2,000 character limit with reactive counter.
- **Feedback**: Immediate haptic feedback and micro-animations on send.
