# FieldReady Frontend - Combine Selection Modal

A Next.js application featuring a full-screen combine selection modal with fuzzy search and beautiful animations.

## Features

- **Full-Screen Modal**: Immersive selection experience
- **Fuzzy Search**: Intelligent search using Fuse.js that finds combines by:
  - Brand name
  - Model number
  - Features
  - Best crops
- **Brand Filtering**: Quick filter buttons for each manufacturer
- **Visual Polish**: 
  - Gradient backgrounds
  - Smooth animations with Framer Motion
  - Hover effects and transitions
- **Field-Ready UX**:
  - Large touch targets (44px minimum)
  - High contrast for sunlight readability
  - Clear visual hierarchy
  - Information at a glance

## Installation

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

3. Run the development server:
```bash
npm run dev
```

4. Open [http://localhost:3000](http://localhost:3000) in your browser

## Key Components

### CombineSelectionModal
The main modal component that provides:
- Command palette-style search bar
- Brand filter buttons
- Responsive grid layout
- Keyboard navigation (ESC to close)
- Smooth animations

### CombineCard
Individual combine cards featuring:
- Gradient overlays on hover
- Visual indicators for key specs:
  - Tough crop ability (color-coded progress bar)
  - Moisture tolerance range
  - Daily capacity
  - Header size
- Feature badges for yield/moisture mapping
- Optimized for quick scanning

## UX Principles Applied

1. **Clarity Over Clutter**: Each combine card shows only essential information with visual hierarchy
2. **Data as Actionable Insight**: Specs are translated into farmer-friendly benefits
3. **Delight in the Details**: Subtle animations and transitions enhance the experience
4. **Built for the Field**: Large touch targets and high contrast ensure usability in truck cabs

## Adding Combine Images

Currently using placeholder SVGs. To add real images:

1. Add combine images to `public/images/combines/`
2. Update the `image` field in `src/data/combines.ts`
3. Update `CombineCard.tsx` to display the actual images

## Customization

### Colors
The color palette is defined in `tailwind.config.js`:
- `field-green`: Primary brand color
- `field-orange`: Accent color for warnings/alerts
- `field-blue`: Secondary color for information

### Animation Timings
Adjust Framer Motion animations in components for different effects.

## Production Build

```bash
npm run build
npm start
```

## Tech Stack

- **Next.js 14**: React framework
- **TypeScript**: Type safety
- **Tailwind CSS**: Utility-first styling
- **Framer Motion**: Animations
- **Fuse.js**: Fuzzy search