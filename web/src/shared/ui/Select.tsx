// Custom dropdown — native <select> option lists can't be themed, so this
// renders a glass menu that matches the aurora design. The menu is portaled to
// <body> with fixed positioning so it escapes the backdrop-filter stacking
// contexts of the cards (otherwise it paints behind later cards).
import { useCallback, useEffect, useLayoutEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";

export interface Option {
  value: string | number;
  label: string;
}

interface Rect {
  left: number;
  top: number;
  width: number;
}

export function Select({
  value,
  options,
  onChange,
  placeholder = "Select…",
}: {
  value: string | number | "";
  options: Option[];
  onChange: (value: string | number) => void;
  placeholder?: string;
}) {
  const [open, setOpen] = useState(false);
  const [rect, setRect] = useState<Rect | null>(null);
  const controlRef = useRef<HTMLButtonElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  const reposition = useCallback(() => {
    const el = controlRef.current;
    if (!el) return;
    const r = el.getBoundingClientRect();
    setRect({ left: r.left, top: r.bottom + 6, width: r.width });
  }, []);

  useLayoutEffect(() => {
    if (open) reposition();
  }, [open, reposition]);

  useEffect(() => {
    if (!open) return;
    const onDoc = (e: MouseEvent) => {
      const target = e.target as Node;
      if (controlRef.current?.contains(target)) return;
      if (menuRef.current?.contains(target)) return;
      setOpen(false);
    };
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setOpen(false);
    document.addEventListener("mousedown", onDoc);
    window.addEventListener("keydown", onKey);
    // Reposition while open so it tracks the control; close on scroll-away is
    // avoided — fixed coords follow the page instead.
    window.addEventListener("scroll", reposition, true);
    window.addEventListener("resize", reposition);
    return () => {
      document.removeEventListener("mousedown", onDoc);
      window.removeEventListener("keydown", onKey);
      window.removeEventListener("scroll", reposition, true);
      window.removeEventListener("resize", reposition);
    };
  }, [open, reposition]);

  const current = options.find((o) => o.value === value);

  return (
    <div className="sel">
      <button
        ref={controlRef}
        type="button"
        className={`input sel__control ${current ? "" : "sel__control--placeholder"}`}
        onClick={() => setOpen((o) => !o)}
        aria-haspopup="listbox"
        aria-expanded={open}
      >
        <span>{current ? current.label : placeholder}</span>
        <svg className={`sel__chev ${open ? "is-open" : ""}`} width="14" height="14" viewBox="0 0 12 8" aria-hidden>
          <path d="M1 1l5 5 5-5" stroke="currentColor" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </button>
      {open && rect &&
        createPortal(
          <div
            ref={menuRef}
            className="sel__menu"
            role="listbox"
            style={{ left: rect.left, top: rect.top, width: rect.width }}
          >
            {options.map((o) => (
              <button
                type="button"
                key={o.value}
                role="option"
                aria-selected={o.value === value}
                className={`sel__option ${o.value === value ? "is-selected" : ""}`}
                onClick={() => {
                  onChange(o.value);
                  setOpen(false);
                }}
              >
                {o.label}
              </button>
            ))}
          </div>,
          document.body,
        )}
    </div>
  );
}
