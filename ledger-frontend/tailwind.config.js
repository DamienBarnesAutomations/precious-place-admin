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
        background: '#0a0a0f',
        surface: '#12121a',
        'surface-hover': '#1a1a24',
        border: '#1e293b',
        'border-light': '#2a3a4a',
        primary: '#6366f1',
        'primary-hover': '#818cf8',
        success: '#10b981',
        'success-light': '#34d399',
        danger: '#ef4444',
        'danger-light': '#f87171',
        warning: '#f59e0b',
        info: '#3b82f6',
        muted: '#64748b',
        'muted-dark': '#475569',
        text: '#f3f4f6',
        'text-secondary': '#cbd5e1',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      boxShadow: {
        'card': '0 1px 3px 0 rgba(0, 0, 0, 0.5)',
        'card-hover': '0 4px 6px -1px rgba(0, 0, 0, 0.7)',
        'glow-success': '0 0 15px rgba(16, 185, 129, 0.2)',
        'glow-primary': '0 0 15px rgba(99, 102, 241, 0.2)',
        'glow-danger': '0 0 15px rgba(239, 68, 68, 0.1)',
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-out',
        'slide-up': 'slideUp 0.3s ease-out',
        'slide-down': 'slideDown 0.3s ease-out',
        'scale-in': 'scaleIn 0.2s ease-out',
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        slideDown: {
          '0%': { opacity: '0', transform: 'translateY(-10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        scaleIn: {
          '0%': { opacity: '0', transform: 'scale(0.95)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
      },
    },
  },
  plugins: [],
}
