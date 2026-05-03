const express = require('express');
const { createRally } = require('../controllers/rallyController');

const router = express.Router();

router.post('/rallies', createRally);

module.exports = router;
