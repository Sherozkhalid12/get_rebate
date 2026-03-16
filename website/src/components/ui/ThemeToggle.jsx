import { IconGlyph } from './IconGlyph';
import { useTheme } from '../../context/ThemeContext';

export function ThemeToggle() {
  const { isDark, toggleTheme } = useTheme();

  return (
    <button
      type="button"
      className="theme-toggle btn ghost tiny"
      onClick={toggleTheme}
      aria-label={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
      title={isDark ? 'Light mode' : 'Dark mode'}
    >
      <IconGlyph name={isDark ? 'lightMode' : 'darkMode'} filled />
    </button>
  );
}
