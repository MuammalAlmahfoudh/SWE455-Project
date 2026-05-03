const matchService = require('../services/matchService');

const sendError = (res, error) => {
  const statusCode = error.statusCode || 500;
  const message = statusCode === 500 ? 'Internal server error' : error.message;

  if (statusCode === 500) {
    console.error(error);
  }

  return res.status(statusCode).json({ message });
};

const createMatch = async (req, res) => {
  try {
    const match = await matchService.createMatch(req.body);
    return res.status(201).json(match);
  } catch (error) {
    return sendError(res, error);
  }
};

const getMatchById = async (req, res) => {
  try {
    const match = await matchService.getMatchById(req.params.id);
    return res.status(200).json(match);
  } catch (error) {
    return sendError(res, error);
  }
};

module.exports = {
  createMatch,
  getMatchById,
};
