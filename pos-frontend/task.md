# UI Overhaul Task Plan - POS Frontend

## Project Context
The `pos-frontend` is a Point of Sale interface designed for staff members in a bakery setting. Its primary goal is to facilitate rapid product selection, cart management, and checkout. Speed, clarity, and reliability are the most important factors for the user (bakery staff).

## Stack
- **Framework**: Vue 3 (Composition API)
- **Styling**: Tailwind CSS v4
- **State Management**: Pinia
- **Icons**: Lucide Vue Next

## Design Direction
The new design will be **"Modern Industrial POS"**: a high-contrast, high-density interface that prioritizes speed and touch-friendliness. We will move away from generic "zinc" cards towards a more structured "Terminal" aesthetic.
- **Tone**: Professional, precise, high-throughput.
- **Density**: Increased information density in the product grid and cart to minimize scrolling.
- **Reference**: Blending Square's visual clarity with Toast's operational efficiency (persistent sidebar, rapid search).

## Design System
- **Font(s)**: 
  - Sans: 'Inter' (UI/Labels)
  - Mono: 'JetBrains Mono' (Prices, quantities, transaction IDs)
- **Color palette**:
  - `bg`: `#020617` (Deep Obsidian)
  - `surface`: `#0f172a` (Slate Surface)
  - `primary`: `#10b981` (Emerald - Success/Action)
  - `danger`: `#ef4444` (Rose - Destructive)
  - `muted`: `#64748b` (Slate Muted)
- **Status color map**:
  - Checkout Ready → `emerald`
  - Processing → `blue`
  - Error/Destructive → `rose`
  - Warning → `amber`

## Boundaries: What Will Not Change
- `src/stores/posStore.js` logic (API calls, cart mutations).
- Environment variable usage.
- Authentication/User creation logic paths.

## Per-Component Plan

### App.vue (App Shell)
**What it does**: Holds the entire POS interface.
**Current problems**: Single massive file. Generic header. Sidebar/Mobile transition is basic.
**Information hierarchy**:
1. Current Order Total (Bottom/Sidebar Footer)
2. Checkout Button (Bottom/Sidebar Footer)
3. Product Grid (Central)
4. Order Items (Sidebar)
**Layout changes**:
- Split `App.vue` logic into a cleaner structure (even if keeping one file for now, group templates better).
- Modernize the header: use a "glass" effect and more distinct brand identity.
- Refine the sidebar to be more integrated on desktop.

### Product Card
**What it does**: Individual item in the grid.
**Current problems**: Large images take up too much space. Price is small.
**Information hierarchy**:
1. Product Name
2. Price (Mono font)
3. Image (Smaller, as a secondary cue)
**Layout changes**:
- Reduce card height.
- Move price to a prominent badge or dedicated row.
- Add a "Quantity in Cart" indicator on the card itself.

### Cart Aside
**What it does**: Displays current items and checkout action.
**Current problems**: Low density. Remove buttons are generic.
**Information hierarchy**:
1. Order Total (Huge, Mono)
2. Checkout Button (Clear primary CTA)
3. Item List (Verification)
**Layout changes**:
- Use a "Ledger" style list for cart items.
- Replace generic "Clear" with a more intentional "Reset Order" workflow.
- Ensure the total is always the most visible element.

### Daily Sales Modal
**What it does**: Historical view of today's sales.
**Current problems**: Generic modal styling. Hard to distinguish between transactions.
**Information hierarchy**:
1. Day Total (Banner)
2. Transaction ID & Time (Identity)
3. Transaction Total (Financial impact)
**Layout changes**:
- Use a "Receipt" aesthetic for transaction entries.
- Add a "Summary Bar" at the top of the modal.

## Implementation Order
1. **Design System & Global Styles**: Setup `style.css` and Tailwind variables.
2. **App Shell**: Refine the layout structure and header.
3. **Product Grid & Cards**: Implement high-density cards.
4. **Cart Refinement**: Optimize for speed and verification.
5. **Modals & Toasts**: Final polish on secondary interfaces.

## Bugs Found (Do Not Fix Unless Blocking)
- Cart quantities are not editable directly, only via re-clicking (Keep as is per logic constraint).
- No category filtering (Out of scope for UI overhaul).
