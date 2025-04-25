-- PostgreSQL version of createDatabase.js

-- Runtime environments table
CREATE TABLE runtime_environments (
    id SERIAL PRIMARY KEY,           -- SERIAL replaces INTEGER PRIMARY KEY AUTOINCREMENT
    platform TEXT NOT NULL,
    version TEXT
);

-- Games table
CREATE TABLE games (
    id SERIAL PRIMARY KEY,           -- SERIAL replaces INTEGER PRIMARY KEY AUTOINCREMENT
    title TEXT NOT NULL,
    short_description VARCHAR(500),
    genre TEXT CHECK(genre IN ('MMO', 'RPG', 'FPS')),
    runtime_environment_id INTEGER,
    FOREIGN KEY (runtime_environment_id) REFERENCES runtime_environments (id)
);

-- Replace SQLite specific syntax for inserts
-- Instead of: INSERT INTO games (title, short_description, genre, runtime_environments_id) VALUES (?, ?, ?, ?)
-- Use: INSERT INTO games (title, short_description, genre, runtime_environment_id) VALUES ($1, $2, $3, $4) RETURNING id
