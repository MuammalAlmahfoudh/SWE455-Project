const matchModel = require('../models/matchModel');

const createMatch = async ({ teamA, teamB }) => {
  const cleanTeamA = typeof teamA === 'string' ? teamA.trim() : '';
  const cleanTeamB = typeof teamB === 'string' ? teamB.trim() : '';

  if (!cleanTeamA || !cleanTeamB) {
    const error = new Error('teamA and teamB are required');
    error.statusCode = 400;
    throw error;
  }

  return matchModel.createMatch(cleanTeamA, cleanTeamB);
};

const getMatchById = async (id) => {
  const matchId = Number(id);

  if (!Number.isInteger(matchId) || matchId <= 0) {
    const error = new Error('Match id must be a positive integer');
    error.statusCode = 400;
    throw error;
  }

  const match = await matchModel.findMatchById(matchId);

  if (!match) {
    const error = new Error('Match not found');
    error.statusCode = 404;
    throw error;
  }

  return match;
};

module.exports = {
  createMatch,
  getMatchById,
};
