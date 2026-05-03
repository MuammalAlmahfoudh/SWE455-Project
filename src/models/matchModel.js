const pool = require('../config/database');

const createMatch = async (teamA, teamB) => {
  const result = await pool.query(
    'INSERT INTO matches ("teamA", "teamB") VALUES ($1, $2) RETURNING id, "teamA", "teamB", created_at',
    [teamA, teamB]
  );

  return result.rows[0];
};

const findMatchById = async (id) => {
  const result = await pool.query(
    'SELECT id, "teamA", "teamB", created_at FROM matches WHERE id = $1',
    [id]
  );

  return result.rows[0] || null;
};

module.exports = {
  createMatch,
  findMatchById,
};
