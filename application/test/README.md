# E2E Test Suite for Task Manager API

This directory contains comprehensive end-to-end tests for the Task Manager API.

## 📁 Test Files

### Core Test Suites

1. **`app.e2e-spec.ts`** - Basic smoke tests
   - Root endpoint test
   - Health check test

2. **`unauthenticated.e2e-spec.ts`** - Unauthenticated access tests
   - Verifies protected endpoints return 401
   - Tests public endpoints (health, root)

3. **`auth.e2e-spec.ts`** - Authentication tests
   - User registration (valid/invalid cases)
   - User login (valid/invalid credentials)
   - Duplicate email handling
   - Validation tests

4. **`tasks.e2e-spec.ts`** - Task CRUD operations
   - Create tasks with valid/invalid data
   - Read all tasks
   - Read single task
   - Update tasks (partial/full updates)
   - Delete tasks
   - UUID validation

5. **`edge-cases.e2e-spec.ts`** - Edge cases and security
   - Disorganized operations (delete then update)
   - Multiple rapid updates
   - User isolation (security tests)
   - Invalid token scenarios
   - Large data handling
   - Special characters
   - Concurrent operations

6. **`load-test.e2e-spec.ts`** - Load testing (DDOS simulation)
   - Concurrent requests to health endpoint (default: 500, configurable)
   - Concurrent login requests
   - Concurrent task creation requests
   - Concurrent task retrieval requests
   - Mixed operations (CREATE, READ, UPDATE, DELETE)
   - Rapid-fire stress test
   - **Configurable concurrency via `TEST_CONCURRENCY` environment variable or `--concurrency` script parameter**

### Configuration

- **`test-config.ts`** - Test configuration helper
  - Reads `TEST_API_URL` environment variable for custom API URLs
  - Reads `TEST_CONCURRENCY` environment variable for load test intensity
  - Provides defaults: URL = http://localhost:3000/api/v1, Concurrency = 500
  - JWT token decoding utility for extracting user IDs
  - Configurable timeouts

- **`jest-e2e.json`** - Jest configuration for e2e tests
  - 30 second default timeout
  - Verbose output enabled
  - Single worker (sequential execution)

## 🚀 Running Tests

### Option 1: Using the Scripts (Recommended)

The easiest way to run tests is using the provided scripts that handle Docker setup and teardown:

#### Linux/Mac:
```bash
# Make script executable (first time only)
chmod +x run-e2e-tests.sh

# Run tests with defaults (URL: http://localhost:3000, Concurrency: 500)
./run-e2e-tests.sh

# Run tests with custom URL
./run-e2e-tests.sh --url http://localhost:5000

# Run tests with custom concurrency (for load tests)
./run-e2e-tests.sh --concurrency 1000

# Run with both custom parameters
./run-e2e-tests.sh --url http://localhost:5000 --concurrency 1000
```

#### Windows:
```cmd
REM Run tests with defaults (URL: http://localhost:3000, Concurrency: 500)
run-e2e-tests.bat

REM Run tests with custom URL
run-e2e-tests.bat --url http://localhost:5000

REM Run tests with custom concurrency (for load tests)
run-e2e-tests.bat --concurrency 1000

REM Run with both custom parameters
run-e2e-tests.bat --url http://localhost:5000 --concurrency 1000
```

**What the scripts do:**
1. Start Docker Compose services
2. Wait for API to be healthy (up to 30 attempts)
3. Run all e2e tests
4. Clean up Docker Compose services (even if tests fail)

### Option 2: Manual Test Execution

If you already have the API running:

```bash
# Run all e2e tests with defaults
npm run test:e2e

# Run tests with custom concurrency for load tests (Linux/Mac)
TEST_CONCURRENCY=1000 npm run test:e2e

# Run tests with custom concurrency (Windows PowerShell)
$env:TEST_CONCURRENCY=1000; npm run test:e2e

# Run tests with custom concurrency (Windows CMD)
set TEST_CONCURRENCY=1000 && npm run test:e2e

# Run with extra verbose output
npm run test:e2e:verbose
```

### Option 3: Run Specific Test Files

```bash
# Run only authentication tests
npm run test:e2e -- --testPathPattern=auth.e2e-spec

# Run only load tests
npm run test:e2e -- --testPathPattern=load-test.e2e-spec

# Run all except load tests
npm run test:e2e -- --testPathIgnorePatterns=load-test
```

## 📊 Test Coverage

### Endpoints Tested

