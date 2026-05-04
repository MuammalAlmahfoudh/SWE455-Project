const express = require('express');
require('dotenv').config();

const pool = require('./src/config/database');
const { initializeDatabase } = require('./src/config/initDatabase');

const healthRoutes = require('./src/routes/healthRoutes');
const matchRoutes = require('./src/routes/matchRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

let server;
let isShuttingDown = false;

app.use(express.json());

app.use(healthRoutes);
app.use(matchRoutes);
app.use('/', require('./src/routes/setRoutes'));
app.use('/', require('./src/routes/rallyRoutes'));
app.use('/', require('./src/routes/analyticsRoutes'));
app.use('/', require('./src/routes/infoRoutes'));

const closeServer = () => new Promise((resolve, reject) => {
  if (!server) {
    resolve();
    return;
  }

  server.close((error) => {
    if (error) {
      reject(error);
      return;
    }

    resolve();
  });
});

const shutdown = async (signal) => {
  if (isShuttingDown) {
    return;
  }

  isShuttingDown = true;
  console.log(`${signal} received, shutting down gracefully`);

  try {
    await closeServer();
    await pool.end();
    process.exit(0);
  } catch (error) {
    console.error('Graceful shutdown failed', error);
    process.exit(1);
  }
};

const start = async () => {
  await initializeDatabase();
  server = app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
};

process.on('SIGINT', () => {
  void shutdown('SIGINT');
});

process.on('SIGTERM', () => {
  void shutdown('SIGTERM');
});

start().catch((error) => {
  console.error('Failed to start application', error);
  process.exit(1);
});

module.exports = app;
