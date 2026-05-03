# Cloud-Based Volleyball Match and Set Analytics API

## Project Description

This project is a Node.js and Express.js backend API for managing volleyball matches, sets, rallies, and match analytics. It stores match data in PostgreSQL and supports deployment using Docker, Docker Compose, Terraform, AWS EC2, and AWS RDS.

The system was built for a SWE 455 Cloud Applications Engineering project and follows a clean backend structure with routes, controllers, services, models, and configuration files.

## Architecture Overview

```text
Client / Postman
      |
      | HTTP requests
      v
Internet Gateway
      |
      | Port 3000
      v
AWS EC2 Instance
      |
      | Docker container running Node.js Express API
      v
AWS RDS PostgreSQL
```

The Express API runs inside a Docker container on EC2. PostgreSQL runs as an external database service using AWS RDS. The backend is stateless, and all persistent match, set, rally, and analytics data is stored in PostgreSQL.

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
- `EC2_KEY_NAME`
- `DB_PASSWORD`

## Project Structure

```text
.
├── app.js
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

Start the server:

```bash
npm start
```

Test:

```bash
curl http://localhost:3000/info
```

## Run With Docker

Build the Docker image:

```bash
docker build -t volleyball-api .
```

Run the API container:

```bash
docker run -p 3000:3000 \
  -e DB_HOST=host.docker.internal \
  -e DB_USER=postgres \
  -e DB_PASSWORD=password \
  -e DB_NAME=volleyball_analytics \
  -e DB_PORT=5432 \
  volleyball-api
```

Run API and PostgreSQL together with Docker Compose:

```bash
docker-compose up --build
```

Test:

```bash
curl http://localhost:3000/info
```

## Deploy With Terraform

Terraform creates:

- VPC
- Public subnets
- Internet gateway
- Security groups
- EC2 instance running the Docker container
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
  -var="container_image=muammalzuhair/volleyball-api:latest" \
  -var="ec2_key_name=YOUR_AWS_KEY_PAIR_NAME"
```

Apply deployment:

```bash
terraform apply \
  -var="container_image=muammalzuhair/volleyball-api:latest" \
  -var="ec2_key_name=YOUR_AWS_KEY_PAIR_NAME"
```

Get the application URL:

```bash
terraform output app_url
```

Test cloud deployment:

```bash
curl http://<EC2_PUBLIC_IP>:3000/info
```

SSH into EC2:

```bash
ssh -i /path/to/key.pem ec2-user@<EC2_PUBLIC_IP>
```

Check deployment logs on EC2:

```bash
cat /home/ec2-user/debug.log
```

## API Endpoints Summary

| Method | Endpoint | Description |
| --- | --- | --- |
| `GET` | `/health` | Health check endpoint. |
| `GET` | `/info` | Returns API runtime information for deployment verification. |
| `POST` | `/matches` | Creates a new volleyball match. |
| `GET` | `/matches/:id` | Returns match details by ID. |
| `POST` | `/matches/:id/sets` | Creates a set for a match. |
| `GET` | `/matches/:id/sets` | Returns all sets for a match. |
| `POST` | `/rallies` | Creates a rally and updates the set score. |
| `GET` | `/matches/:id/analytics` | Returns match analytics computed from rallies. |

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
curl http://localhost:3000/matches/1/analytics
```
