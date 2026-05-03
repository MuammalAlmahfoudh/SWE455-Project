const express = require('express');
require('dotenv').config();

require('./src/config/database');

const healthRoutes = require('./src/routes/healthRoutes');
const matchRoutes = require('./src/routes/matchRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.use(healthRoutes);
app.use(matchRoutes);
app.use('/', require('./src/routes/setRoutes'));
app.use('/', require('./src/routes/rallyRoutes'));
app.use('/', require('./src/routes/analyticsRoutes'));
app.use('/', require('./src/routes/infoRoutes'));

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

module.exports = app;
