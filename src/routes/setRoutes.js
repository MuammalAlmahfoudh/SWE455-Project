const express = require('express');
const {
  createSet,
  getSets,
} = require('../controllers/setController');

const router = express.Router();

router.post('/matches/:id/sets', createSet);
router.get('/matches/:id/sets', getSets);

module.exports = router;
