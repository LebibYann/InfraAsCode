import request from 'supertest';
import { TEST_CONFIG } from './test-config';

describe('Authentication (e2e)', () => {
  const apiUrl = TEST_CONFIG.apiUrl;
  const uniqueId = Date.now();
  const testUser = {
    email: `testuser${uniqueId}@example.com`,
    username: `testuser${uniqueId}`,
    password: 'Test123456!',
  };

  describe('/auth/register (POST)', () => {
    it('should successfully register a new user', () => {
      return request(apiUrl)
        .post('/auth/register')
        .send(testUser)
        .expect(201)
        .expect((res) => {
          expect(res.body).toHaveProperty('access_token');
          expect(typeof res.body.access_token).toBe('string');
        });
    });

    it('should fail to register with duplicate email', () => {
      return request(apiUrl)
        .post('/auth/register')
        .send(testUser)
        .expect(409); // Conflict
    });

    it('should fail to register with invalid email', () => {
      return request(apiUrl)
        .post('/auth/register')
        .send({
          email: 'invalid-email',
          username: 'testuser',
          password: 'Test123456!',
        })
        .expect(400);
    });

    it('should fail to register with short password', () => {
      return request(apiUrl)
        .post('/auth/register')
        .send({
          email: `short${uniqueId}@example.com`,
          username: `shortpass${uniqueId}`,
          password: '12345', // Less than 6 characters
        })
        .expect(400);
    });

    it('should fail to register with missing fields', () => {
      return request(apiUrl)
        .post('/auth/register')
        .send({
          email: `missing${uniqueId}@example.com`,
          // Missing username and password
        })
        .expect(400);
    });
  });

  describe('/auth/login (POST)', () => {
    it('should successfully login with valid credentials', () => {
      return request(apiUrl)
        .post('/auth/login')
        .send({
          email: testUser.email,
          password: testUser.password,
        })
        .expect(200)
        .expect((res) => {
          expect(res.body).toHaveProperty('access_token');
          expect(typeof res.body.access_token).toBe('string');
        });
    });

    it('should fail to login with wrong password', () => {
      return request(apiUrl)
        .post('/auth/login')
        .send({
          email: testUser.email,
          password: 'WrongPassword123!',
        })
        .expect(401);
    });

    it('should fail to login with non-existent email', () => {
      return request(apiUrl)
        .post('/auth/login')
        .send({
          email: `nonexistent${uniqueId}@example.com`,
          password: 'Test123456!',
        })
        .expect(401);
    });

    it('should fail to login with invalid email format', () => {
      return request(apiUrl)
        .post('/auth/login')
        .send({
          email: 'invalid-email',
          password: 'Test123456!',
        })
        .expect(400);
    });

    it('should fail to login with missing fields', () => {
      return request(apiUrl)
        .post('/auth/login')
        .send({
          email: testUser.email,
          // Missing password
        })
        .expect(400);
    });
  });
});
