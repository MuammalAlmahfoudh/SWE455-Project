const rallyService = require('../services/rallyService');

const sendError = (res, error) => {
  const statusCode = error.statusCode || 500;
  const message = statusCode === 500 ? 'Internal server error' : error.message;

  if (statusCode === 500) {
    console.error(error);
  }

  return res.status(statusCode).json({ message });
};

const createRally = async (req, res) => {
  try {
    const result = await rallyService.createRally(req.body);
    return res.status(201).json(result);
  } catch (error) {
    return sendError(res, error);
  }
};

module.exports = {
  createRally,
};
