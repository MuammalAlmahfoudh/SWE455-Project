const analyticsModel = require('../models/analyticsModel');
const matchModel = require('../models/matchModel');

const RALLY_TYPES = ['SPIKE', 'BLOCK', 'ACE', 'ERROR'];

const createTeamAnalytics = () => RALLY_TYPES.reduce((analytics, type) => {
  analytics[type] = 0;
  return analytics;
}, { points: 0 });

const validateMatchId = (id) => {
  const matchId = Number(id);

  if (!Number.isInteger(matchId) || matchId <= 0) {
    const error = new Error('Match id must be a positive integer');
    error.statusCode = 400;
    throw error;
  }

  return matchId;
};

const getMatchAnalytics = async (id) => {
  const matchId = validateMatchId(id);
  const match = await matchModel.findMatchById(matchId);

  if (!match) {
    const error = new Error('Match not found');
    error.statusCode = 404;
    throw error;
  }

  const [sets, rallyTypeCounts] = await Promise.all([
    analyticsModel.getSetScoresByMatchId(matchId),
    analyticsModel.getRallyTypeCountsByMatchId(matchId),
  ]);

  const teamA = createTeamAnalytics();
  const teamB = createTeamAnalytics();

  sets.forEach((set) => {
    teamA.points += set.teamA_score;
    teamB.points += set.teamB_score;
  });

  rallyTypeCounts.forEach(({ winner, type, count }) => {
    const team = winner === 'A' ? teamA : teamB;
    team[type] = count;
  });

  return {
    sets,
    teamA,
    teamB,
  };
};

module.exports = {
  getMatchAnalytics,
};