| Endpoint | Method | Auth Required | Tests |
|----------|--------|---------------|-------|
| `/` | GET | No | ✅ Basic response |
| `/health` | GET | No | ✅ Health check, load test |
| `/auth/register` | POST | No | ✅ Valid/invalid data, duplicates |
| `/auth/login` | POST | No | ✅ Valid/invalid credentials |
| `/tasks` | POST | Yes | ✅ Create with valid/invalid data |
| `/tasks` | GET | Yes | ✅ List all tasks, user isolation |
| `/tasks/:id` | GET | Yes | ✅ Get single task, 404 handling |
| `/tasks/:id` | PUT | Yes | ✅ Update task, validation |
| `/tasks/:id` | DELETE | Yes | ✅ Delete task, 404 handling |

### Test Scenarios

- ✅ Happy path operations
- ✅ Validation errors (400)
- ✅ Authentication failures (401)
- ✅ Authorization failures (403)
- ✅ Resource not found (404)
- ✅ Duplicate resources (409)
- ✅ User data isolation
- ✅ Invalid tokens
- ✅ Malformed requests
- ✅ Edge cases (delete then update, etc.)
- ✅ Concurrent operations
- ✅ Load testing (500 concurrent requests)
- ✅ Special characters and large data

## 🔧 Configuration Options

### Environment Variables

- `TEST_API_URL` - Default API URL (default: `http://localhost:3000`)

### Command Line Arguments

- `--url <url>` - Specify custom API URL for tests

### Jest Options

- `--verbose` - Extra verbose output
- `--testPathPattern=<pattern>` - Run specific test files
- `--testPathIgnorePatterns=<pattern>` - Exclude test files
- `--maxWorkers=<n>` - Control parallelization (default: 1 for e2e)

## 📝 Test Execution Order

Tests are designed to run in this order:

1. **app.e2e-spec.ts** - Quick smoke test
2. **unauthenticated.e2e-spec.ts** - Verify authentication is required
3. **auth.e2e-spec.ts** - Test user registration and login
4. **tasks.e2e-spec.ts** - Test normal task operations
5. **edge-cases.e2e-spec.ts** - Test edge cases and security
6. **load-test.e2e-spec.ts** - Heavy load testing (runs last)

The load tests are intentionally last because they stress the API with 500 concurrent requests.

## 🐛 Troubleshooting

### Tests fail with connection errors

**Problem:** Cannot connect to API
**Solution:** Ensure Docker Compose is running and API is healthy
```bash
docker-compose ps
curl http://localhost:3000/health
```

### Load tests timeout

**Problem:** Load tests take too long or timeout
**Solution:**
- Increase Jest timeout in `jest-e2e.json`
- Reduce `CONCURRENT_REQUESTS` in `load-test.e2e-spec.ts`
- Check system resources (CPU, memory)

### Tests pass locally but fail in CI

**Problem:** Timing issues in CI environment
**Solution:**
- Increase `MAX_HEALTH_CHECKS` in test scripts
- Add retry logic for flaky tests
- Check CI resource constraints

### Port already in use

**Problem:** Port 3000 or 5432 already in use
**Solution:**
```bash
# Stop existing services
docker-compose down

# Or use custom port
docker-compose up -d
# Then run tests with custom URL
./run-e2e-tests.sh --url http://localhost:<custom-port>
```

## 📈 Performance Expectations

Based on load tests with 500 concurrent requests:

- **Health endpoint:** 95%+ success rate
- **Authentication:** 90%+ success rate
- **Task CRUD:** 90%+ success rate
- **Mixed operations:** 85%+ success rate

Lower success rates in mixed operations are expected due to intentional race conditions (e.g., deleting a task that another request is trying to update).

## 🔒 Security Testing

The test suite includes security-focused tests:

- User data isolation (users cannot access each other's tasks)
- Invalid JWT token rejection
- Expired token handling
- Authorization checks on all protected endpoints

## 💡 Tips

1. **Run load tests separately** if they're too slow:
   ```bash
   npm run test:e2e -- --testPathIgnorePatterns=load-test
   ```

2. **Debug a specific test:**
   ```bash
   npm run test:e2e -- --testNamePattern="should create a new task"
   ```

3. **Watch test output in real-time:**
   ```bash
   npm run test:e2e:verbose
   ```

4. **Check Docker logs** if tests fail:
   ```bash
   docker-compose logs app
   docker-compose logs postgres
   ```

## 📚 Additional Resources

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Supertest Documentation](https://github.com/visionmedia/supertest)
- [NestJS Testing Documentation](https://docs.nestjs.com/fundamentals/testing)
