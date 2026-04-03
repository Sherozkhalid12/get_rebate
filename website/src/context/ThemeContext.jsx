import { createContext, useContext, useEffect } from 'react';

const THEME_KEY = 'getarebate_theme';

const ThemeContext = createContext(null);

/** Dark mode disabled — site is always light. Restore `useState` + sync effect from git history to re-enable. */
export function ThemeProvider({ children }) {
  const theme = 'light';

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', 'light');
    try {
      localStorage.setItem(THEME_KEY, 'light');
    } catch {
      /* ignore */
    }
  }, []);

  const toggleTheme = () => {};

  const isDark = false;

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme, isDark }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used within ThemeProvider');
  return ctx;
}
