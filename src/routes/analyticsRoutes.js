const express = require('express');
const { getMatchAnalytics } = require('../controllers/analyticsController');

const router = express.Router();

router.get('/matches/:id/analytics', getMatchAnalytics);

module.exports = router;
