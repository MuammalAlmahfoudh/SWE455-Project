const fs = require('node:fs/promises');
const path = require('node:path');

const pool = require('./database');

const schemaPath = path.resolve(__dirname, '../../schema.sql');

let initializationPromise;

const initializeDatabase = async () => {
  if (!initializationPromise) {
    initializationPromise = (async () => {
      const schemaSql = await fs.readFile(schemaPath, 'utf8');
      await pool.query(schemaSql);
    })().catch((error) => {
      initializationPromise = undefined;
      throw error;
    });
  }

  return initializationPromise;
};

module.exports = {
  initializeDatabase,
};
