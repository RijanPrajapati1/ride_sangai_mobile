/**
 * Creates the database named in DATABASE_URL if it does not exist yet
 * (`npm run db:create`). Connects to the server's `postgres` database to do so.
 */
import pg from 'pg';
import { loadDotEnv } from '../src/config/env.js';

loadDotEnv();
const url = process.env.DATABASE_URL;
if (!url) {
  console.error('DATABASE_URL is not set (copy .env.example to .env).');
  process.exit(1);
}

const target = new URL(url);
const name = decodeURIComponent(target.pathname.replace(/^\//, ''));
const admin = new URL(url);
admin.pathname = '/postgres';

const client = new pg.Client({ connectionString: admin.toString() });
try {
  await client.connect();
  const exists = await client.query('SELECT 1 FROM pg_database WHERE datname = $1', [name]);
  if (exists.rowCount) {
    console.log(`Database "${name}" already exists`);
  } else {
    await client.query(`CREATE DATABASE "${name.replaceAll('"', '""')}"`);
    console.log(`Created database "${name}"`);
  }
} catch (err) {
  console.error(`Could not create database "${name}": ${(err as Error).message}`);
  process.exitCode = 1;
} finally {
  await client.end().catch(() => undefined);
}
