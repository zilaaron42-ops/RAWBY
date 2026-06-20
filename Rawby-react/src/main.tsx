import React from "react";
import ReactDOM from "react-dom/client";
import { QueryClientProvider } from "@tanstack/react-query";
import { queryClient } from "./lib/queryClient";
import { useTheme, applyTheme } from "./store/theme";
import App from "./App";
import "./index.css";

// Apply persisted theme before first paint to avoid a flash.
const t = useTheme.getState();
applyTheme(t.mode, t.accent);

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </React.StrictMode>
);
