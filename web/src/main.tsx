import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { AppRoot } from "@telegram-apps/telegram-ui";
import "@telegram-apps/telegram-ui/dist/styles.css";

import { App } from "./app/App";
import { ErrorBoundary } from "./app/ErrorBoundary";
import { AuthProvider } from "./features/auth/useAuth";
import "./styles.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <ErrorBoundary>
      <AppRoot>
        <AuthProvider>
          <App />
        </AuthProvider>
      </AppRoot>
    </ErrorBoundary>
  </StrictMode>,
);
