import pg from 'pg';
const { Pool } = pg;

// Connection pool configuration
const pool = new Pool({
  user: 'postgres',      // Default PostgreSQL user
  host: 'localhost',     // Database host
  database: 'games_db',  // Database name
  password: 'password',  // Database password
  port: 5432,           // Default PostgreSQL port
});

// Test connection
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Database connection error:', err);
  } else {
    console.log('Connected to PostgreSQL database');
  }
});

// For compatibility with current code structure
// Mimicking the SQLite interface
const connection = {
  exec: async (sql) => {
    return await pool.query(sql);
  },
  run: async (sql, params) => {
    const result = await pool.query(sql, params);
    return { 
      lastID: result.rows[0]?.id || null,
      changes: result.rowCount
    };
  },
  get: async (sql, params = []) => {
    const result = await pool.query(sql, params);
    return result.rows[0];
  },
  all: async (sql, params = []) => {
    const result = await pool.query(sql, params);
    return result.rows;
  }
};

export default connection;