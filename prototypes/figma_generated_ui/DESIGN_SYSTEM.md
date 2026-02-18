# Sacred Wisdom - Design System Documentation

## Overview
Sacred Wisdom is a spiritual texts Q&A chat application featuring a vibrant, modern UI with gradient backgrounds and colorful accents that create a peaceful yet engaging user experience.

---

## Color Palette

### Primary Gradients

#### Background Gradient
```css
background: linear-gradient(to bottom right, purple-100, blue-50, teal-50)
/* Tailwind: bg-gradient-to-br from-purple-100 via-blue-50 to-teal-50 */
```
- Creates a soft, ethereal atmosphere
- Used for: Main app background, dialogs, modals

#### Primary Action Gradient (Teal to Cyan)
```css
background: linear-gradient(to right, teal-600, cyan-600)
/* Tailwind: bg-gradient-to-r from-teal-600 to-cyan-600 */
/* Hover: hover:from-teal-700 hover:to-cyan-700 */
```
- Used for: Primary buttons, send button, confirmation actions, user message bubbles

#### Accent Gradient (Purple to Fuchsia)
```css
background: linear-gradient(to right, purple-600, fuchsia-600)
/* Tailwind: bg-gradient-to-r from-purple-600 to-fuchsia-600 */
```
- Used for: Premium features, special highlights

#### Icon Container Gradient
```css
background: linear-gradient(to bottom right, teal-500, cyan-500)
/* Tailwind: bg-gradient-to-br from-teal-500 to-cyan-500 */
```
- Used for: Feature icons, empty state icons

### Core Colors

#### Text Colors
- **Primary Text**: `text-gray-900` - Main content, headings
- **Secondary Text**: `text-gray-700` - Descriptions, body text
- **Tertiary Text**: `text-gray-600` - Helper text, metadata
- **Muted Text**: `text-gray-500` - Placeholders, disabled states
- **White Text**: `text-white` - Text on dark/gradient backgrounds

#### Border Colors
- **Primary Border**: `border-purple-300` - Input fields, cards
- **Secondary Border**: `border-gray-200` - Dividers, subtle borders
- **Focus Border**: `border-teal-500` - Active input states

#### Background Colors
- **Card Background**: `bg-white/90` - Message bubbles, cards with slight transparency
- **Solid White**: `bg-white` - Input areas, menus
- **Glass Effect**: `bg-white/80 backdrop-blur-sm` - Suggestion cards, overlays

#### Alert/Status Colors
- **Error**: `text-red-600`, `border-red-100`, `hover:border-red-200`
- **Warning**: Toast warnings for rate limits
- **Success**: Toast success messages

---

## Typography

### Font System
- **Base Font**: System default (inherit from theme)
- **Font Sizes**: Follow Tailwind's default scale
  - `text-xs` - Helper text, timestamps (12px)
  - `text-sm` - Body text, buttons (14px)
  - `text-base` - Standard content (16px)
  - `text-lg` - Subheadings (18px)
  - `text-xl` - Section headings (20px)
  - `text-2xl` - Page titles (24px)
  - `text-3xl` - Main app title (30px)

### Font Weights
- `font-normal` - Body text
- `font-medium` - Emphasized text, labels (500)
- `font-semibold` - Headings, button text (600)
- `font-bold` - Strong emphasis (700)

### Line Heights
- `leading-relaxed` - Message content for better readability
- Default for UI elements

---

## Components

### 1. Header
**Purpose**: Top navigation bar with app branding

**Style**:
```
- Background: bg-white shadow-sm
- Height: h-14
- Padding: px-4 sm:px-6 lg:px-8
- Border: border-b border-gray-200
```

**Elements**:
- Logo icon: Book icon in teal-600 gradient container
- App title: "Sacred Wisdom" in text-xl font-semibold
- Menu button: Menu icon in top-right

---

### 2. App Menu (Sidebar)
**Purpose**: Navigation drawer with user info and actions

**Style**:
```
- Background: bg-gradient-to-br from-purple-100 via-blue-50 to-teal-50
- Width: w-80 (320px)
- Padding: p-6
- Shadow: shadow-lg
```

**Sections**:

#### User Profile Section
- **Guest Mode**: 
  - Icon: UserIcon in bg-gradient-to-br from-purple-500 to-fuchsia-500
  - Text: "Guest User" (text-lg font-semibold)
  - Queries: Pill badge with remaining count

- **Authenticated Mode**:
  - User icon with gradient background
  - Display name and email
  - Query status

#### Action Buttons
- **New Conversation**: Gradient button (teal to cyan)
- **Sign In** (Guest): Gradient button (purple to fuchsia)
- **Logout**: White/semi-transparent with red text and border

---

### 3. Message Bubbles

#### User Messages
```css
- Background: bg-gradient-to-r from-teal-600 to-cyan-600
- Text: text-white
- Border Radius: rounded-xl
- Padding: px-4 py-3
- Shadow: shadow-md
- Max Width: max-w-[85%] sm:max-w-[75%]
- Alignment: justify-end (right-aligned)
```

