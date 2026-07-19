export class AppError extends Error {
  constructor({
    status = 500,
    code = 'INTERNAL_ERROR',
    message = 'The request could not be completed.',
    details,
    retryAfterSeconds,
    cause,
  } = {}) {
    super(message, { cause });
    this.name = 'AppError';
    this.status = status;
    this.code = code;
    this.details = details;
    this.retryAfterSeconds = retryAfterSeconds;
  }
}

export class ProviderError extends AppError {
  constructor({
    provider,
    status = 502,
    code = 'PROVIDER_ERROR',
    message,
    retryAfterSeconds,
    cause,
  }) {
    super({
      status,
      code,
      message: message || `${provider} could not complete the scan.`,
      retryAfterSeconds,
      cause,
    });
    this.name = 'ProviderError';
    this.provider = provider;
  }
}

export function errorPayload(error) {
  const appError =
    error instanceof AppError
      ? error
      : new AppError({ cause: error });

  const payload = {
    error: {
      code: appError.code,
      message: appError.message,
    },
  };

  if (appError.details !== undefined) {
    payload.error.details = appError.details;
  }

  if (appError.retryAfterSeconds !== undefined) {
    payload.error.retryAfterSeconds = appError.retryAfterSeconds;
  }

  return {
    status: appError.status,
    payload,
    retryAfterSeconds: appError.retryAfterSeconds,
  };
}
