const express = require('express');
require('dotenv').config();

const { runHttpService } = require('./src/config/runHttpService');

const healthRoutes = require('./src/routes/healthRoutes');
const analyticsRoutes = require('./src/routes/analyticsRoutes');
const infoRoutes = require('./src/routes/infoRoutes');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(express.json());

app.use(healthRoutes);
app.use('/', analyticsRoutes);
app.use('/', infoRoutes);

void runHttpService({
  app,
  port: PORT,
  serviceName: 'analytics-service',
});

module.exports = app;
