import { QueryClient } from "@tanstack/react-query";

// Server is a cold-start Render dyno — the axios layer already retries
// transient failures, so keep React Query retries low and cache generously.
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60_000,
      gcTime: 5 * 60_000,
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});
