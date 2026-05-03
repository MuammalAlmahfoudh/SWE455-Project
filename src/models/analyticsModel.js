const pool = require('../config/database');

const getSetScoresByMatchId = async (matchId) => {
  const result = await pool.query(
    `SELECT
       s.set_number,
       COALESCE(SUM(CASE WHEN r.winner = 'A' THEN 1 ELSE 0 END), 0)::int AS "teamA_score",
       COALESCE(SUM(CASE WHEN r.winner = 'B' THEN 1 ELSE 0 END), 0)::int AS "teamB_score"
     FROM sets s
     LEFT JOIN rallies r
       ON r.match_id = s.match_id
      AND r.set_number = s.set_number
     WHERE s.match_id = $1
     GROUP BY s.set_number
     ORDER BY s.set_number ASC`,
    [matchId]
  );

  return result.rows;
};

const getRallyTypeCountsByMatchId = async (matchId) => {
  const result = await pool.query(
    `SELECT winner, type, COUNT(*)::int AS count
     FROM rallies
     WHERE match_id = $1
     GROUP BY winner, type`,
    [matchId]
  );

  return result.rows;
};

module.exports = {
  getSetScoresByMatchId,
  getRallyTypeCountsByMatchId,
};
