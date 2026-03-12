# UI Overhaul Guide

This document provides step-by-step instructions for performing a professional UI overhaul on a Vue.js project, similar to the ledger-frontend redesign.

## Prerequisites

Before starting, ensure you have:
- Node.js and npm installed
- Basic knowledge of Vue.js and CSS
- Access to the project codebase

---

## Phase 1: Project Analysis

### 1.1 Explore Project Structure

First, understand the project's architecture:

```bash
# List all files in the project
ls -la

# Explore the src directory
find src -type f -name "*.vue" -o -name "*.js" -o -name "*.css"
```

### 1.2 Identify Key Files

Look for:
- **App.vue** - Main application shell/layout
- **router.js** - Route definitions
- **main.js** - Application entry point
- **views/** - Page components
- **components/** - Reusable components
- **assets/** - CSS, images, fonts

### 1.3 Understand Current Styling

Check for existing:
- CSS frameworks (Bootstrap, Tailwind, etc.)
- Custom CSS files
- Component libraries
- Design tokens / theme variables

### 1.4 Review Dependencies

```bash
# Check package.json
cat package.json
```

---

## Phase 2: Research Best Practices

### 2.1 Search for Modern UI Trends

Use web search to find current best practices:

**Search queries to use:**
- "modern SaaS dashboard UI design 2024 2025"
- "Vue.js admin dashboard template best"
- "Tailwind CSS dashboard components"
- "professional web app UI patterns"
- "dark mode dashboard design"

### 2.2 Find Inspiration

Look at successful SaaS products:
- Linear (linear.app)
- Vercel (vercel.com)
- Stripe (stripe.com)
- Notion (notion.so)

### 2.3 Research Component Libraries

Popular options:
- **Headless UI** - Unstyled, accessible components
- **Radix Vue** - Primitives for building accessible components
- **Naive UI** - Vue 3 component library
- **Element Plus** - UI library for Vue 3
- **Shadcn Vue** - Copy-paste components

---

## Phase 3: Planning

### 3.1 Define Requirements

Based on research, document:
- Color palette (primary, secondary, accent, success, danger)
- Typography (headings, body, monospace)
- Spacing system
- Component patterns (cards, buttons, inputs, tables)
- Animation guidelines

### 3.2 Choose Tech Stack

Decide on:
- **Styling**: Tailwind CSS (recommended) or custom CSS
- **Icons**: Lucide, Heroicons, or Phosphor Icons
- **Components**: Build custom or use library
- **Fonts**: Google Fonts (Inter, JetBrains Mono recommended)

---

## Phase 4: Implementation

### 4.1 Set Up Tailwind CSS (Recommended)

```bash
# Install Tailwind CSS
npm install -D tailwindcss postcss autoprefixer

# Initialize Tailwind
npx tailwindcss init -p
```

**Configure tailwind.config.js:**
```javascript
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Add custom colors
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
```

**Create main CSS file:**
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --color-primary: #6366f1;
    --color-background: #0a0a0f;
    --color-surface: #12121a;
    /* Add custom properties */
  }
}
```

### 4.2 Update main.js

Import the new CSS:
```javascript
import './assets/main.css'
```

### 4.3 Redesign App.vue

Create a modern layout:
- **Sidebar**: Collapsible navigation with icons
- **Header**: Page title, actions, user menu
- **Main content**: RouterView with transitions
- **Modals**: User creation, confirmations

**Key patterns:**
- Use flexbox/grid for layout
- Add smooth transitions (300ms ease)
- Include loading states
- Handle empty states

### 4.4 Create Dashboard View

Add a home page with:
- Overview cards (stats, totals)
- Quick actions
- Recent activity
- Navigation shortcuts

### 4.5 Update All Views

Apply consistent styling:
- Card-based layouts
- Consistent spacing (use 4px, 8px, 16px, 24px, 32px)
- Proper typography hierarchy
- Loading/empty/error states
- Responsive design

### 4.6 Add Animations

Use Vue's built-in transitions:
```vue
<Transition name="fade">
  <div v-if="show">Content</div>
</Transition>

<style>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
```

---

## Phase 5: Testing & Deployment

### 5.1 Test Build

```bash
npm run build
```

Fix any compilation errors.

### 5.2 Test in Browser

```bash
npm run dev
```

### 5.3 Docker Build

```bash
docker compose build <service_name>
docker compose up -d <service_name>
```

---

## Checklist

- [ ] Analyze project structure
- [ ] Research modern UI trends
- [ ] Define design system (colors, typography)
- [ ] Install dependencies (Tailwind, icons)
- [ ] Configure Tailwind
- [ ] Update main.js entry point
- [ ] Redesign App.vue layout
- [ ] Create dashboard/home view
- [ ] Update all page views
- [ ] Add loading/empty/error states
- [ ] Test build
- [ ] Test in browser
- [ ] Deploy via Docker

---

## Useful Resources

### Design Inspiration
- https://dribbble.com
- https://www.awwwards.com
- https://mobbin.com

### Tailwind CSS
- https://tailwindcss.com
- https://tailwindcss.com/docs

### Icons
- https://lucide.dev (recommended)
- https://heroicons.com
- https://phosphoricons.com

### Fonts
- https://fonts.google.com (Inter, JetBrains Mono)

---

## Common Issues & Solutions

### Issue: Tailwind not working
**Solution:** 
- Ensure `content` in tailwind.config.js includes all relevant files
- Run `npm install` to get dependencies

### Issue: Router not working
**Solution:**
- Check router.js has correct import: `createWebHistory()` with parentheses

### Issue: Animation spinning whole button
**Solution:**
- Apply animation class only to the icon, not the entire button element

### Issue: Docker not picking up changes
**Solution:**
- Run `docker compose build <service>` to rebuild
- Then `docker compose up -d <service>` to restart
