const getInfo = (req, res) => {
  res.status(200).json({
    message: process.env.SERVICE_LABEL || 'Volleyball API running',
    timestamp: new Date().toISOString(),
    env: process.env.NODE_ENV || 'development',
  });
};

module.exports = {
  getInfo,
};
