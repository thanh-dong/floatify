/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}',
    './node_modules/flowbite/**/*.js',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        terminal: {
          bg: '#0a0a0a',
          card: '#111',
          surface: '#1a1a1a',
          border: '#1a1a1a',
          'border-hover': '#262626',
          text: '#e5e5e5',
          'text-secondary': '#737373',
          'text-tertiary': '#525252',
          'text-muted': '#404040',
          'text-faint': '#333',
          dot: '#404040',
        },
      },
      fontFamily: {
        mono: ['SF Mono', 'Fira Code', 'monospace'],
      },
    },
  },
  plugins: [
    require('flowbite/plugin'),
  ],
};