#### Assistant Messages
```css
- Background: bg-white/90 backdrop-blur-sm
- Text: text-gray-900
- Border Radius: rounded-xl
- Padding: px-4 py-3
- Shadow: shadow-md
- Max Width: max-w-[85%] sm:max-w-[75%]
- Alignment: justify-start (left-aligned)
```

#### Citations Section
- Border Top: border-t border-gray-200
- Padding Top: pt-3
- Margin Top: mt-3
- Citation Items:
  - Icon: ExternalLink (w-3 h-3)
  - Text: text-xs text-gray-600
  - Hover: hover:text-indigo-600
  - Cursor: cursor-pointer

#### Timestamp
- Size: text-xs
- Opacity: opacity-60
- Margin Top: mt-2

---

### 4. Input Area

#### Container
```css
- Background: bg-white
- Shadow: shadow-lg
- Padding: px-4 sm:px-6 lg:px-8 py-4
```

#### Textarea
```css
- Min Height: min-h-[80px]
- Resize: resize-none
- Padding Right: pr-12 (for send button)
- Background: bg-white
- Border: border-2 border-purple-300
- Focus Border: focus:border-teal-500
- Focus Ring: focus:ring-2 focus:ring-teal-200
- Text: text-gray-900
- Placeholder: placeholder:text-gray-500
```

#### Send Button
```css
- Position: absolute bottom-2 right-2
- Shape: rounded-full
- Background: bg-gradient-to-r from-teal-600 to-cyan-600
- Hover: hover:from-teal-700 hover:to-cyan-700
- Shadow: shadow-md
- Icon: Send (w-4 h-4)
```

#### Helper Text
- Size: text-xs
- Color: text-gray-700
- Over Limit: text-red-600 font-medium

---

### 5. Empty State

**Layout**:
```
- Center alignment with flexbox
- Max Width: max-w-md
- Padding: px-4
- Spacing: space-y-4
```

**Icon Container**:
```css
- Background: bg-gradient-to-br from-teal-500 to-cyan-500
- Padding: p-5
- Border Radius: rounded-xl
- Shadow: shadow-lg
- Icon: MessageSquare (w-10 h-10 text-white)
```

**Suggestion Cards**:
```css
- Background: bg-white/80 backdrop-blur-sm
- Border Radius: rounded-xl
- Padding: px-4 py-2.5
- Shadow: shadow-md
- Hover Shadow: hover:shadow-lg
- Hover Background: hover:bg-white
- Transition: transition-all
- Text: text-sm text-gray-700
- Alignment: text-left
```

---

### 6. Buttons

#### Primary Button
```css
- Background: bg-gradient-to-r from-teal-600 to-cyan-600
- Hover: hover:from-teal-700 hover:to-cyan-700
- Text: text-white
- Shadow: shadow-md
- Border Radius: rounded-lg
```

#### Secondary Button (Purple Variant)
```css
- Background: bg-gradient-to-r from-purple-600 to-fuchsia-600
- Hover: hover:from-purple-700 hover:to-fuchsia-700
- Text: text-white
- Shadow: shadow-md
```

#### Ghost Button
```css
- Background: transparent/white variants
- Border: Optional borders for definition
- Hover: Subtle background change
```

#### Logout Button (Danger Variant)
```css
- Background: bg-white/50
- Border: border-2 border-red-100
- Text: text-red-600
- Hover Background: hover:bg-white
- Hover Border: hover:border-red-200
```

---

### 7. Dialogs & Modals

#### AlertDialog
```css
- Background: bg-gradient-to-br from-purple-50 via-blue-50 to-teal-50
- Border Radius: rounded-lg
- Padding: p-6
- Shadow: shadow-xl
```

**Title**:
- Color: text-gray-900
- Size: text-lg
- Weight: font-semibold

**Description**:
- Color: text-gray-700
- Size: text-sm

**Actions**:
- Cancel Button: border-purple-300 hover:bg-purple-50
- Confirm Button: Gradient (teal to cyan) or danger color

---

### 8. Loading States

#### Typing Indicator
```css
- Container: bg-white border border-gray-200 rounded-2xl px-4 py-3
- Dots: w-2 h-2 bg-indigo-600 rounded-full animate-bounce
- Animation Delay: [animation-delay:0.2s], [animation-delay:0.4s]
```

#### Button Loading
- Disabled state with reduced opacity
- Optional spinner icon

---

### 9. Badges & Pills

#### Query Counter Badge
```css
- Background: bg-gradient-to-r from-purple-600 to-fuchsia-600
- Text: text-white
- Size: text-xs
- Weight: font-semibold
- Padding: px-3 py-1
- Border Radius: rounded-full
- Shadow: shadow-sm
```

---

## Spacing System

### Container Padding
- Mobile: `px-4`
- Tablet: `sm:px-6`
- Desktop: `lg:px-8`

### Content Max Width
- Chat messages: `max-w-4xl mx-auto`
- Empty state: `max-w-md`
- Menu sidebar: `w-80`

### Component Spacing
- Section gaps: `space-y-4` (16px)
- Tight spacing: `space-y-2` (8px)
- Loose spacing: `space-y-6` (24px)

---

## Shadows

