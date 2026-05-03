const rallyModel = require('../models/rallyModel');

const VALID_WINNERS = ['A', 'B'];
const VALID_TYPES = ['SPIKE', 'BLOCK', 'ACE', 'ERROR'];

const validatePositiveInteger = (value, fieldName) => {
  const number = Number(value);

  if (!Number.isInteger(number) || number <= 0) {
    const error = new Error(`${fieldName} must be a positive integer`);
    error.statusCode = 400;
    throw error;
  }

  return number;
};

const validateSetNumber = (value) => {
  const setNumber = Number(value);

  if (!Number.isInteger(setNumber) || setNumber < 1 || setNumber > 5) {
    const error = new Error('setNumber must be an integer between 1 and 5');
    error.statusCode = 400;
    throw error;
  }

  return setNumber;
};

const validateWinner = (value) => {
  const winner = typeof value === 'string' ? value.trim().toUpperCase() : '';

  if (!VALID_WINNERS.includes(winner)) {
    const error = new Error('winner must be A or B');
    error.statusCode = 400;
    throw error;
  }

  return winner;
};

const validateType = (value) => {
  const type = typeof value === 'string' ? value.trim().toUpperCase() : '';

  if (!VALID_TYPES.includes(type)) {
    const error = new Error('type must be one of SPIKE, BLOCK, ACE, ERROR');
    error.statusCode = 400;
    throw error;
  }

  return type;
};

const createRally = async ({ matchId, setNumber, winner, type }) => {
  const cleanMatchId = validatePositiveInteger(matchId, 'matchId');
  const cleanSetNumber = validateSetNumber(setNumber);
  const cleanWinner = validateWinner(winner);
  const cleanType = validateType(type);

  const result = await rallyModel.createRallyAndUpdateScore({
    matchId: cleanMatchId,
    setNumber: cleanSetNumber,
    winner: cleanWinner,
    type: cleanType,
  });

  if (!result) {
    const error = new Error('Set not found');
    error.statusCode = 404;
    throw error;
  }

  return result;
};

module.exports = {
  createRally,
};
