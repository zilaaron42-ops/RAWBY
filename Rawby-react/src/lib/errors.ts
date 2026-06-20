import { AxiosError } from "axios";

/** Turn an axios/login error into a human message using the server payload. */
export function authErrorMessage(err: unknown): string {
  if (err instanceof AxiosError) {
    // No response = network / cold-start / CORS.
    if (!err.response) {
      return "Can't reach the server. It may be waking up — wait a moment and try again.";
    }
    const data = err.response.data as { error?: string; message?: string } | undefined;
    const code = data?.error;
    const status = err.response.status;

    if (code === "email_not_verified") {
      return data?.message ?? "Please verify your email before signing in. Check your inbox.";
    }
    if (status === 401) return "Invalid username or password.";
    if (status === 409) return "That username or email is already taken.";
    if (status === 400) return data?.message ?? data?.error ?? "Missing required fields.";
    if (status >= 500) return "Server error. Try again in a moment.";
    return data?.message ?? data?.error ?? "Something went wrong.";
  }
  return "Something went wrong. Try again.";
}
