/**
 * Test configuration helper
 * Allows passing custom API URL via command line: npm run test:e2e -- --url http://localhost:3000/api/v1
 */

export const getApiUrl = (): string => {
  // Check for --url parameter in process.argv
  const urlArgIndex = process.argv.findIndex(arg => arg === '--url');
  if (urlArgIndex !== -1 && process.argv[urlArgIndex + 1]) {
    const url = process.argv[urlArgIndex + 1];
    console.log(`[TEST CONFIG] Using custom API URL: ${url}`);
    return url;
  }

  // Default URL (includes /api/v1 prefix)
  const defaultUrl = process.env.TEST_API_URL || 'http://localhost:3000/api/v1';
  console.log(`[TEST CONFIG] Using default API URL: ${defaultUrl}`);
  return defaultUrl;
};

/**
 * Decode JWT token and extract user ID from the 'sub' claim
 * @param token JWT token string
 * @returns User ID from the token payload
 */
export const getUserIdFromToken = (token: string): string => {
  try {
    // JWT format: header.payload.signature
    const parts = token.split('.');
    if (parts.length !== 3) {
      throw new Error('Invalid JWT format');
    }

    // Decode the payload (second part) - base64url encoded
    const payload = JSON.parse(Buffer.from(parts[1], 'base64').toString('utf8'));

    if (!payload.sub) {
      throw new Error('No sub claim found in JWT');
    }

    return payload.sub;
  } catch (error) {
    throw new Error(`Failed to decode JWT: ${error.message}`);
  }
};

/**
 * Add a small delay to avoid rate limiting
 * @param ms Milliseconds to wait (default: 100ms)
 */
export const delay = (ms: number = 100): Promise<void> => {
  return new Promise(resolve => setTimeout(resolve, ms));
};

/**
 * Get the concurrency level for load tests
 * Can be set via environment variable: TEST_CONCURRENCY=1000 npm run test:e2e
 * @returns Number of concurrent requests for load tests
 */
export const getConcurrency = (): number => {
  // Check for TEST_CONCURRENCY environment variable
  const envConcurrency = process.env.TEST_CONCURRENCY;
  if (envConcurrency) {
    const concurrency = parseInt(envConcurrency, 10);
    if (!isNaN(concurrency) && concurrency > 0) {
      console.log(`[TEST CONFIG] Using custom concurrency: ${concurrency}`);
      return concurrency;
    }
  }

  // Default concurrency
  const defaultConcurrency = 500;
  console.log(`[TEST CONFIG] Using default concurrency: ${defaultConcurrency}`);
  return defaultConcurrency;
};

export const TEST_CONFIG = {
  apiUrl: getApiUrl(),
  timeout: 30000, // 30 seconds
  concurrency: getConcurrency(),
};
