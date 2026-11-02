import React from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "./style.css";

class AppErrorBoundary extends React.Component<
  { children: React.ReactNode },
  { error: Error | null }
> {
  state = { error: null as Error | null };

  static getDerivedStateFromError(error: Error) {
    return { error };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error("[Carwash POS] render error", error, info);
  }

  render() {
    if (!this.state.error) return this.props.children;
    return (
      <div style={{
        minHeight: "100dvh",
        display: "grid",
        placeItems: "center",
        padding: 24,
        background: "#0f172a",
        color: "#f8fafc",
        fontFamily: "system-ui, sans-serif",
      }}>
        <div style={{ maxWidth: 720, width: "100%" }}>
          <h2 style={{ marginBottom: 8 }}>Carwash POS encountered an error</h2>
          <p style={{ opacity: 0.85 }}>
            The app did not go blank silently. The error was captured below.
          </p>
          <pre style={{
            whiteSpace: "pre-wrap",
            background: "#020617",
            padding: 16,
            borderRadius: 10,
            overflow: "auto",
          }}>
            {this.state.error.message}
          </pre>
          <button
            type="button"
            onClick={() => window.location.reload()}
            style={{ padding: "10px 16px", borderRadius: 8, cursor: "pointer" }}
          >
            Reload POS
          </button>
        </div>
      </div>
    );
  }
}



createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <AppErrorBoundary>
      <App />
    </AppErrorBoundary>
  </React.StrictMode>,
);

// Service worker → offline app shell
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    if (import.meta.env.DEV) {
      // Dev: unregister so Vite HMR is not blocked
      navigator.serviceWorker.getRegistrations().then((regs) => {
        regs.forEach((r) => r.unregister());
      });
      return;
    }
    navigator.serviceWorker
      .register("/sw.js")
      .then((reg) => {
        setInterval(() => reg.update().catch(() => {}), 60 * 60 * 1000);
      })
      .catch((err) => console.warn("SW registration failed:", err));
  });
}

const boot = document.getElementById("offline-boot");
if (boot) boot.classList.remove("show");
