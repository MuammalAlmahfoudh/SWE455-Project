const express = require('express');
const {
  createMatch,
  getMatchById,
} = require('../controllers/matchController');

const router = express.Router();

router.post('/matches', createMatch);
router.get('/matches/:id', getMatchById);

module.exports = router;
