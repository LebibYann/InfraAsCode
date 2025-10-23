import request from 'supertest';
import { TEST_CONFIG, getUserIdFromToken } from './test-config';

describe('Tasks - Edge Cases and Disorganized Operations (e2e)', () => {
  const apiUrl = TEST_CONFIG.apiUrl;
  let authToken: string;
  let userId: string;
  const uniqueId = Date.now();

  const testUser = {
    email: `edgeuser${uniqueId}@example.com`,
    username: `edgeuser${uniqueId}`,
    password: 'EdgeTest123!',
  };

  beforeAll(async () => {
    // Register and login to get auth token
    const registerRes = await request(apiUrl)
      .post('/auth/register')
      .send(testUser);

    authToken = registerRes.body.access_token;
    userId = getUserIdFromToken(authToken);

    console.log('[EDGE CASES TEST] User authenticated successfully');
  });

  describe('Disorganized Operations', () => {
    it('should handle: create -> delete -> try to update deleted task', async () => {
      // Create a task
      const createRes = await request(apiUrl)
        .post('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Task to be deleted',
          content: 'Content',
          due_date: '2025-12-31',
          request_timestamp: new Date().toISOString(),
        })
        .expect(201);

      const taskId = createRes.body.id;

      // Delete the task
      await request(apiUrl)
        .delete(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          request_timestamp: new Date().toISOString(),
        })
        .expect(200);

      // Try to update the deleted task - should return 410 Gone
      await request(apiUrl)
        .put(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Updating deleted task',
          request_timestamp: new Date().toISOString(),
        })
        .expect(410);

      // Try to get the deleted task - should return 410 Gone
      await request(apiUrl)
        .get(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(410);

      // Try to delete again - should return 410 Gone
      await request(apiUrl)
        .delete(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          request_timestamp: new Date().toISOString(),
        })
        .expect(410);
    });

    it('should handle: create -> update -> delete in rapid succession', async () => {
      // Create
      const createRes = await request(apiUrl)
        .post('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Rapid task',
          content: 'Content',
          due_date: '2025-12-31',
          request_timestamp: new Date().toISOString(),
        })
        .expect(201);

      const taskId = createRes.body.id;

      // Update immediately
      await request(apiUrl)
        .put(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Updated rapidly',
          done: true,
          request_timestamp: new Date().toISOString(),
        })
        .expect(200);

      // Delete immediately
      await request(apiUrl)
        .delete(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          request_timestamp: new Date().toISOString(),
        })
        .expect(200);
    });

    it('should handle multiple updates to same task', async () => {
      // Create a task
      const createRes = await request(apiUrl)
        .post('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Multi-update task',
          content: 'Original content',
          due_date: '2025-12-31',
          request_timestamp: new Date().toISOString(),
        })
        .expect(201);

      const taskId = createRes.body.id;

      // Update 1: Change title
      await request(apiUrl)
        .put(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Update 1',
          request_timestamp: new Date().toISOString(),
        })
        .expect(200);

      // Update 2: Change content
      await request(apiUrl)
        .put(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          content: 'Updated content',
          request_timestamp: new Date().toISOString(),
        })
        .expect(200);

      // Update 3: Mark as done
      await request(apiUrl)
        .put(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          done: true,
          request_timestamp: new Date().toISOString(),
        })
        .expect(200);

      // Update 4: Unmark as done
      await request(apiUrl)
        .put(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          done: false,
          request_timestamp: new Date().toISOString(),
        })
        .expect(200);

      // Verify final state
      const finalRes = await request(apiUrl)
        .get(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(finalRes.body.title).toBe('Update 1');
      expect(finalRes.body.content).toBe('Updated content');
      expect(finalRes.body.done).toBe(false);
    });
  });

  describe('User Isolation - Security Tests', () => {
    let otherUserToken: string;
    let otherUserId: string;
    let myTaskId: string;
    let otherTaskId: string;

    beforeAll(async () => {
      // Create another user
      const otherUser = {
        email: `otheruser${uniqueId}@example.com`,
        username: `otheruser${uniqueId}`,
        password: 'OtherTest123!',
      };

      const registerRes = await request(apiUrl)
        .post('/auth/register')
        .send(otherUser);

      otherUserToken = registerRes.body.access_token;
      otherUserId = getUserIdFromToken(otherUserToken);

      // Create task for first user
      const myTaskRes = await request(apiUrl)
        .post('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'My private task',
          content: 'Content',
          due_date: '2025-12-31',
          request_timestamp: new Date().toISOString(),
        });
      myTaskId = myTaskRes.body.id;

      // Create task for other user
      const otherTaskRes = await request(apiUrl)
        .post('/tasks')
        .set('Authorization', `Bearer ${otherUserToken}`)
        .send({
          title: 'Other user task',
          content: 'Content',
          due_date: '2025-12-31',
          request_timestamp: new Date().toISOString(),
        });
      otherTaskId = otherTaskRes.body.id;
    });

    it('should not allow user to access another user\'s task', async () => {
      // Try to get other user's task
      await request(apiUrl)
        .get(`/tasks/${otherTaskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404); // Task not found for this user
    });

    it('should not allow user to update another user\'s task', async () => {
      await request(apiUrl)
        .put(`/tasks/${otherTaskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Trying to hack',
          request_timestamp: new Date().toISOString(),
        })
        .expect(404); // Task not found for this user
    });

    it('should not allow user to delete another user\'s task', async () => {
      await request(apiUrl)
        .delete(`/tasks/${otherTaskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          request_timestamp: new Date().toISOString(),
        })
        .expect(404); // Task not found for this user
    });

    it('should not see other user tasks in list', async () => {
      const res = await request(apiUrl)
        .get('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      // Verify none of the tasks belong to other user
      const hasOtherUserTask = res.body.some((task: any) => task.user_id === otherUserId);
      expect(hasOtherUserTask).toBe(false);
    });
  });

  describe('Invalid Token Scenarios', () => {
    it('should reject with invalid JWT token', () => {
      return request(apiUrl)
        .get('/tasks')
        .set('Authorization', 'Bearer invalid.token.here')
        .expect(401);
    });

    it('should reject with expired or malformed token', () => {
      return request(apiUrl)
        .get('/tasks')
        .set('Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid')
        .expect(401);
    });

    it('should reject with Bearer prefix missing', () => {
      return request(apiUrl)
        .get('/tasks')
        .set('Authorization', authToken) // Without "Bearer "
        .expect(401);
    });
  });

  describe('Large Data Handling', () => {
    it('should handle very long task titles and content', async () => {
      const longTitle = 'A'.repeat(500);
      const longContent = 'B'.repeat(5000);

      const res = await request(apiUrl)
        .post('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: longTitle,
          content: longContent,
          due_date: '2025-12-31',
          request_timestamp: new Date().toISOString(),
        });

      // This might succeed or fail depending on DB constraints
      // If it succeeds, verify data integrity
      if (res.status === 201) {
        expect(res.body.title).toBe(longTitle);
        expect(res.body.content).toBe(longContent);
      }
    });

    it('should handle special characters in task data', async () => {
      const specialChars = {
        title: '!@#$%^&*()_+-=[]{}|;:\'",.<>?/\\`~',
        content: '日本語 中文 한국어 Émojis: 🚀🎉💻',
        due_date: '2025-12-31',
        request_timestamp: new Date().toISOString(),
      };

      const res = await request(apiUrl)
        .post('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send(specialChars)
        .expect(201);

      expect(res.body.title).toBe(specialChars.title);
      expect(res.body.content).toBe(specialChars.content);
    });
  });

  describe('Concurrent Operations', () => {
    it('should handle creating multiple tasks simultaneously', async () => {
      const promises = Array.from({ length: 10 }, (_, i) =>
        request(apiUrl)
          .post('/tasks')
          .set('Authorization', `Bearer ${authToken}`)
          .send({
            title: `Concurrent Task ${i}`,
            content: `Content ${i}`,
            due_date: '2025-12-31',
            request_timestamp: new Date().toISOString(),
          })
      );

      const results = await Promise.all(promises);

      // All should succeed
      results.forEach(res => {
        expect(res.status).toBe(201);
      });

      // All should have unique IDs
      const ids = results.map(res => res.body.id);
      const uniqueIds = new Set(ids);
      expect(uniqueIds.size).toBe(10);
    });
  });

  describe('Non-Existent vs Deleted Tasks - HTTP Status Codes', () => {
    it('should return 404 when trying to GET a task that never existed', async () => {
      const nonExistentId = '00000000-0000-0000-0000-000000000000';

      await request(apiUrl)
        .get(`/tasks/${nonExistentId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });

    it('should return 404 when trying to UPDATE a task that never existed', async () => {
      const nonExistentId = '00000000-0000-0000-0000-000000000000';

      await request(apiUrl)
        .put(`/tasks/${nonExistentId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Trying to update non-existent task',
          request_timestamp: new Date().toISOString(),
        })
        .expect(404);
    });

    it('should return 404 when trying to DELETE a task that never existed', async () => {
      const nonExistentId = '00000000-0000-0000-0000-000000000000';

      await request(apiUrl)
        .delete(`/tasks/${nonExistentId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          request_timestamp: new Date().toISOString(),
        })
        .expect(404);
    });

    it('should return 410 Gone when trying to GET a deleted task (not 404)', async () => {
      // Create a task
      const createRes = await request(apiUrl)
        .post('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Task to delete for 410 test',
          content: 'Content',
          due_date: '2025-12-31',
          request_timestamp: new Date().toISOString(),
        })
        .expect(201);

      const taskId = createRes.body.id;

      // Delete the task
      await request(apiUrl)
        .delete(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          request_timestamp: new Date().toISOString(),
        })
        .expect(200);

      // Try to access the deleted task - should be 410 Gone (not 404)
      await request(apiUrl)
        .get(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(410);
    });

    it('should return 410 Gone when trying to UPDATE a deleted task (not 404)', async () => {
      // Create a task
      const createRes = await request(apiUrl)
        .post('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Task to delete for 410 update test',
          content: 'Content',
          due_date: '2025-12-31',
          request_timestamp: new Date().toISOString(),
        })
        .expect(201);

      const taskId = createRes.body.id;

      // Delete the task
      await request(apiUrl)
        .delete(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          request_timestamp: new Date().toISOString(),
        })
        .expect(200);

      // Try to update the deleted task - should be 410 Gone (not 404)
      await request(apiUrl)
        .put(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Trying to update deleted task',
          request_timestamp: new Date().toISOString(),
        })
        .expect(410);
    });

    it('should return 410 Gone when trying to DELETE an already deleted task (not 404)', async () => {
      // Create a task
      const createRes = await request(apiUrl)
        .post('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Task to delete twice for 410 test',
          content: 'Content',
          due_date: '2025-12-31',
          request_timestamp: new Date().toISOString(),
        })
        .expect(201);

      const taskId = createRes.body.id;

      // Delete the task once
      await request(apiUrl)
        .delete(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          request_timestamp: new Date().toISOString(),
        })
        .expect(200);

      // Try to delete again - should be 410 Gone (not 404)
      await request(apiUrl)
        .delete(`/tasks/${taskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          request_timestamp: new Date().toISOString(),
        })
        .expect(410);
    });
  });
});
