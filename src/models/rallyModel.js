const pool = require('../config/database');

const createRallyAndUpdateScore = async ({ matchId, setNumber, winner, type }) => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const setResult = await client.query(
      `SELECT id, match_id, set_number, "teamA_score", "teamB_score"
       FROM sets
       WHERE match_id = $1 AND set_number = $2
       FOR UPDATE`,
      [matchId, setNumber]
    );

    if (setResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return null;
    }

    const rallyResult = await client.query(
      `INSERT INTO rallies (match_id, set_number, winner, type)
       VALUES ($1, $2, $3, $4)
       RETURNING id, match_id, set_number, winner, type, created_at`,
      [matchId, setNumber, winner, type]
    );

    const scoreColumn = winner === 'A' ? '"teamA_score"' : '"teamB_score"';
    const scoreResult = await client.query(
      `UPDATE sets
       SET ${scoreColumn} = ${scoreColumn} + 1
       WHERE match_id = $1 AND set_number = $2
       RETURNING id, match_id, set_number, "teamA_score", "teamB_score"`,
      [matchId, setNumber]
    );

    await client.query('COMMIT');

    return {
      rally: rallyResult.rows[0],
      set: scoreResult.rows[0],
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  createRallyAndUpdateScore,
};
