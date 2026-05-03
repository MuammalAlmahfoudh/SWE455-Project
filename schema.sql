CREATE TABLE IF NOT EXISTS matches (
  id SERIAL PRIMARY KEY,
  "teamA" VARCHAR(255) NOT NULL,
  "teamB" VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sets (
  id SERIAL PRIMARY KEY,
  match_id INTEGER NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  set_number INTEGER NOT NULL CHECK (set_number BETWEEN 1 AND 5),
  "teamA_score" INTEGER NOT NULL DEFAULT 0 CHECK ("teamA_score" >= 0),
  "teamB_score" INTEGER NOT NULL DEFAULT 0 CHECK ("teamB_score" >= 0),
  UNIQUE (match_id, set_number)
);

CREATE TABLE IF NOT EXISTS rallies (
  id SERIAL PRIMARY KEY,
  match_id INTEGER NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  set_number INTEGER NOT NULL CHECK (set_number BETWEEN 1 AND 5),
  winner VARCHAR(1) NOT NULL CHECK (winner IN ('A', 'B')),
  type VARCHAR(20) NOT NULL CHECK (type IN ('SPIKE', 'BLOCK', 'ACE', 'ERROR')),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (match_id, set_number) REFERENCES sets(match_id, set_number) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sets_match_id ON sets(match_id);
CREATE INDEX IF NOT EXISTS idx_rallies_match_id ON rallies(match_id);
CREATE INDEX IF NOT EXISTS idx_rallies_match_set ON rallies(match_id, set_number);
