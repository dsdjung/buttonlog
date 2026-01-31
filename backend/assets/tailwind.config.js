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
      // Color Palette - Minimal & Clean Aesthetic
      // =======================================================================
      colors: {
        // Brand / Primary - Softer, Sophisticated Teal
        primary: {
          DEFAULT: '#26A69A',
          50: '#E0F2F1',
          100: '#B2DFDB',
          200: '#80CBC4',
          300: '#4DB6AC',
          400: '#26A69A',
          500: '#009688',
          600: '#00897B',
          700: '#00796B',
          800: '#00695C',
          900: '#004D40',
        },
        // Secondary - Warmer Coral (muted)
        secondary: {
          DEFAULT: '#EF8A76',
          50: '#FBE9E7',
          100: '#FFCCBC',
          200: '#FFAB91',
          300: '#FF8A65',
          400: '#EF8A76',
          500: '#F4511E',
          600: '#E64A19',
          700: '#D84315',
          800: '#BF360C',
          900: '#9E2A0D',
        },
        // Neutral / Gray - Refined
        neutral: {
          50: '#FAFBFC',  // Slight warmth for background
          100: '#F5F6F7',
          200: '#EEEFF1',
          300: '#E5E7EB',  // Border color
          400: '#9CA3AF',
          500: '#6B7280',  // Text secondary
          600: '#4B5563',
          700: '#374151',
          800: '#1F2937',
          900: '#1A1A2E',  // Text primary - softer than pure black
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
          teal: '#26A69A',
          blue: '#2196F3',
          indigo: '#3F51B5',
          purple: '#9C27B0',
          pink: '#E91E63',
        },
        // Border color for minimal aesthetic
        border: '#E5E7EB',
        // Text colors for minimal aesthetic
        'text-primary': '#1A1A2E',
        'text-secondary': '#6B7280',
        'text-tertiary': '#9CA3AF',
        // Surface colors
        surface: '#FFFFFF',
        'surface-elevated': '#F5F6F7',
        // Legacy brand color (keep for backwards compatibility)
        brand: "#26A69A",
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
        // Display sizes - Light weight for elegance (300)
        'display-lg': ['3.5625rem', { lineHeight: '4rem', letterSpacing: '0.03125rem', fontWeight: '300' }],
        'display-md': ['2.8125rem', { lineHeight: '3.25rem', letterSpacing: '0.01875rem', fontWeight: '300' }],
        'display-sm': ['2.25rem', { lineHeight: '2.75rem', letterSpacing: '0.0125rem', fontWeight: '300' }],
        // Headline sizes - Regular weight for readability (400)
        'headline-lg': ['2rem', { lineHeight: '2.5rem', letterSpacing: '0.0125rem', fontWeight: '400' }],
        'headline-md': ['1.75rem', { lineHeight: '2.25rem', letterSpacing: '0.009375rem', fontWeight: '400' }],
        'headline-sm': ['1.5rem', { lineHeight: '2rem', letterSpacing: '0.00625rem', fontWeight: '400' }],
        // Title sizes - Medium weight for hierarchy (500)
        'title-lg': ['1.375rem', { lineHeight: '1.75rem', letterSpacing: '0', fontWeight: '500' }],
        'title-md': ['1rem', { lineHeight: '1.5rem', letterSpacing: '0.00625rem', fontWeight: '500' }],
        'title-sm': ['0.875rem', { lineHeight: '1.25rem', letterSpacing: '0.00625rem', fontWeight: '500' }],
        // Body sizes - Regular weight with subtle tracking (400)
        'body-lg': ['1rem', { lineHeight: '1.5rem', letterSpacing: '0.009375rem', fontWeight: '400' }],
        'body-md': ['0.875rem', { lineHeight: '1.25rem', letterSpacing: '0.00625rem', fontWeight: '400' }],
        'body-sm': ['0.75rem', { lineHeight: '1rem', letterSpacing: '0.00625rem', fontWeight: '400' }],
        // Label sizes - Medium weight for emphasis (500)
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
      // Box Shadow - Minimal, subtle shadows
      // =======================================================================
      boxShadow: {
        'none': 'none',
        'subtle': '0 1px 2px rgba(0, 0, 0, 0.04)',
        'sm': '0 1px 3px rgba(0, 0, 0, 0.06)',
        'md': '0 2px 6px rgba(0, 0, 0, 0.08)',
        'lg': '0 4px 12px rgba(0, 0, 0, 0.10)',
        'xl': '0 8px 24px rgba(0, 0, 0, 0.12)',
        // Card shadows - very subtle for minimal look
        'card': '0 1px 3px rgba(0, 0, 0, 0.04)',
        'card-hover': '0 2px 6px rgba(0, 0, 0, 0.08)',
        // Button shadows - minimal
        'button': '0 1px 2px rgba(0, 0, 0, 0.05)',
        'button-hover': '0 2px 4px rgba(0, 0, 0, 0.08)',
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
      // Animation - Spring-like, smooth animations
      // =======================================================================
      animation: {
        'fade-in': 'fadeIn 0.25s ease-out',
        'fade-out': 'fadeOut 0.25s ease-out',
        'slide-up': 'slideUp 0.35s cubic-bezier(0.34, 1.56, 0.64, 1)',
        'slide-down': 'slideDown 0.35s cubic-bezier(0.34, 1.56, 0.64, 1)',
        'scale-in': 'scaleIn 0.25s cubic-bezier(0.34, 1.56, 0.64, 1)',
        'scale-out': 'scaleOut 0.15s ease-out',
        'pulse-soft': 'pulseSoft 2s ease-in-out infinite',
        'press': 'press 0.15s ease-out',
        'spring': 'spring 0.35s cubic-bezier(0.34, 1.56, 0.64, 1)',
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
          '0%': { transform: 'translateY(12px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        slideDown: {
          '0%': { transform: 'translateY(-12px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        scaleIn: {
          '0%': { transform: 'scale(0.95)', opacity: '0' },
          '100%': { transform: 'scale(1)', opacity: '1' },
        },
        scaleOut: {
          '0%': { transform: 'scale(1)', opacity: '1' },
          '100%': { transform: 'scale(0.95)', opacity: '0' },
        },
        pulseSoft: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.7' },
        },
        press: {
          '0%': { transform: 'scale(1)' },
          '50%': { transform: 'scale(0.98)' },
          '100%': { transform: 'scale(1)' },
        },
        spring: {
          '0%': { transform: 'scale(0.95)' },
          '50%': { transform: 'scale(1.02)' },
          '100%': { transform: 'scale(1)' },
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

    // Custom utility classes for ButtonLog design system - Minimal & Clean
    plugin(function({ addComponents, theme }) {
      addComponents({
        // Card component - Minimal with subtle border
        '.bl-card': {
          backgroundColor: theme('colors.white'),
          borderRadius: theme('borderRadius.xl'),  // 16px - larger, softer corners
          border: `1px solid ${theme('colors.neutral.300')}`,  // Subtle border instead of shadow
          padding: theme('spacing.5'),  // 20px - more generous
          transition: 'all 0.25s cubic-bezier(0.34, 1.56, 0.64, 1)',
          '&:hover': {
            borderColor: theme('colors.neutral.400'),
          },
        },
        // Card with subtle shadow (for elevated elements)
        '.bl-card-elevated': {
          backgroundColor: theme('colors.white'),
          borderRadius: theme('borderRadius.xl'),
          border: `1px solid ${theme('colors.neutral.300')}`,
          boxShadow: theme('boxShadow.subtle'),
          padding: theme('spacing.5'),
          transition: 'all 0.25s cubic-bezier(0.34, 1.56, 0.64, 1)',
          '&:hover': {
            boxShadow: theme('boxShadow.sm'),
          },
        },
        // Primary button - Minimal with subtle shadow
        '.bl-btn-primary': {
          backgroundColor: theme('colors.primary.DEFAULT'),
          color: theme('colors.white'),
          fontWeight: '500',
          padding: `${theme('spacing.3')} ${theme('spacing.4')}`,
          borderRadius: theme('borderRadius.lg'),  // 12px
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
            opacity: '0.6',
          },
        },
        // Secondary button - Outlined
        '.bl-btn-secondary': {
          backgroundColor: 'transparent',
          color: theme('colors.primary.DEFAULT'),
          fontWeight: '500',
          padding: `${theme('spacing.3')} ${theme('spacing.4')}`,
          borderRadius: theme('borderRadius.lg'),
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
        // Input field - Pill shape for search bars
        '.bl-input': {
          width: '100%',
          padding: `${theme('spacing.3')} ${theme('spacing.4')}`,
          borderRadius: theme('borderRadius.md'),
          border: `1px solid ${theme('colors.neutral.300')}`,
          backgroundColor: theme('colors.neutral.50'),
          fontSize: theme('fontSize.body-md[0]'),
          transition: 'all 0.15s ease-out',
          '&:focus': {
            outline: 'none',
            backgroundColor: theme('colors.white'),
            borderColor: theme('colors.primary.DEFAULT'),
            boxShadow: `0 0 0 3px ${theme('colors.primary.100')}`,
          },
          '&::placeholder': {
            color: theme('colors.neutral.400'),
          },
        },
        // Pill-shaped search input
        '.bl-search-input': {
          width: '100%',
          padding: `${theme('spacing.3')} ${theme('spacing.4')}`,
          paddingLeft: theme('spacing.10'),
          borderRadius: theme('borderRadius.full'),  // Pill shape
          border: 'none',
          backgroundColor: theme('colors.neutral.50'),
          fontSize: theme('fontSize.body-md[0]'),
          transition: 'all 0.15s ease-out',
          '&:focus': {
            outline: 'none',
            backgroundColor: theme('colors.white'),
            boxShadow: `0 0 0 2px ${theme('colors.primary.200')}`,
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
        // Outlined icon circle - Minimal aesthetic
        '.bl-icon-circle': {
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          borderRadius: theme('borderRadius.full'),
          border: '2px solid currentColor',
          transition: 'all 0.15s ease-out',
        },
      })
    }),
  ]
}
