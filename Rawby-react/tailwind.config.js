/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // Accent — driven by --c-* triplets (swaps with the active theme).
        cinema: {
          300: "rgb(var(--c-300) / <alpha-value>)",
          400: "rgb(var(--c-400) / <alpha-value>)",
          500: "rgb(var(--c-500) / <alpha-value>)",
          600: "rgb(var(--c-600) / <alpha-value>)",
          700: "rgb(var(--c-700) / <alpha-value>)",
        },
        green: {
          300: "#8FBD93",
          400: "#6FA373",
          500: "#5A8A5E",
          600: "#3D6B41",
          700: "#2A4D2D",
        },
        // Surfaces / text — driven by light/dark semantic tokens.
        ink: {
          bg: "rgb(var(--bg) / <alpha-value>)",
          surface: "rgb(var(--surface) / <alpha-value>)",
          card: "rgb(var(--card) / <alpha-value>)",
        },
        text: {
          hi: "rgb(var(--text-hi) / <alpha-value>)",
          dim: "rgb(var(--text-dim) / <alpha-value>)",
        },
        hairline: "rgb(var(--hairline))",
        "hairline-strong": "rgb(var(--hairline-strong))",
        glass: "rgb(var(--glass))",
        "glass-hover": "rgb(var(--glass-hover))",
        field: "rgb(var(--field))",
        chip: "rgb(var(--chip))",
        divide: "rgb(var(--divide))",
        danger: "#EF4444",
        warning: "#F59E0B",
        caution: "#FBBF24",
        success: "#22C55E",
        info: "#3B82F6",
      },
      fontFamily: {
        display: ['"Playfair Display"', "serif"],
        body: ["Inter", "system-ui", "sans-serif"],
      },
      borderRadius: { glass: "18px" },
      zIndex: { bg: "-10", base: "10", nav: "30", grain: "40", modal: "50", toast: "60" },
      transitionTimingFunction: {
        out: "cubic-bezier(0.22,1,0.36,1)",
        in: "cubic-bezier(0.4,0,1,1)",
        cinema: "cubic-bezier(0.34,1.32,0.64,1)",
      },
      maxWidth: { prose: "68ch" },
      boxShadow: {
        glass: "0 1px 0 0 rgba(255,255,255,0.04) inset, 0 12px 28px -6px rgba(0,0,0,0.5)",
        glow: "0 0 0 1px rgb(var(--glow) / 0.22), 0 10px 34px -8px rgb(var(--glow) / 0.45)",
        "glow-sm": "0 0 0 1px rgb(var(--glow) / 0.18), 0 6px 18px -6px rgb(var(--glow) / 0.4)",
      },
      backgroundImage: {
        "level-sequence": "linear-gradient(135deg,#6FA373,#3D6B41)",
        "level-short": "linear-gradient(135deg,#E8B647,#C97E2C)",
        "level-story": "linear-gradient(135deg,#E85D75,#B12B5C)",
      },
      keyframes: {
        "grain-shift": {
          "0%,100%": { transform: "translate(0,0)" },
          "10%": { transform: "translate(-5%,-5%)" },
          "30%": { transform: "translate(3%,-8%)" },
          "50%": { transform: "translate(-4%,6%)" },
          "70%": { transform: "translate(6%,3%)" },
          "90%": { transform: "translate(-6%,-3%)" },
        },
        "pulse-soft": {
          "0%,100%": { opacity: "0.55" },
          "50%": { opacity: "1" },
        },
        shimmer: {
          "100%": { transform: "translateX(100%)" },
        },
        "fade-in": {
          from: { opacity: "0" },
          to: { opacity: "1" },
        },
      },
      animation: {
        grain: "grain-shift 0.8s steps(4) infinite",
        "pulse-soft": "pulse-soft 2s ease-in-out infinite",
        shimmer: "shimmer 1.6s ease-in-out infinite",
        "fade-in": "fade-in 0.4s ease-out both",
      },
    },
  },
  plugins: [],
};
