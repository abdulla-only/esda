import { ReactNode, useState } from "react";

import { getTheme, setTheme, Theme } from "../shared/theme";

const OPTIONS: { value: Theme; label: string; glyph: ReactNode }[] = [
  { value: "light", label: "Light", glyph: <SunGlyph /> },
  { value: "dark", label: "Dark", glyph: <MoonGlyph /> },
  { value: "system", label: "System", glyph: <SystemGlyph /> },
];

export function ThemeToggle() {
  const [theme, setLocal] = useState<Theme>(getTheme());

  const choose = (t: Theme) => {
    setTheme(t);
    setLocal(t);
  };

  return (
    <div className="theme-toggle" role="group" aria-label="Theme">
      {OPTIONS.map((o) => (
        <button
          key={o.value}
          type="button"
          className={`theme-toggle__btn ${theme === o.value ? "active" : ""}`}
          onClick={() => choose(o.value)}
          aria-label={o.label}
          aria-pressed={theme === o.value}
          title={o.label}
        >
          {o.glyph}
        </button>
      ))}
    </div>
  );
}

function SunGlyph() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden>
      <circle cx="12" cy="12" r="4" fill="currentColor" />
      <path
        d="M12 2v2m0 16v2M4.9 4.9l1.4 1.4m11.4 11.4l1.4 1.4M2 12h2m16 0h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
      />
    </svg>
  );
}

function MoonGlyph() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden>
      <path
        d="M21 12.8A9 9 0 1111.2 3a7 7 0 009.8 9.8z"
        fill="currentColor"
      />
    </svg>
  );
}

function SystemGlyph() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden>
      <rect x="3" y="4" width="18" height="12" rx="2" stroke="currentColor" strokeWidth="2" />
      <path d="M8 20h8M12 16v4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}
