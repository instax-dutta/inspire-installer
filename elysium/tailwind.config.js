const elysiumDark = {
  50:  '#e8e6e3',
  100: '#c9c6c2',
  200: '#a8a6a3',
  300: '#8a8885',
  400: '#6c6a68',
  500: '#4e4d4b',
  600: '#333130',
  700: '#242222',
  800: '#1c1b1b',
  900: '#121212',
  950: '#0a0a0a',
};

module.exports = {
  content: [
    './resources/scripts/**/*.{js,jsx,ts,tsx}',
    './resources/views/**/*.blade.php',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        sans: ['JetBrains Mono', 'IBM Plex Mono', 'ui-monospace', 'SFMono-Regular', 'Menlo', 'Monaco', 'monospace'],
        mono: ['JetBrains Mono', 'IBM Plex Mono', 'ui-monospace', 'SFMono-Regular', 'Menlo', 'Monaco', 'monospace'],
      },
      colors: {
        gray:    elysiumDark,
        neutral: elysiumDark,
        slate:   elysiumDark,
        zinc:    elysiumDark,
        stone:   elysiumDark,
        blue: {
          DEFAULT: '#007aff',
          400: '#0a84ff',
          500: '#007aff',
          600: '#0056b3',
        },
        red: {
          DEFAULT: '#ff453a',
          400: '#ff6961',
          500: '#ff453a',
          600: '#d70015',
        },
        green: {
          DEFAULT: '#30d158',
          400: '#34c759',
          500: '#30d158',
          600: '#248a3d',
        },
        yellow: {
          DEFAULT: '#ff9f0a',
          400: '#ffb340',
          500: '#ff9f0a',
          600: '#cc7f08',
        },
        cyan: {
          DEFAULT: '#64d2ff',
          400: '#8adcff',
          500: '#64d2ff',
          600: '#0a84ff',
        },
        purple: {
          DEFAULT: '#bf5af2',
          400: '#d573ff',
          500: '#bf5af2',
          600: '#9b30cc',
        },
      },
      borderRadius: {
        sm:    '4px',
        DEFAULT:'6px',
        md:    '6px',
        lg:    '8px',
        xl:    '12px',
        '2xl': '16px',
        full:  '9999px',
      },
      boxShadow: {
        sm:      'inset 0 0 0 1px rgba(255,255,255,0.06)',
        DEFAULT: 'inset 0 0 0 1px rgba(255,255,255,0.08)',
        md:      'inset 0 0 0 1px rgba(255,255,255,0.08)',
        lg:      'inset 0 0 0 1px rgba(255,255,255,0.10)',
        xl:      'inset 0 0 0 1px rgba(255,255,255,0.10)',
        none:    'none',
      },
    },
  },
  plugins: [],
};
