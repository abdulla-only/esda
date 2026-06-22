// Theme preference: light / dark / system. The resolved value is written to
// <html data-theme="light|dark">; CSS keys off that attribute. "system" follows
// the OS and live-updates when the OS scheme changes.
export type Theme = "light" | "dark" | "system";

const KEY = "esda.theme";
const mq = window.matchMedia("(prefers-color-scheme: dark)");

let pref: Theme = (localStorage.getItem(KEY) as Theme | null) ?? "system";

function resolved(): "light" | "dark" {
  return pref === "system" ? (mq.matches ? "dark" : "light") : pref;
}

function apply(): void {
  document.documentElement.dataset.theme = resolved();
}

export function initTheme(): void {
  apply();
  mq.addEventListener("change", () => {
    if (pref === "system") apply();
  });
}

export function getTheme(): Theme {
  return pref;
}

export function setTheme(theme: Theme): void {
  pref = theme;
  localStorage.setItem(KEY, theme);
  apply();
}