- **Small Shadow**: `shadow-sm` - Headers, subtle elevation
- **Medium Shadow**: `shadow-md` - Buttons, cards, messages
- **Large Shadow**: `shadow-lg` - Modals, menus, input area
- **Extra Large Shadow**: `shadow-xl` - Dialogs, important overlays

---

## Borders

### Border Radius
- **Small**: `rounded-lg` (8px) - Buttons, inputs
- **Medium**: `rounded-xl` (12px) - Message bubbles, cards
- **Large**: `rounded-2xl` (16px) - Loading indicators
- **Full**: `rounded-full` - Icon buttons, badges

### Border Width
- Default: `border` (1px)
- Emphasized: `border-2` (2px) - Input fields, important borders

---

## Responsive Breakpoints

Following Tailwind defaults:
- **Mobile**: Default (< 640px)
- **Tablet**: `sm:` (≥ 640px)
- **Desktop**: `lg:` (≥ 1024px)
- **Large Desktop**: `xl:` (≥ 1280px)

### Responsive Adjustments
- Padding increases at larger screens
- Message bubble max-width adjusts
- Font sizes scale appropriately
- Menu sidebar adapts to screen size

---

## Interactive States

### Hover States
- Buttons: Darker gradient shades
- Cards: Increased shadow, background transition
- Links: Color change to indigo-600
- Menu items: Light background overlay

### Focus States
- Inputs: Border color change + ring
  - Border: `focus:border-teal-500`
  - Ring: `focus:ring-2 focus:ring-teal-200`

### Active States
- Buttons: Slightly darker, pressed effect
- Interactive elements: Visual feedback on click

### Disabled States
- Reduced opacity
- Cursor: `cursor-not-allowed`
- Grayed out text

---

## Animations & Transitions

### Transitions
- Default: `transition-all` for smooth changes
- Color transitions: `transition-colors`
- Opacity transitions: `transition-opacity`

### Animations
- Loading dots: `animate-bounce` with staggered delays
- Hover effects: Smooth scale/shadow changes
- Modal entrance: Fade in + scale

---

## Accessibility

### Color Contrast
- Text on gradient backgrounds uses white for sufficient contrast
- Dark text (gray-900, gray-700) on light backgrounds
- Focus indicators with visible rings

### Interactive Elements
- Sufficient touch target sizes (minimum 44x44px)
- Keyboard navigation support
- Screen reader text: `<span className="sr-only">`

### ARIA Labels
- Proper button labels
- Dialog titles and descriptions
- Icon-only buttons have text alternatives

---

## Design Patterns

### 1. Glass Morphism
Used for suggestion cards and assistant message bubbles:
```css
bg-white/80 backdrop-blur-sm
```
Creates a frosted glass effect over gradient backgrounds.

### 2. Gradient Overlays
Consistent gradient direction (left to right or top-left to bottom-right):
- Actions: `from-teal-600 to-cyan-600`
- Accents: `from-purple-600 to-fuchsia-600`
- Backgrounds: `from-purple-100 via-blue-50 to-teal-50`

### 3. Card Design
- Rounded corners (xl)
- Subtle shadows
- White or semi-transparent backgrounds
- Proper spacing and padding

### 4. Consistent Iconography
- Lucide React icons throughout
- Size: w-4 h-4 (16px) for small, w-5 h-5 for medium, w-10 h-10 for large
- Color matches context (white on gradients, gray/colored on light backgrounds)

---

## Usage Guidelines

### Do's ✓
- Use gradient backgrounds for primary actions and key features
- Maintain consistent spacing using Tailwind's scale
- Apply shadows to create depth and hierarchy
- Use glass morphism effect sparingly for modern touch
- Keep text readable with proper contrast
- Apply transitions for smooth interactions

### Don'ts ✗
- Don't mix too many different gradient directions
- Don't use gradients on body text
- Don't override established color patterns
- Don't use shadows excessively
- Don't sacrifice accessibility for aesthetics
- Don't create custom colors outside the system

---

## Future Considerations

### Dark Mode (Future Enhancement)
- Invert gradient intensities
- Use darker base colors
- Adjust text colors for dark backgrounds
- Maintain gradient accents but with adjusted saturation

### Custom Themes (Future Enhancement)
- Allow users to customize gradient colors
- Provide preset theme options
- Maintain accessibility standards across themes

---

## Component Checklist

When creating new components, ensure:
- [ ] Follows established color palette
- [ ] Uses appropriate gradients for context
- [ ] Includes hover/focus/active states
- [ ] Responsive across breakpoints
- [ ] Accessible with proper contrast
- [ ] Consistent spacing and sizing
- [ ] Proper shadows for depth
- [ ] Smooth transitions on interactions
- [ ] Compatible with existing design system

---

## Version History

**Version 1.0** - Current
- Initial design system documentation
- Vibrant gradient theme with purple-blue-teal palette
- Glass morphism effects
- Comprehensive component library
- Responsive design patterns

---

## Contact & Contributions

For design questions or suggestions, refer to the GitHub repository "cs698-repo" issue #3.

---

**Last Updated**: February 2026
**Design System Version**: 1.0
**Framework**: React + Tailwind CSS v4
