// Custom dropdown — native <select> option lists can't be themed, so this
// renders a glass menu that matches the aurora design.
import { useEffect, useRef, useState } from "react";

export interface Option {
  value: string | number;
  label: string;
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
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const onDoc = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && setOpen(false);
    document.addEventListener("mousedown", onDoc);
    window.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onDoc);
      window.removeEventListener("keydown", onKey);
    };
  }, [open]);

  const current = options.find((o) => o.value === value);

  return (
    <div className="sel" ref={ref}>
      <button
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
      {open && (
        <div className="sel__menu" role="listbox">
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
        </div>
      )}
    </div>
  );
}
