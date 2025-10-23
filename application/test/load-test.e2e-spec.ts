import request from 'supertest';
import { TEST_CONFIG, getUserIdFromToken } from './test-config';

/**
 * Load Testing Suite
 * Tests API behavior under heavy concurrent load
 * This suite should run LAST and only if all previous tests passed
 *
 * Concurrency can be configured via --concurrency parameter:
 * npm run test:e2e -- --concurrency 1000
 */
describe('Load Testing - DDOS Simulation (e2e)', () => {
  const apiUrl = TEST_CONFIG.apiUrl;
  const CONCURRENT_REQUESTS = TEST_CONFIG.concurrency;
  let authToken: string;
  let userId: string;
  const uniqueId = Date.now();

  const testUser = {
    email: `loadtest${uniqueId}@example.com`,
    username: `loadtest${uniqueId}`,
    password: 'LoadTest123!',
  };

  beforeAll(async () => {
    console.log('[LOAD TEST] Setting up test user...');

    // Register and login to get auth token
    const registerRes = await request(apiUrl)
      .post('/auth/register')
      .send(testUser);

    authToken = registerRes.body.access_token;
    userId = getUserIdFromToken(authToken);

    // Create some initial tasks for testing
    console.log('[LOAD TEST] Creating initial test data...');
    const initialTasks = Array.from({ length: 10 }, (_, i) => ({
      title: `Load Test Task ${i}`,
      content: `Content ${i}`,
      due_date: '2025-12-31',
      request_timestamp: new Date().toISOString(),
    }));

    await Promise.all(
      initialTasks.map(task =>
        request(apiUrl)
          .post('/tasks')
          .set('Authorization', `Bearer ${authToken}`)
          .send(task)
      )
    );

    console.log('[LOAD TEST] Setup complete. Starting load tests...');
  }, 60000); // 60 second timeout for setup

  describe('Health Endpoint Load Test', () => {
    it(`should handle ${CONCURRENT_REQUESTS} concurrent health check requests`, async () => {
      console.log(`[LOAD TEST] Sending ${CONCURRENT_REQUESTS} requests to /health...`);
      const startTime = Date.now();

      const promises = Array.from({ length: CONCURRENT_REQUESTS }, () =>
        request(apiUrl)
          .get('/health')
          .then(res => ({ status: res.status, success: res.status === 200 }))
          .catch(err => ({ status: err.status || 500, success: false }))
      );

      const results = await Promise.all(promises);
      const endTime = Date.now();
      const duration = endTime - startTime;

      // Analysis
      const successful = results.filter(r => r.success).length;
      const failed = results.filter(r => !r.success).length;
      const successRate = (successful / CONCURRENT_REQUESTS) * 100;

      console.log('[LOAD TEST] Health endpoint results:');
      console.log(`  - Total requests: ${CONCURRENT_REQUESTS}`);
      console.log(`  - Successful: ${successful} (${successRate.toFixed(2)}%)`);
      console.log(`  - Failed: ${failed}`);
      console.log(`  - Duration: ${duration}ms`);
      console.log(`  - Avg response time: ${(duration / CONCURRENT_REQUESTS).toFixed(2)}ms`);

      // We expect at least 95% success rate
      expect(successRate).toBeGreaterThanOrEqual(95);
    }, 120000); // 120 second timeout
  });

  describe('Authentication Load Test', () => {
    it(`should handle ${CONCURRENT_REQUESTS} concurrent login requests`, async () => {
      console.log(`[LOAD TEST] Sending ${CONCURRENT_REQUESTS} concurrent login requests...`);
      const startTime = Date.now();

      const promises = Array.from({ length: CONCURRENT_REQUESTS }, () =>
        request(apiUrl)
          .post('/auth/login')
          .send({
            email: testUser.email,
            password: testUser.password,
          })
          .then(res => ({ status: res.status, success: res.status === 200 }))
          .catch(err => ({ status: err.status || 500, success: false }))
      );

      const results = await Promise.all(promises);
      const endTime = Date.now();
      const duration = endTime - startTime;

      const successful = results.filter(r => r.success).length;
      const failed = results.filter(r => !r.success).length;
      const successRate = (successful / CONCURRENT_REQUESTS) * 100;

      console.log('[LOAD TEST] Login endpoint results:');
      console.log(`  - Total requests: ${CONCURRENT_REQUESTS}`);
      console.log(`  - Successful: ${successful} (${successRate.toFixed(2)}%)`);
      console.log(`  - Failed: ${failed}`);
      console.log(`  - Duration: ${duration}ms`);
      console.log(`  - Avg response time: ${(duration / CONCURRENT_REQUESTS).toFixed(2)}ms`);

      expect(successRate).toBeGreaterThanOrEqual(90);
    }, 120000);
  });

  describe('Task Creation Load Test', () => {
    it(`should handle ${CONCURRENT_REQUESTS} concurrent task creation requests`, async () => {
      console.log(`[LOAD TEST] Sending ${CONCURRENT_REQUESTS} concurrent task creation requests...`);
      const startTime = Date.now();

      const promises = Array.from({ length: CONCURRENT_REQUESTS }, (_, i) =>
        request(apiUrl)
          .post('/tasks')
          .set('Authorization', `Bearer ${authToken}`)
          .send({
            title: `Load Test Task ${uniqueId}-${i}`,
            content: `Content for load test ${i}`,
            due_date: '2025-12-31',
            request_timestamp: new Date().toISOString(),
          })
          .then(res => ({ status: res.status, success: res.status === 201, id: res.body.id }))
          .catch(err => ({ status: err.status || 500, success: false, id: null }))
      );

      const results = await Promise.all(promises);
      const endTime = Date.now();
      const duration = endTime - startTime;

      const successful = results.filter(r => r.success).length;
      const failed = results.filter(r => !r.success).length;
      const successRate = (successful / CONCURRENT_REQUESTS) * 100;

      console.log('[LOAD TEST] Task creation results:');
      console.log(`  - Total requests: ${CONCURRENT_REQUESTS}`);
      console.log(`  - Successful: ${successful} (${successRate.toFixed(2)}%)`);
      console.log(`  - Failed: ${failed}`);
      console.log(`  - Duration: ${duration}ms`);
      console.log(`  - Avg response time: ${(duration / CONCURRENT_REQUESTS).toFixed(2)}ms`);

      // Verify all created tasks have unique IDs
      const successfulIds = results.filter(r => r.id).map(r => r.id);
      const uniqueIds = new Set(successfulIds);
      console.log(`  - Unique task IDs: ${uniqueIds.size}/${successful}`);

      expect(successRate).toBeGreaterThanOrEqual(90);
      expect(uniqueIds.size).toBe(successful); // All IDs should be unique
    }, 120000);
  });

  describe('Task Retrieval Load Test', () => {
    it(`should handle ${CONCURRENT_REQUESTS} concurrent GET /tasks requests`, async () => {
      console.log(`[LOAD TEST] Sending ${CONCURRENT_REQUESTS} concurrent GET /tasks requests...`);
      const startTime = Date.now();

      const promises = Array.from({ length: CONCURRENT_REQUESTS }, () =>
        request(apiUrl)
          .get('/tasks')
          .set('Authorization', `Bearer ${authToken}`)
          .then(res => ({ status: res.status, success: res.status === 200, count: res.body?.length || 0 }))
          .catch(err => ({ status: err.status || 500, success: false, count: 0 }))
      );

      const results = await Promise.all(promises);
      const endTime = Date.now();
      const duration = endTime - startTime;

      const successful = results.filter(r => r.success).length;
      const failed = results.filter(r => !r.success).length;
      const successRate = (successful / CONCURRENT_REQUESTS) * 100;

      console.log('[LOAD TEST] GET /tasks results:');
      console.log(`  - Total requests: ${CONCURRENT_REQUESTS}`);
      console.log(`  - Successful: ${successful} (${successRate.toFixed(2)}%)`);
      console.log(`  - Failed: ${failed}`);
      console.log(`  - Duration: ${duration}ms`);
      console.log(`  - Avg response time: ${(duration / CONCURRENT_REQUESTS).toFixed(2)}ms`);

      expect(successRate).toBeGreaterThanOrEqual(95);
    }, 120000);
  });

  describe('Mixed Operations Load Test', () => {
    let taskIds: string[] = [];

    beforeAll(async () => {
      // Create some tasks to update/delete during load test
      console.log('[LOAD TEST] Creating tasks for mixed operations...');
      const createPromises = Array.from({ length: 50 }, (_, i) =>
        request(apiUrl)
          .post('/tasks')
          .set('Authorization', `Bearer ${authToken}`)
          .send({
            title: `Mixed Op Task ${i}`,
            content: `Content ${i}`,
            due_date: '2025-12-31',
            request_timestamp: new Date().toISOString(),
          })
          .then(res => res.body.id)
      );

      taskIds = await Promise.all(createPromises);
      console.log(`[LOAD TEST] Created ${taskIds.length} tasks for mixed operations`);
    });

    it(`should handle ${CONCURRENT_REQUESTS} mixed operations (CREATE, READ, UPDATE, DELETE)`, async () => {
      console.log(`[LOAD TEST] Sending ${CONCURRENT_REQUESTS} mixed operation requests...`);
      const startTime = Date.now();

      const operations = ['CREATE', 'READ', 'UPDATE', 'DELETE', 'LIST'];

      const promises = Array.from({ length: CONCURRENT_REQUESTS }, (_, i) => {
        const operation = operations[i % operations.length];
        const randomTaskId = taskIds[Math.floor(Math.random() * taskIds.length)];

        switch (operation) {
          case 'CREATE':
            return request(apiUrl)
              .post('/tasks')
              .set('Authorization', `Bearer ${authToken}`)
              .send({
                title: `Mixed Load Task ${i}`,
                content: `Content ${i}`,
                due_date: '2025-12-31',
                request_timestamp: new Date().toISOString(),
              })
              .then(res => ({ operation, status: res.status, success: res.status === 201 }))
              .catch(err => ({ operation, status: err.status || 500, success: false }));

          case 'READ':
            return request(apiUrl)
              .get(`/tasks/${randomTaskId}`)
              .set('Authorization', `Bearer ${authToken}`)
              .then(res => ({ operation, status: res.status, success: res.status === 200 }))
              .catch(err => ({ operation, status: err.status || 500, success: false }));

          case 'UPDATE':
            return request(apiUrl)
              .put(`/tasks/${randomTaskId}`)
              .set('Authorization', `Bearer ${authToken}`)
              .send({
                title: `Updated in load test ${i}`,
                request_timestamp: new Date().toISOString(),
              })
              .then(res => ({ operation, status: res.status, success: res.status === 200 || res.status === 404 }))
              .catch(err => ({ operation, status: err.status || 500, success: false }));

          case 'DELETE':
            return request(apiUrl)
              .delete(`/tasks/${randomTaskId}`)
              .set('Authorization', `Bearer ${authToken}`)
              .send({
                request_timestamp: new Date().toISOString(),
              })
              .then(res => ({ operation, status: res.status, success: res.status === 200 || res.status === 404 }))
              .catch(err => ({ operation, status: err.status || 500, success: false }));

          case 'LIST':
          default:
            return request(apiUrl)
              .get('/tasks')
              .set('Authorization', `Bearer ${authToken}`)
              .then(res => ({ operation, status: res.status, success: res.status === 200 }))
              .catch(err => ({ operation, status: err.status || 500, success: false }));
        }
      });

      const results = await Promise.all(promises);
      const endTime = Date.now();
      const duration = endTime - startTime;

      const successful = results.filter(r => r.success).length;
      const failed = results.filter(r => !r.success).length;
      const successRate = (successful / CONCURRENT_REQUESTS) * 100;

      // Group by operation
      const byOperation = operations.reduce((acc, op) => {
        const opResults = results.filter(r => r.operation === op);
        acc[op] = {
          total: opResults.length,
          successful: opResults.filter(r => r.success).length,
          failed: opResults.filter(r => !r.success).length,
        };
        return acc;
      }, {} as Record<string, { total: number; successful: number; failed: number }>);

      console.log('[LOAD TEST] Mixed operations results:');
      console.log(`  - Total requests: ${CONCURRENT_REQUESTS}`);
      console.log(`  - Overall successful: ${successful} (${successRate.toFixed(2)}%)`);
      console.log(`  - Overall failed: ${failed}`);
      console.log(`  - Duration: ${duration}ms`);
      console.log(`  - Avg response time: ${(duration / CONCURRENT_REQUESTS).toFixed(2)}ms`);
      console.log('  - By operation:');
      Object.entries(byOperation).forEach(([op, stats]) => {
        const opSuccessRate = (stats.successful / stats.total) * 100;
        console.log(`    * ${op}: ${stats.successful}/${stats.total} (${opSuccessRate.toFixed(2)}%)`);
      });

      // We expect at least 85% success rate for mixed operations (more lenient due to race conditions)
      expect(successRate).toBeGreaterThanOrEqual(85);
    }, 180000); // 180 second timeout for complex operations
  });

  describe('Stress Test - Rapid Fire', () => {
    it('should handle rapid successive requests to same endpoint', async () => {
      console.log('[LOAD TEST] Sending rapid fire requests...');
      const rapidCount = 100;

      // Send 100 requests as fast as possible without Promise.all
      const results: any[] = [];
      const startTime = Date.now();

      for (let i = 0; i < rapidCount; i++) {
        try {
          const res = await request(apiUrl)
            .get('/health')
            .timeout(5000);
          results.push({ success: res.status === 200 });
        } catch (err) {
          results.push({ success: false });
        }
      }

      const endTime = Date.now();
      const duration = endTime - startTime;
      const successful = results.filter(r => r.success).length;

      console.log('[LOAD TEST] Rapid fire results:');
      console.log(`  - Total requests: ${rapidCount}`);
      console.log(`  - Successful: ${successful}`);
      console.log(`  - Duration: ${duration}ms`);
      console.log(`  - Requests per second: ${(rapidCount / (duration / 1000)).toFixed(2)}`);

      expect(successful).toBeGreaterThanOrEqual(rapidCount * 0.85); // 85% success (allows for rate limiting)
    }, 120000);
  });

  afterAll(() => {
    console.log('[LOAD TEST] All load tests completed!');
    console.log('[LOAD TEST] ========================================');
  });
});
