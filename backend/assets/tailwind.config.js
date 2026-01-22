// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

// =============================================================================
// ButtonLog Unified Design System - Tailwind Configuration
// =============================================================================

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/buttonlog_web.ex",
    "../lib/buttonlog_web/**/*.*ex"
  ],
  darkMode: 'class',
  theme: {
    extend: {
      // =======================================================================
      // Color Palette
      // =======================================================================
      colors: {
        // Brand / Primary - Vibrant Teal
        primary: {
          DEFAULT: '#00BFA5',
          50: '#E0F7F4',
          100: '#B2DFDB',
          200: '#80CBC4',
          300: '#4DB6AC',
          400: '#26A69A',
          500: '#00BFA5',
          600: '#00897B',
          700: '#00796B',
          800: '#00695C',
          900: '#004D40',
        },
        // Secondary - Coral Orange
        secondary: {
          DEFAULT: '#FF6B6B',
          50: '#FFEBEE',
          100: '#FFCDD2',
          200: '#EF9A9A',
          300: '#E57373',
          400: '#FF6B6B',
          500: '#EF5350',
          600: '#E55555',
          700: '#D32F2F',
          800: '#C62828',
          900: '#B71C1C',
        },
        // Neutral / Gray
        neutral: {
          50: '#FAFAFA',
          100: '#F5F5F5',
          200: '#EEEEEE',
          300: '#E0E0E0',
          400: '#BDBDBD',
          500: '#9E9E9E',
          600: '#757575',
          700: '#616161',
          800: '#424242',
          900: '#212121',
        },
        // Semantic Colors
        success: {
          DEFAULT: '#4CAF50',
          light: '#E8F5E9',
          dark: '#2E7D32',
        },
        warning: {
          DEFAULT: '#FF9800',
          light: '#FFF3E0',
          dark: '#E65100',
        },
        error: {
          DEFAULT: '#F44336',
          light: '#FFEBEE',
          dark: '#C62828',
        },
        info: {
          DEFAULT: '#2196F3',
          light: '#E3F2FD',
          dark: '#1565C0',
        },
        // Button Palette Colors (for user-customizable buttons)
        btn: {
          red: '#EF5350',
          orange: '#FF9800',
          yellow: '#FFC107',
          green: '#4CAF50',
          teal: '#00BFA5',
          blue: '#2196F3',
          indigo: '#3F51B5',
          purple: '#9C27B0',
          pink: '#E91E63',
        },
        // Legacy brand color (keep for backwards compatibility)
        brand: "#00BFA5",
      },
      // =======================================================================
      // Typography
      // =======================================================================
      fontFamily: {
        sans: [
          'Inter',
          '-apple-system',
          'BlinkMacSystemFont',
          'Segoe UI',
          'Roboto',
          'Helvetica Neue',
          'Arial',
          'sans-serif'
        ],
        mono: [
          'JetBrains Mono',
          'Fira Code',
          'Monaco',
          'Consolas',
          'monospace'
        ],
      },
      fontSize: {
        // Display sizes
        'display-lg': ['3.5625rem', { lineHeight: '4rem', letterSpacing: '-0.015625rem' }],
        'display-md': ['2.8125rem', { lineHeight: '3.25rem', letterSpacing: '0' }],
        'display-sm': ['2.25rem', { lineHeight: '2.75rem', letterSpacing: '0' }],
        // Headline sizes
        'headline-lg': ['2rem', { lineHeight: '2.5rem', letterSpacing: '0' }],
        'headline-md': ['1.75rem', { lineHeight: '2.25rem', letterSpacing: '0' }],
        'headline-sm': ['1.5rem', { lineHeight: '2rem', letterSpacing: '0' }],
        // Title sizes
        'title-lg': ['1.375rem', { lineHeight: '1.75rem', letterSpacing: '0' }],
        'title-md': ['1rem', { lineHeight: '1.5rem', letterSpacing: '0.009375rem' }],
        'title-sm': ['0.875rem', { lineHeight: '1.25rem', letterSpacing: '0.00625rem' }],
        // Body sizes
        'body-lg': ['1rem', { lineHeight: '1.5rem', letterSpacing: '0.03125rem' }],
        'body-md': ['0.875rem', { lineHeight: '1.25rem', letterSpacing: '0.015625rem' }],
        'body-sm': ['0.75rem', { lineHeight: '1rem', letterSpacing: '0.025rem' }],
        // Label sizes
        'label-lg': ['0.875rem', { lineHeight: '1.25rem', letterSpacing: '0.00625rem', fontWeight: '500' }],
        'label-md': ['0.75rem', { lineHeight: '1rem', letterSpacing: '0.03125rem', fontWeight: '500' }],
        'label-sm': ['0.6875rem', { lineHeight: '1rem', letterSpacing: '0.03125rem', fontWeight: '500' }],
      },
      // =======================================================================
      // Spacing (8-point grid system)
      // =======================================================================
      spacing: {
        '0.5': '0.125rem', // 2px
        '1': '0.25rem',    // 4px (xs)
        '2': '0.5rem',     // 8px (sm)
        '3': '0.75rem',    // 12px (md)
        '4': '1rem',       // 16px (lg)
        '5': '1.25rem',    // 20px
        '6': '1.5rem',     // 24px (xl)
        '8': '2rem',       // 32px (xxl)
        '10': '2.5rem',    // 40px
        '12': '3rem',      // 48px (xxxl)
        '16': '4rem',      // 64px
        '20': '5rem',      // 80px
        '24': '6rem',      // 96px
      },
      // =======================================================================
      // Border Radius
      // =======================================================================
      borderRadius: {
        'sm': '0.25rem',   // 4px - chips, badges
        'md': '0.5rem',    // 8px - inputs, small cards
        'lg': '0.75rem',   // 12px - cards
        'xl': '1rem',      // 16px - sheets, modals
        '2xl': '1.5rem',   // 24px - pills, FABs
        'full': '9999px',  // Circle
      },
      // =======================================================================
      // Box Shadow
      // =======================================================================
      boxShadow: {
        'sm': '0 2px 4px rgba(0, 0, 0, 0.08)',
        'md': '0 4px 8px rgba(0, 0, 0, 0.12)',
        'lg': '0 8px 16px rgba(0, 0, 0, 0.16)',
        'xl': '0 12px 24px rgba(0, 0, 0, 0.20)',
        'card': '0 2px 4px rgba(0, 0, 0, 0.08), 0 4px 12px rgba(0, 0, 0, 0.04)',
        'card-hover': '0 4px 8px rgba(0, 0, 0, 0.12), 0 8px 24px rgba(0, 0, 0, 0.08)',
        'button': '0 1px 2px rgba(0, 0, 0, 0.08)',
        'button-hover': '0 2px 4px rgba(0, 0, 0, 0.12)',
      },
      // =======================================================================
      // Transitions
      // =======================================================================
      transitionDuration: {
        'fast': '150ms',
        'normal': '250ms',
        'slow': '350ms',
      },
      transitionTimingFunction: {
        'ease-out-expo': 'cubic-bezier(0.16, 1, 0.3, 1)',
      },
      // =======================================================================
      // Animation
      // =======================================================================
      animation: {
        'fade-in': 'fadeIn 0.25s ease-out',
        'fade-out': 'fadeOut 0.25s ease-out',
        'slide-up': 'slideUp 0.25s ease-out',
        'slide-down': 'slideDown 0.25s ease-out',
        'scale-in': 'scaleIn 0.15s ease-out',
        'pulse-soft': 'pulseSoft 2s ease-in-out infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        fadeOut: {
          '0%': { opacity: '1' },
          '100%': { opacity: '0' },
        },
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        slideDown: {
          '0%': { transform: 'translateY(-10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        scaleIn: {
          '0%': { transform: 'scale(0.95)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
        pulseSoft: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.7' },
        },
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Custom utility classes for ButtonLog design system
    plugin(function({ addComponents, theme }) {
      addComponents({
        // Card component
        '.bl-card': {
          backgroundColor: theme('colors.white'),
          borderRadius: theme('borderRadius.lg'),
          boxShadow: theme('boxShadow.card'),
          padding: theme('spacing.4'),
          transition: 'box-shadow 0.25s ease-out',
          '&:hover': {
            boxShadow: theme('boxShadow.card-hover'),
          },
        },
        // Primary button
        '.bl-btn-primary': {
          backgroundColor: theme('colors.primary.DEFAULT'),
          color: theme('colors.white'),
          fontWeight: '500',
          padding: `${theme('spacing.3')} ${theme('spacing.4')}`,
          borderRadius: theme('borderRadius.md'),
          boxShadow: theme('boxShadow.button'),
          transition: 'all 0.15s ease-out',
          '&:hover': {
            backgroundColor: theme('colors.primary.600'),
            boxShadow: theme('boxShadow.button-hover'),
          },
          '&:active': {
            transform: 'scale(0.98)',
          },
          '&:disabled': {
            backgroundColor: theme('colors.neutral.400'),
            cursor: 'not-allowed',
          },
        },
        // Secondary button
        '.bl-btn-secondary': {
          backgroundColor: 'transparent',
          color: theme('colors.primary.DEFAULT'),
          fontWeight: '500',
          padding: `${theme('spacing.3')} ${theme('spacing.4')}`,
          borderRadius: theme('borderRadius.md'),
          border: `1.5px solid ${theme('colors.primary.DEFAULT')}`,
          transition: 'all 0.15s ease-out',
          '&:hover': {
            backgroundColor: theme('colors.primary.50'),
          },
          '&:active': {
            transform: 'scale(0.98)',
          },
        },
        // Text button
        '.bl-btn-text': {
          backgroundColor: 'transparent',
          color: theme('colors.primary.DEFAULT'),
          fontWeight: '500',
          padding: `${theme('spacing.2')} ${theme('spacing.3')}`,
          borderRadius: theme('borderRadius.md'),
          transition: 'all 0.15s ease-out',
          '&:hover': {
            backgroundColor: theme('colors.primary.50'),
          },
        },
        // Input field
        '.bl-input': {
          width: '100%',
          padding: `${theme('spacing.3')} ${theme('spacing.4')}`,
          borderRadius: theme('borderRadius.md'),
          border: `1px solid ${theme('colors.neutral.300')}`,
          fontSize: theme('fontSize.body-md[0]'),
          transition: 'border-color 0.15s ease-out, box-shadow 0.15s ease-out',
          '&:focus': {
            outline: 'none',
            borderColor: theme('colors.primary.DEFAULT'),
            boxShadow: `0 0 0 3px ${theme('colors.primary.100')}`,
          },
          '&::placeholder': {
            color: theme('colors.neutral.400'),
          },
        },
        // Badge / Chip
        '.bl-badge': {
          display: 'inline-flex',
          alignItems: 'center',
          padding: `${theme('spacing.1')} ${theme('spacing.2')}`,
          borderRadius: theme('borderRadius.sm'),
          fontSize: theme('fontSize.label-sm[0]'),
          fontWeight: '500',
        },
        '.bl-badge-primary': {
          backgroundColor: theme('colors.primary.100'),
          color: theme('colors.primary.700'),
        },
        '.bl-badge-success': {
          backgroundColor: theme('colors.success.light'),
          color: theme('colors.success.dark'),
        },
        '.bl-badge-warning': {
          backgroundColor: theme('colors.warning.light'),
          color: theme('colors.warning.dark'),
        },
        '.bl-badge-error': {
          backgroundColor: theme('colors.error.light'),
          color: theme('colors.error.dark'),
        },
      })
    }),
  ]
}
