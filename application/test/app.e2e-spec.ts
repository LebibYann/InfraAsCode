import request from 'supertest';
import { TEST_CONFIG } from './test-config';

/**
 * Basic smoke test to verify API is accessible
 * More comprehensive tests are in:
 * - unauthenticated.e2e-spec.ts
 * - auth.e2e-spec.ts
 * - tasks.e2e-spec.ts
 * - edge-cases.e2e-spec.ts
 * - load-test.e2e-spec.ts
 */
describe('AppController (e2e)', () => {
  const apiUrl = TEST_CONFIG.apiUrl;

  it('/health (GET) - should return health status', () => {
    return request(apiUrl)
      .get('/health')
      .expect(200)
      .expect((res) => {
        expect(res.body).toHaveProperty('status', 'ok');
        expect(res.body).toHaveProperty('timestamp');
      });
  });
});
