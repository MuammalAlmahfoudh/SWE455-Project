# Cloud-Based Volleyball Match Management and Analytics

## Overview

This project is a cloud backend for managing volleyball match data and serving match analytics. It was built for the SWE 455 Cloud Applications Engineering course and focuses on cloud architecture, automation, and runtime design rather than complex business logic.

The system satisfies the core project requirement of:

- two functional services
- one data storage service
- Terraform-provisioned infrastructure
- automated CI/CD deployment

## Final Architecture

The deployed system is split into:

- `Match Service` on `app.js`
- `Analytics Service` on `analytics.js`
- `PostgreSQL` on AWS RDS
- `API Gateway` as the public API entry point
- `EC2` as the Docker host for both backend services

```text
Client / Postman / Browser
           |
           v
   AWS API Gateway
      |        |
      |        |
      v        v
Match Service  Analytics Service
   (EC2/Docker)   (EC2/Docker)
         \        /
          \      /
           v    v
        AWS RDS PostgreSQL
```

## Why The Architecture Is Split

The project is intentionally divided into two backend services:

- The `Match Service` handles operational match management such as creating matches, sets, and rallies.
- The `Analytics Service` handles read-only match analytics queries.

Both services are stateless and use the same RDS PostgreSQL database as a backing service.

## Tech Stack

- Node.js 18+
- Express.js
- PostgreSQL 15
- Docker
- Docker Compose
- AWS API Gateway
- AWS EC2
- AWS RDS PostgreSQL
- Terraform
- GitHub Actions

## Repository Structure

```text
.
├── app.js
├── analytics.js
├── Dockerfile
├── docker-compose.yml
├── main.tf
├── outputs.tf
├── variables.tf
├── schema.sql
├── package.json
└── src
    ├── config
    ├── controllers
    ├── models
    ├── routes
    └── services
```

## Service Responsibilities

### Match Service

The Match Service exposes endpoints for:

- health and runtime info
- match creation
- match lookup
- set creation and retrieval
- rally creation

### Analytics Service

The Analytics Service exposes endpoints for:

- health and runtime info
- match analytics retrieval

## API Surface

### Public API Gateway Routes

Base URL:

```text
https://<api-id>.execute-api.us-east-1.amazonaws.com/prod
```

Routes:

| Method | Route | Service |
| --- | --- | --- |
| `GET` | `/info` | Match Service |
| `GET` | `/health` | Match Service |
| `POST` | `/matches` | Match Service |
| `GET` | `/matches/:id` | Match Service |
| `POST` | `/matches/:id/sets` | Match Service |
| `GET` | `/matches/:id/sets` | Match Service |
| `POST` | `/rallies` | Match Service |
| `GET` | `/matches/:id/analytics` | Analytics Service |
| `GET` | `/analytics/info` | Analytics Service |
| `GET` | `/analytics/health` | Analytics Service |

### Direct EC2 Endpoints

Terraform still exposes direct EC2 service URLs for debugging:

- `direct_match_service_url`
- `direct_analytics_service_url`

These are not the preferred public entry points after API Gateway was added.

## Local Development

### Option 1: Run with Docker Compose

This is the simplest local setup.

```bash
docker-compose up --build
```

This starts:

- Match Service on `localhost:3000`
- Analytics Service on `localhost:3001`
- PostgreSQL on `localhost:5432`

Smoke test:

```bash
curl http://localhost:3000/info
curl http://localhost:3001/info
```

### Option 2: Run Services Manually

Install dependencies:

```bash
npm install
```

Create `.env` from the example:

```bash
cp .env.example .env
```

Create the database and load the schema:

```bash
createdb volleyball_analytics
psql -h localhost -U postgres -d volleyball_analytics -f schema.sql
```

Start the Match Service:

```bash
npm start
```

Start the Analytics Service in a second terminal:

```bash
npm run start:analytics
```

Smoke test:

```bash
curl http://localhost:3000/info
curl http://localhost:3001/info
```

## Environment Variables

Example local configuration:

```env
NODE_ENV=development
PORT=3000
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=password
DB_NAME=volleyball_analytics
DB_PORT=5432
DB_SSL=false
DB_SSL_REJECT_UNAUTHORIZED=true
```

In AWS, Terraform passes production values to both containers through EC2 `user_data`.

## Cloud Deployment

Terraform provisions the cloud stack defined in `main.tf`:

- VPC
- two public subnets
- internet gateway
- route table and associations
- EC2 security group
- RDS security group
- RDS PostgreSQL
- EC2 Docker host
- API Gateway REST API

### Terraform Commands

Initialize:

```bash
terraform init
```

Provide the database password:

```bash
export TF_VAR_db_password="CHANGE_ME_TO_A_STRONG_PASSWORD"
```

Plan:

```bash
terraform plan -var="container_image=<dockerhub-username>/volleyball-api:latest"
```

Apply:

```bash
terraform apply -var="container_image=<dockerhub-username>/volleyball-api:latest"
```

Useful outputs:

```bash
terraform output api_gateway_url
terraform output direct_match_service_url
terraform output direct_analytics_service_url
terraform output db_endpoint
```

## CI/CD

GitHub Actions is used for automated deployment.

On each push to `main`, the workflow:

- checks out the repository
- installs Node.js dependencies
- runs JavaScript syntax checks
- builds a Linux AMD64 Docker image
- pushes the image to Docker Hub
- imports existing AWS resources into Terraform state for the ephemeral runner
- runs `terraform apply`

Workflow file:

- `.github/workflows/deploy.yml`

### Required GitHub Secrets

- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `DB_PASSWORD`

### Required GitHub Variable

- `ENABLE_TERRAFORM_DEPLOY=true`

### AWS Permission Note

The IAM user used by GitHub Actions must have enough permission to manage:

- EC2
- RDS
- VPC networking
- API Gateway

## Example Requests

### Through API Gateway

```bash
BASE="https://<api-id>.execute-api.us-east-1.amazonaws.com/prod"
```

Health and info:

```bash
curl -i "$BASE/info"
curl -i "$BASE/analytics/info"
```

Create a match:

```bash
curl -i -X POST "$BASE/matches" \
  -H "Content-Type: application/json" \
  -d '{"teamA":"Team A","teamB":"Team B"}'
```

Create a set:

```bash
curl -i -X POST "$BASE/matches/1/sets" \
  -H "Content-Type: application/json" \
  -d '{"setNumber":1}'
```

Create a rally:

```bash
curl -i -X POST "$BASE/rallies" \
  -H "Content-Type: application/json" \
  -d '{"matchId":1,"setNumber":1,"winner":"A","type":"SPIKE"}'
```

Get analytics:

```bash
curl -i "$BASE/matches/1/analytics"
```

## Notes For Demo

- Use API Gateway routes in the demo, not the raw EC2 ports.
- Opening only the API Gateway base path `/prod` returns `{"message":"Missing Authentication Token"}` because the gateway does not define a root `/` route.
- Use `/prod/info` or `/prod/analytics/info` instead.
- After `terraform apply`, EC2 may take a short time to finish `user_data` before the services become reachable.

## Project Summary

This project demonstrates a cloud-native backend architecture with:

- API Gateway as the public API layer
- two functional backend services
- one shared managed PostgreSQL database
- Terraform-managed AWS infrastructure
- Dockerized service deployment on EC2
- automated CI/CD through GitHub Actions

It is designed to be easy to explain in a live demo while still covering the core cloud engineering concepts required by the course.
