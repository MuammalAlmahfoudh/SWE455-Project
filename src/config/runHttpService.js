const pool = require('./database');
const { initializeDatabase } = require('./initDatabase');

const runHttpService = async ({ app, port, serviceName }) => {
  let server;
  let isShuttingDown = false;

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
    console.log(`${serviceName} received ${signal}, shutting down gracefully`);

    try {
      await closeServer();
      await pool.end();
      process.exit(0);
    } catch (error) {
      console.error(`${serviceName} failed during shutdown`, error);
      process.exit(1);
    }
  };

  process.on('SIGINT', () => {
    void shutdown('SIGINT');
  });

  process.on('SIGTERM', () => {
    void shutdown('SIGTERM');
  });

  try {
    await initializeDatabase();
    server = app.listen(port, () => {
      console.log(`${serviceName} is running on port ${port}`);
    });
  } catch (error) {
    console.error(`${serviceName} failed to start`, error);
    process.exit(1);
  }
};

module.exports = {
  runHttpService,
};
