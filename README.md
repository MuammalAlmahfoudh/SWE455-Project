# Cloud-Based Volleyball Match and Set Analytics API

## Project Description

This project is a Node.js and Express.js backend architecture for managing volleyball matches, sets, rallies, and match analytics. It is split into two functional services backed by PostgreSQL and supports deployment using Docker, Docker Compose, Terraform, AWS EC2, and AWS RDS.

The system was built for a SWE 455 Cloud Applications Engineering project and follows a clean backend structure with routes, controllers, services, models, and configuration files.

## Architecture Overview

```text
Client / Postman
      |
      | HTTP requests
      v
Internet Gateway
      |
      | Ports 3000 and 3001
      v
AWS EC2 Instance
      |
      | Docker containers running Match Service and Analytics Service
      v
AWS RDS PostgreSQL
```

The Match Service runs on port 3000 and handles match, set, and rally writes. The Analytics Service runs on port 3001 and serves analytics queries. PostgreSQL runs as an external database service using AWS RDS. Both services are stateless, and all persistent data is stored in PostgreSQL.

## Tech Stack

- Node.js
- Express.js
- PostgreSQL
- Docker
- Docker Compose
- AWS EC2
- AWS RDS PostgreSQL
- Terraform
- GitHub Actions

## CI/CD

GitHub Actions workflow:

- Installs dependencies
- Runs JavaScript syntax checks
- Builds Docker image
- Pushes Docker image to Docker Hub
- Optionally runs Terraform deployment when `ENABLE_TERRAFORM_DEPLOY` repository variable is set to `true`

Required GitHub secrets for Docker publishing:

- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`

Additional GitHub secrets for Terraform deployment:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `DB_PASSWORD`

## Project Structure

```text
.
├── app.js
├── analytics.js
├── package.json
├── schema.sql
├── Dockerfile
├── docker-compose.yml
├── main.tf
├── variables.tf
├── outputs.tf
└── src
    ├── config
    ├── controllers
    ├── models
    ├── routes
    └── services
```

## Run Locally

Install dependencies:

```bash
npm install
```

Create a `.env` file:

```env
PORT=3000
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=password
DB_NAME=volleyball_analytics
DB_PORT=5432
```

Create the PostgreSQL database and tables:

```bash
createdb volleyball_analytics
psql -h localhost -U postgres -d volleyball_analytics -f schema.sql
```

Start the match service:

```bash
npm start
```

Start the analytics service in a second terminal:

```bash
npm run start:analytics
```

Test:

```bash
curl http://localhost:3000/info
curl http://localhost:3001/info
```

## Run With Docker

Build the Docker image:

```bash
docker build -t volleyball-api .
```

Run the match service container:

```bash
docker run -p 3000:3000 \
  -e SERVICE_LABEL="Volleyball Match Service running" \
  -e DB_HOST=host.docker.internal \
  -e DB_USER=postgres \
  -e DB_PASSWORD=password \
  -e DB_NAME=volleyball_analytics \
  -e DB_PORT=5432 \
  volleyball-api
```

Run the analytics service container:

```bash
docker run -p 3001:3001 \
  -e SERVICE_LABEL="Volleyball Analytics Service running" \
  -e PORT=3001 \
  -e DB_HOST=host.docker.internal \
  -e DB_USER=postgres \
  -e DB_PASSWORD=password \
  -e DB_NAME=volleyball_analytics \
  -e DB_PORT=5432 \
  volleyball-api npm run start:analytics
```

Run both services and PostgreSQL together with Docker Compose:

```bash
docker-compose up --build
```

Test:

```bash
curl http://localhost:3000/info
curl http://localhost:3001/info
```

## Deploy With Terraform

Terraform creates:

- VPC
- Public subnets
- Internet gateway
- Security groups
- EC2 instance running both Docker service containers
- RDS PostgreSQL instance

Initialize Terraform:

```bash
terraform init
```

Set a database password outside source control:

```bash
export TF_VAR_db_password="CHANGE_ME_TO_A_STRONG_PASSWORD"
```

Plan deployment:

```bash
terraform plan \
  -var="container_image=muammalzuhair/volleyball-api:latest"
```

Apply deployment:

```bash
terraform apply \
  -var="container_image=muammalzuhair/volleyball-api:latest"
```

Get the service URLs:

```bash
terraform output app_url
terraform output analytics_url
```

Test cloud deployment:

```bash
curl http://<EC2_PUBLIC_IP>:3000/info
curl http://<EC2_PUBLIC_IP>:3001/info
```

## API Endpoints Summary

| Method | Endpoint | Description |
| --- | --- | --- |
| `GET` | `http://<host>:3000/health` | Match service health check. |
| `GET` | `http://<host>:3000/info` | Match service runtime information. |
| `POST` | `http://<host>:3000/matches` | Creates a new volleyball match. |
| `GET` | `http://<host>:3000/matches/:id` | Returns match details by ID. |
| `POST` | `http://<host>:3000/matches/:id/sets` | Creates a set for a match. |
| `GET` | `http://<host>:3000/matches/:id/sets` | Returns all sets for a match. |
| `POST` | `http://<host>:3000/rallies` | Creates a rally and updates the set score. |
| `GET` | `http://<host>:3001/health` | Analytics service health check. |
| `GET` | `http://<host>:3001/info` | Analytics service runtime information. |
| `GET` | `http://<host>:3001/matches/:id/analytics` | Returns match analytics computed from rallies. |

## Example Requests

Create match:

```bash
curl -X POST http://localhost:3000/matches \
  -H "Content-Type: application/json" \
  -d '{"teamA":"Team A","teamB":"Team B"}'
```

Create set:

```bash
curl -X POST http://localhost:3000/matches/1/sets \
  -H "Content-Type: application/json" \
  -d '{"setNumber":1}'
```

Create rally:

```bash
curl -X POST http://localhost:3000/rallies \
  -H "Content-Type: application/json" \
  -d '{"matchId":1,"setNumber":1,"winner":"A","type":"SPIKE"}'
```

Get analytics:

```bash
curl http://localhost:3001/matches/1/analytics
```
