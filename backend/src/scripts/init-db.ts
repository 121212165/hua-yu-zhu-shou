import { Pool } from 'pg';
import * as fs from 'fs';
import * as path from 'path';
import dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'flower_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '',
});

async function runSQL(filePath: string): Promise<void> {
  const sql = fs.readFileSync(filePath, 'utf-8');
  await pool.query(sql);
  console.log(`Executed: ${path.basename(filePath)}`);
}

async function main() {
  try {
    const sqlDir = path.join(__dirname, '..', '..', 'database');

    console.log('Initializing database schema...');
    await runSQL(path.join(sqlDir, 'init.sql'));

    console.log('Seeding data...');
    await runSQL(path.join(sqlDir, 'seed.sql'));

    console.log('Database initialized successfully!');
  } catch (error) {
    console.error('Database initialization failed:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

main();
