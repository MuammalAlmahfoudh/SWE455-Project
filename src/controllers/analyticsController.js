const analyticsService = require('../services/analyticsService');

const sendError = (res, error) => {
  const statusCode = error.statusCode || 500;
  const message = statusCode === 500 ? 'Internal server error' : error.message;

  if (statusCode === 500) {
    console.error(error);
  }

  return res.status(statusCode).json({ message });
};

const getMatchAnalytics = async (req, res) => {
  try {
    const analytics = await analyticsService.getMatchAnalytics(req.params.id);
    return res.status(200).json(analytics);
  } catch (error) {
    return sendError(res, error);
  }
};

module.exports = {
  getMatchAnalytics,
};
