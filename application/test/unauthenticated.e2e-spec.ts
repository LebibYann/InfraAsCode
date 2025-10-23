import request from 'supertest';
import { TEST_CONFIG } from './test-config';

describe('Unauthenticated Access (e2e)', () => {
  const apiUrl = TEST_CONFIG.apiUrl;

  describe('Protected Task Endpoints - Should Return 401', () => {
    it('/tasks (POST) - should reject without auth', () => {
      return request(apiUrl)
        .post('/tasks')
        .send({
          title: 'Test Task',
          content: 'Test Content',
          due_date: '2025-12-31',
          request_timestamp: new Date().toISOString(),
        })
        .expect(401);
    });

    it('/tasks (GET) - should reject without auth', () => {
      return request(apiUrl)
        .get('/tasks')
        .expect(401);
    });

    it('/tasks/:id (GET) - should reject without auth', () => {
      return request(apiUrl)
        .get('/tasks/123e4567-e89b-12d3-a456-426614174000')
        .expect(401);
    });

    it('/tasks/:id (PUT) - should reject without auth', () => {
      return request(apiUrl)
        .put('/tasks/123e4567-e89b-12d3-a456-426614174000')
        .send({
          title: 'Updated Task',
          request_timestamp: new Date().toISOString(),
        })
        .expect(401);
    });

    it('/tasks/:id (DELETE) - should reject without auth', () => {
      return request(apiUrl)
        .delete('/tasks/123e4567-e89b-12d3-a456-426614174000')
        .send({
          request_timestamp: new Date().toISOString(),
        })
        .expect(401);
    });
  });

  describe('Public Endpoints - Should Work', () => {
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
});
