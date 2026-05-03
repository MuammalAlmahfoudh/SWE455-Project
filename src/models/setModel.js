const pool = require('../config/database');

const createSet = async (matchId, setNumber) => {
  const result = await pool.query(
    `INSERT INTO sets (match_id, set_number)
     VALUES ($1, $2)
     RETURNING id, match_id, set_number, "teamA_score", "teamB_score"`,
    [matchId, setNumber]
  );

  return result.rows[0];
};

const findSetByMatchIdAndNumber = async (matchId, setNumber) => {
  const result = await pool.query(
    `SELECT id, match_id, set_number, "teamA_score", "teamB_score"
     FROM sets
     WHERE match_id = $1 AND set_number = $2`,
    [matchId, setNumber]
  );

  return result.rows[0] || null;
};

const findSetsByMatchId = async (matchId) => {
  const result = await pool.query(
    `SELECT id, match_id, set_number, "teamA_score", "teamB_score"
     FROM sets
     WHERE match_id = $1
     ORDER BY set_number ASC`,
    [matchId]
  );

  return result.rows;
};

module.exports = {
  createSet,
  findSetByMatchIdAndNumber,
  findSetsByMatchId,
};
