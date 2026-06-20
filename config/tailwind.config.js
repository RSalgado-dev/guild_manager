/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './app/controllers/**/*.rb'
  ],
  theme: {
    extend: {
      colors: {
        'neon-cyan': '#00ffff',
        'neon-magenta': '#ff00ff',
        'neon-purple': '#b026ff',
        'neon-green': '#39ff14',
        'neon-pink': '#ff10f0',
        'neon-blue': '#04d9ff',
        'dark-bg': '#0a0a0f',
        'dark-surface': '#15151f',
        'dark-card': '#1a1a2e',
      },
      boxShadow: {
        'neon-cyan': '0 0 12px rgba(0, 255, 255, 0.18)',
        'neon-magenta': '0 0 12px rgba(255, 0, 255, 0.18)',
        'neon-purple': '0 0 12px rgba(176, 38, 255, 0.18)',
        'neon-green': '0 0 12px rgba(57, 255, 20, 0.18)',
        'neon-blue': '0 0 12px rgba(4, 217, 255, 0.18)',
      },
      animation: {
        'pulse-slow': 'none',
        'glow': 'none',
      },
      keyframes: {
        glow: {
          '0%': { filter: 'brightness(1) drop-shadow(0 0 10px currentColor)' },
          '100%': { filter: 'brightness(1.2) drop-shadow(0 0 20px currentColor)' },
        }
      }
    },
  },
  plugins: [],
}
