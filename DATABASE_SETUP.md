# PostgreSQL Setup

## 1. Install and start PostgreSQL

macOS with Homebrew:

```bash
brew install postgresql@16
brew services start postgresql@16
```

Ubuntu/Debian:

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo service postgresql start
```

Windows:

Install PostgreSQL from https://www.postgresql.org/download/windows/ and keep note of the password you set for the `postgres` user.

## 2. Create the database

```bash
createdb volleyball_analytics
```

If `createdb` is not available for your user, run:

```bash
psql -U postgres -c "CREATE DATABASE volleyball_analytics;"
```

## 3. Create the tables

From the project root:

```bash
psql -h localhost -U postgres -d volleyball_analytics -f schema.sql
```

## 4. Configure environment variables

Create a `.env` file in the project root:

```env
PORT=3000
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=password
DB_NAME=volleyball_analytics
DB_PORT=5432
```

Set `DB_PASSWORD` to your local PostgreSQL password. The app reads these variables in `src/config/database.js`.

## 5. Run the app

```bash
npm install
npm start
```

Health check:

```bash
curl http://localhost:3000/health
```
