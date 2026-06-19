import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { AppRoot } from "@telegram-apps/telegram-ui";
import "@telegram-apps/telegram-ui/dist/styles.css";

import { App } from "./app/App";
import { AuthProvider } from "./features/auth/useAuth";
import { initTelegram } from "./shared/telegram";
import "./styles.css";

// Must run before rendering so the SDK/UI have an environment to read.
initTelegram();

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <AppRoot>
      <AuthProvider>
        <App />
      </AuthProvider>
    </AppRoot>
  </StrictMode>,
);
