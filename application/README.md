# Task Manager API

A production-ready Task Manager REST API built with NestJS, PostgreSQL, and deployed on Kubernetes.

## Features

✅ **RESTful CRUD API** - Full task management with title, content, due_date, and done fields
✅ **JWT Authentication** - Secure Bearer token authentication
✅ **Request Timestamp Handling** - Handles out-of-order requests using request_timestamp
✅ **Correlation ID Tracing** - Request tracing for debugging
✅ **Rate Limiting** - Throttling to prevent abuse (429 Too Many Requests)
✅ **Security Best Practices** - Helmet, CORS, input validation, non-root user
✅ **Horizontal Scaling** - Stateless design with 3+ replicas
✅ **PostgreSQL Database** - Managed SQL database with TypeORM
✅ **HTTPS/TLS** - Secure protocols via Ingress
✅ **Health Checks** - Liveness and readiness probes
✅ **Kubernetes Deployment** - Helm chart with HPA, PDB, and anti-affinity

## Quick Start

See full documentation below for local development, Docker, and Kubernetes deployment.

## API Endpoints

All endpoints are prefixed with `/api/v1`

### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login and get JWT token

### Tasks (Requires Authentication)
- `POST /tasks` - Create task (201)
- `GET /tasks` - List all tasks (200)
- `GET /tasks/{id}` - Get specific task (200)
- `PUT /tasks/{id}` - Update task (200)
- `DELETE /tasks/{id}` - Delete task (200)

For detailed API documentation, see sections below.
  <!--[![Backers on Open Collective](https://opencollective.com/nest/backers/badge.svg)](https://opencollective.com/nest#backer)
  [![Sponsors on Open Collective](https://opencollective.com/nest/sponsors/badge.svg)](https://opencollective.com/nest#sponsor)-->

## Description

[Nest](https://github.com/nestjs/nest) framework TypeScript starter repository.

## Project setup

```bash
$ npm install
```

## Compile and run the project

```bash
# development
$ npm run start

# watch mode
$ npm run start:dev

# production mode
$ npm run start:prod
```

## Run tests

```bash
# unit tests
$ npm run test

# e2e tests (manual - requires running API)
$ npm run test:e2e

# e2e tests with custom URL
$ npm run test:e2e -- --url http://localhost:3000

# test coverage
$ npm run test:cov
```

### Comprehensive E2E Testing

The project includes a complete end-to-end test suite covering:
- ✅ Unauthenticated access (401 responses)
- ✅ Authentication (register, login, validation)
- ✅ All CRUD operations on tasks
- ✅ Edge cases (race conditions, user isolation)
- ✅ Load testing (500 concurrent requests)

**Run tests with Docker (Recommended):**

```bash
# Linux/Mac - starts Docker, runs tests, cleans up
./run-e2e-tests.sh

# Windows
run-e2e-tests.bat

# With custom URL
./run-e2e-tests.sh --url http://localhost:5000
```

The scripts automatically:
1. Start Docker Compose services
2. Wait for API health check
3. Run all e2e tests
4. Clean up Docker resources

📚 See `test/README.md` for detailed testing documentation.

## Deployment

When you're ready to deploy your NestJS application to production, there are some key steps you can take to ensure it runs as efficiently as possible. Check out the [deployment documentation](https://docs.nestjs.com/deployment) for more information.

If you are looking for a cloud-based platform to deploy your NestJS application, check out [Mau](https://mau.nestjs.com), our official platform for deploying NestJS applications on AWS. Mau makes deployment straightforward and fast, requiring just a few simple steps:

```bash
$ npm install -g @nestjs/mau
$ mau deploy
```

With Mau, you can deploy your application in just a few clicks, allowing you to focus on building features rather than managing infrastructure.

## Resources

Check out a few resources that may come in handy when working with NestJS:

- Visit the [NestJS Documentation](https://docs.nestjs.com) to learn more about the framework.
- For questions and support, please visit our [Discord channel](https://discord.gg/G7Qnnhy).
- To dive deeper and get more hands-on experience, check out our official video [courses](https://courses.nestjs.com/).
- Deploy your application to AWS with the help of [NestJS Mau](https://mau.nestjs.com) in just a few clicks.
- Visualize your application graph and interact with the NestJS application in real-time using [NestJS Devtools](https://devtools.nestjs.com).
- Need help with your project (part-time to full-time)? Check out our official [enterprise support](https://enterprise.nestjs.com).
- To stay in the loop and get updates, follow us on [X](https://x.com/nestframework) and [LinkedIn](https://linkedin.com/company/nestjs).
- Looking for a job, or have a job to offer? Check out our official [Jobs board](https://jobs.nestjs.com).

## Support

Nest is an MIT-licensed open source project. It can grow thanks to the sponsors and support by the amazing backers. If you'd like to join them, please [read more here](https://docs.nestjs.com/support).

## Stay in touch

- Author - [Kamil Myśliwiec](https://twitter.com/kammysliwiec)
- Website - [https://nestjs.com](https://nestjs.com/)
- Twitter - [@nestframework](https://twitter.com/nestframework)

## License

Nest is [MIT licensed](https://github.com/nestjs/nest/blob/master/LICENSE).
