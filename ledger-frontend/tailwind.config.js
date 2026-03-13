/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Semantic Roles
        background: '#f8fafc', // slate-50
        surface: '#ffffff',     // white
        'surface-hover': '#f1f5f9', // slate-100
        border: '#cbd5e1',      // slate-300 - higher contrast for financial grids
        'border-light': '#e2e8f0', // slate-200
        
        // Brand
        primary: {
          DEFAULT: '#4f46e5', // indigo-600
          hover: '#4338ca',   // indigo-700
          light: '#e0e7ff',   // indigo-100
        },

        // Status
        success: {
          DEFAULT: '#059669', // emerald-600
          light: '#d1fae5',   // emerald-100
          text: '#065f46',    // emerald-800
        },
        danger: {
          DEFAULT: '#e11d48', // rose-600
          light: '#ffe4e6',   // rose-100
          text: '#9f1239',    // rose-800
        },
        warning: {
          DEFAULT: '#d97706', // amber-600
          light: '#fef3c7',   // amber-100
          text: '#92400e',    // amber-800
        },
        muted: {
          DEFAULT: '#64748b', // slate-500
          light: '#94a3b8',   // slate-400
          dark: '#334155',    // slate-700
        },

        // Text
        text: {
          DEFAULT: '#0f172a', // slate-900
          secondary: '#475569', // slate-600
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'Roboto Mono', 'monospace'],
      },
      fontSize: {
        '2xs': '0.65rem',
        'xs': '0.75rem',    // 12px
        'sm': '0.8125rem',  // 13px - Standard Table Data
        'base': '0.875rem', // 14px
        'lg': '1rem',       // 16px
        'xl': '1.125rem',   // 18px
        '2xl': '1.5rem',    // 24px
        '3xl': '1.875rem',  // 30px
      },
      spacing: {
        '4.5': '1.125rem',
      },
      boxShadow: {
        'card': '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
        'card-hover': '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
        'glow-success': '0 0 0 1px rgba(5, 150, 105, 0.1), 0 0 4px rgba(5, 150, 105, 0.1)',
        'glow-danger': '0 0 0 1px rgba(225, 29, 72, 0.1), 0 0 4px rgba(225, 29, 72, 0.1)',
      }
    },
  },
  plugins: [],
}
