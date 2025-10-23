import request from 'supertest';
import { TEST_CONFIG, getUserIdFromToken } from './test-config';

describe('Tasks - Normal Operations (e2e)', () => {
  const apiUrl = TEST_CONFIG.apiUrl;
  let authToken: string;
  let userId: string;
  let createdTaskId: string;
  const uniqueId = Date.now();

  const testUser = {
    email: `taskuser${uniqueId}@example.com`,
    username: `taskuser${uniqueId}`,
    password: 'TaskTest123!',
  };

  beforeAll(async () => {
    // Register and login to get auth token
    const registerRes = await request(apiUrl)
      .post('/auth/register')
      .send(testUser);

    authToken = registerRes.body.access_token;
    userId = getUserIdFromToken(authToken);

    console.log('[TASKS TEST] User authenticated successfully');
  });

  describe('/tasks (POST) - Create Task', () => {
    it('should create a new task with valid data', async () => {
      const taskData = {
        title: 'Test Task 1',
        content: 'This is a test task content',
        due_date: '2025-12-31',
        request_timestamp: new Date().toISOString(),
      };

      const res = await request(apiUrl)
        .post('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send(taskData)
        .expect(201);

      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('title', taskData.title);
      expect(res.body).toHaveProperty('content', taskData.content);
      expect(res.body).toHaveProperty('done', false);
      expect(res.body).toHaveProperty('userId', userId);

      createdTaskId = res.body.id;
      console.log(`[TASKS TEST] Created task with ID: ${createdTaskId}`);
    });

    it('should fail to create task with missing required fields', () => {
      return request(apiUrl)
        .post('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Incomplete Task',
          // Missing content, due_date, request_timestamp
        })
        .expect(400);
    });

    it('should fail to create task with invalid date format', () => {
      return request(apiUrl)
        .post('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Invalid Date Task',
          content: 'Content',
          due_date: 'not-a-date',
          request_timestamp: new Date().toISOString(),
        })
        .expect(400);
    });

    it('should create multiple tasks', async () => {
      const tasks = [
        {
          title: 'Task 2',
          content: 'Content 2',
          due_date: '2025-11-30',
          request_timestamp: new Date().toISOString(),
        },
        {
          title: 'Task 3',
          content: 'Content 3',
          due_date: '2025-10-31',
          request_timestamp: new Date().toISOString(),
        },
      ];

      for (const task of tasks) {
        await request(apiUrl)
          .post('/tasks')
          .set('Authorization', `Bearer ${authToken}`)
          .send(task)
          .expect(201);
      }
    });
  });

  describe('/tasks (GET) - Get All Tasks', () => {
    it('should retrieve all tasks for authenticated user', async () => {
      const res = await request(apiUrl)
        .get('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.length).toBeGreaterThanOrEqual(3);

      // All tasks should belong to this user
      res.body.forEach((task: any) => {
        expect(task.userId).toBe(userId);
      });
    });

    it('should work with correlation_id header', () => {
      return request(apiUrl)
        .get('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .set('correlation_id', 'test-correlation-123')
        .expect(200);
    });
  });

  describe('/tasks/:id (GET) - Get Single Task', () => {
    it('should retrieve a specific task by ID', async () => {
      const res = await request(apiUrl)
        .get(`/tasks/${createdTaskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(res.body).toHaveProperty('id', createdTaskId);
      expect(res.body).toHaveProperty('title', 'Test Task 1');
      expect(res.body).toHaveProperty('userId', userId);
    });

    it('should return 404 for non-existent task', () => {
      const fakeId = '123e4567-e89b-12d3-a456-426614174999';
      return request(apiUrl)
        .get(`/tasks/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });

    it('should return error for invalid UUID format', () => {
      return request(apiUrl)
        .get('/tasks/invalid-uuid')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(500); // API returns 500 for invalid UUID (could be improved to 400)
    });
  });

  describe('/tasks/:id (PUT) - Update Task', () => {
    it('should update task title', async () => {
      const updateData = {
        title: 'Updated Task Title',
        request_timestamp: new Date().toISOString(),
      };

      const res = await request(apiUrl)
        .put(`/tasks/${createdTaskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData)
        .expect(200);

      expect(res.body).toHaveProperty('title', updateData.title);
      expect(res.body).toHaveProperty('content', 'This is a test task content'); // Unchanged
    });

    it('should update task status to done', async () => {
      const updateData = {
        done: true,
        request_timestamp: new Date().toISOString(),
      };

      const res = await request(apiUrl)
        .put(`/tasks/${createdTaskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData)
        .expect(200);

      expect(res.body).toHaveProperty('done', true);
    });

    it('should update multiple fields at once', async () => {
      const updateData = {
        title: 'Fully Updated Task',
        content: 'Updated content',
        due_date: '2026-01-15',
        done: false,
        request_timestamp: new Date().toISOString(),
      };

      const res = await request(apiUrl)
        .put(`/tasks/${createdTaskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updateData)
        .expect(200);

      expect(res.body).toHaveProperty('title', updateData.title);
      expect(res.body).toHaveProperty('content', updateData.content);
      expect(res.body).toHaveProperty('done', false);
    });

    it('should fail to update without request_timestamp', () => {
      return request(apiUrl)
        .put(`/tasks/${createdTaskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Should Fail',
        })
        .expect(400);
    });

    it('should return 404 for non-existent task', () => {
      const fakeId = '123e4567-e89b-12d3-a456-426614174999';
      return request(apiUrl)
        .put(`/tasks/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Update Non-existent',
          request_timestamp: new Date().toISOString(),
        })
        .expect(404);
    });
  });

  describe('/tasks/:id (DELETE) - Delete Task', () => {
    let taskToDelete: string;

    beforeAll(async () => {
      // Create a task specifically for deletion
      const res = await request(apiUrl)
        .post('/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          title: 'Task to Delete',
          content: 'This will be deleted',
          due_date: '2025-12-31',
          request_timestamp: new Date().toISOString(),
        });

      taskToDelete = res.body.id;
    });

    it('should delete a task successfully', async () => {
      const res = await request(apiUrl)
        .delete(`/tasks/${taskToDelete}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          request_timestamp: new Date().toISOString(),
        })
        .expect(200);

      expect(res.body).toHaveProperty('message', 'Task deleted successfully');

      // Verify task is actually deleted - should return 410 Gone
      await request(apiUrl)
        .get(`/tasks/${taskToDelete}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(410);
    });

    it('should fail to delete without request_timestamp', () => {
      return request(apiUrl)
        .delete(`/tasks/${createdTaskId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({})
        .expect(400);
    });

    it('should return 404 when deleting non-existent task', () => {
      const fakeId = '123e4567-e89b-12d3-a456-426614174999';
      return request(apiUrl)
        .delete(`/tasks/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          request_timestamp: new Date().toISOString(),
        })
        .expect(404);
    });
  });
});
