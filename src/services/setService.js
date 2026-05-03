const matchModel = require('../models/matchModel');
const setModel = require('../models/setModel');

const validateMatchId = (id) => {
  const matchId = Number(id);

  if (!Number.isInteger(matchId) || matchId <= 0) {
    const error = new Error('Match id must be a positive integer');
    error.statusCode = 400;
    throw error;
  }

  return matchId;
};

const validateSetNumber = (setNumber) => {
  const cleanSetNumber = Number(setNumber);

  if (
    !Number.isInteger(cleanSetNumber)
    || cleanSetNumber < 1
    || cleanSetNumber > 5
  ) {
    const error = new Error('setNumber must be an integer between 1 and 5');
    error.statusCode = 400;
    throw error;
  }

  return cleanSetNumber;
};

const ensureMatchExists = async (matchId) => {
  const match = await matchModel.findMatchById(matchId);

  if (!match) {
    const error = new Error('Match not found');
    error.statusCode = 404;
    throw error;
  }
};

const createSet = async (matchIdParam, { setNumber }) => {
  const matchId = validateMatchId(matchIdParam);
  const cleanSetNumber = validateSetNumber(setNumber);

  await ensureMatchExists(matchId);

  const existingSet = await setModel.findSetByMatchIdAndNumber(
    matchId,
    cleanSetNumber
  );

  if (existingSet) {
    const error = new Error('Set number already exists for this match');
    error.statusCode = 409;
    throw error;
  }

  try {
    return await setModel.createSet(matchId, cleanSetNumber);
  } catch (error) {
    if (error.code === '23505') {
      error.message = 'Set number already exists for this match';
      error.statusCode = 409;
    }

    throw error;
  }
};

const getSetsByMatchId = async (matchIdParam) => {
  const matchId = validateMatchId(matchIdParam);

  await ensureMatchExists(matchId);

  return setModel.findSetsByMatchId(matchId);
};

module.exports = {
  createSet,
  getSetsByMatchId,
};
