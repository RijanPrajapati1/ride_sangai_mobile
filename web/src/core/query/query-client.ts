import { MutationCache, QueryCache, QueryClient } from '@tanstack/react-query';
import { toast } from 'sonner';
import { ApiError, errorMessage } from '@/core/http/errors';

declare module '@tanstack/react-query' {
  interface Register {
    mutationMeta: { silent?: boolean };
  }
}

function shouldToast(err: unknown) {
  // 401s redirect to the login page; aborted requests are not errors.
  if (err instanceof ApiError && err.status === 401) return false;
  if (err instanceof DOMException && err.name === 'AbortError') return false;
  return true;
}

/** Errors surface as toasts carrying the API's `message`. */
export function makeQueryClient() {
  return new QueryClient({
    queryCache: new QueryCache({
      onError: (err) => {
        if (shouldToast(err)) toast.error(errorMessage(err), { id: errorMessage(err) });
      },
    }),
    mutationCache: new MutationCache({
      onError: (err, _vars, _ctx, mutation) => {
        if (mutation.meta?.silent) return;
        if (shouldToast(err)) toast.error(errorMessage(err));
      },
    }),
    defaultOptions: {
      queries: {
        staleTime: 30_000,
        refetchOnWindowFocus: false,
        retry: (count, err) => {
          if (err instanceof ApiError && err.status >= 400 && err.status < 500) return false;
          return count < 1;
        },
      },
    },
  });
}
