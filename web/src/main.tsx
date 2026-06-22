import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import { App } from "./app/App";
import { ErrorBoundary } from "./app/ErrorBoundary";
import { AuthProvider } from "./features/auth/useAuth";
import { initTheme } from "./shared/theme";
import "./styles.css";

// Resolve the theme before first paint (avoids a flash of the wrong scheme).
initTheme();

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <ErrorBoundary>
      <AuthProvider>
        <App />
      </AuthProvider>
    </ErrorBoundary>
  </StrictMode>,
);
