// ============================================================
// RAWBY — axios client
// Auth interceptor + cold-start retry (ported from Flutter
// lib/services/api_service.dart:49-77). Render free dyno sleeps
// after ~15 min idle; cold start 30-60s, so timeouts are generous
// and transient failures retry 3x with backoff (1.5s * attempt).
// ============================================================
import axios, {
  AxiosError,
  AxiosHeaders,
  type InternalAxiosRequestConfig,
} from "axios";
import { getToken, forceLogout } from "../store/auth";

const BASE_URL =
  import.meta.env.VITE_API_BASE_URL ?? "https://rawby-1.onrender.com";

export const api = axios.create({
  baseURL: BASE_URL,
  timeout: 60000, // cold-start friendly
  headers: { "Content-Type": "application/json", Accept: "application/json" },
});

// Inject bearer token on every request.
api.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = getToken();
  if (token) {
    config.headers = AxiosHeaders.from(config.headers);
    config.headers.set("Authorization", `Bearer ${token}`);
  }
  return config;
});

const MAX_RETRIES = 3;

function isTransient(err: AxiosError): boolean {
  // No response = network/timeout/cold-start; or 5xx while waking.
  if (err.code === "ECONNABORTED" || err.code === "ERR_NETWORK") return true;
  if (!err.response) return true;
  return err.response.status >= 500;
}

api.interceptors.response.use(
  (res) => res,
  async (error: AxiosError) => {
    const config = error.config as
      | (InternalAxiosRequestConfig & { _retry?: number })
      | undefined;

    if (config && isTransient(error)) {
      const attempt = config._retry ?? 0;
      if (attempt < MAX_RETRIES) {
        config._retry = attempt + 1;
        await new Promise((r) => setTimeout(r, 1500 * (attempt + 1)));
        return api(config);
      }
    }

    if (error.response?.status === 401) {
      forceLogout();
      if (typeof window !== "undefined" && !location.pathname.startsWith("/login")) {
        location.assign("/login");
      }
    }
    return Promise.reject(error);
  }
);

export { BASE_URL };
