const setService = require('../services/setService');

const sendError = (res, error) => {
  const statusCode = error.statusCode || 500;
  const message = statusCode === 500 ? 'Internal server error' : error.message;

  if (statusCode === 500) {
    console.error(error);
  }

  return res.status(statusCode).json({ message });
};

const createSet = async (req, res) => {
  try {
    const set = await setService.createSet(req.params.id, req.body);
    return res.status(201).json(set);
  } catch (error) {
    return sendError(res, error);
  }
};

const getSets = async (req, res) => {
  try {
    const sets = await setService.getSetsByMatchId(req.params.id);
    return res.status(200).json(sets);
  } catch (error) {
    return sendError(res, error);
  }
};

module.exports = {
  createSet,
  getSets,
};
