// Single place to turn an API error (envelope) into a human message.
interface ErrorEnvelope {
  response?: {
    data?: { error?: { message?: string; details?: Record<string, string[]> } };
  };
}

export function errorMessage(e: unknown, fallback = "Something went wrong."): string {
  const err = (e as ErrorEnvelope)?.response?.data?.error;
  if (err) {
    if (err.details) {
      const first = Object.values(err.details)[0];
      if (Array.isArray(first) && first.length) return String(first[0]);
    }
    if (err.message) return err.message;
  }
  return fallback;
}
