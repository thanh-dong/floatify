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
          bg: '#2e3440',
          card: '#3b4252',
          surface: '#434c5e',
          border: '#4c566a',
          'border-hover': '#5e81ac',
          text: '#eceff4',
          'text-secondary': '#d8dee9',
          'text-tertiary': '#81a1c1',
          'text-muted': '#4c566a',
          'text-faint': '#434c5e',
          dot: '#4c566a',
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
