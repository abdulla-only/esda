import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import { App } from "./app/App";
import { ErrorBoundary } from "./app/ErrorBoundary";
import { AuthProvider } from "./features/auth/useAuth";
import { initTheme } from "./shared/theme";
import { ConfirmProvider } from "./shared/ui/confirm";
import { ToastProvider } from "./shared/ui/toast";
import "./styles.css";

// Resolve the theme before first paint (avoids a flash of the wrong scheme).
initTheme();

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <ErrorBoundary>
      <ToastProvider>
        <ConfirmProvider>
          <AuthProvider>
            <App />
          </AuthProvider>
        </ConfirmProvider>
      </ToastProvider>
    </ErrorBoundary>
  </StrictMode>,
);
