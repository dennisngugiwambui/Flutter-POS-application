/**
 * Pushes the Pixel POS migration to Supabase.
 * Requires: SUPABASE_DB_PASSWORD (get it from Dashboard → Settings → Database).
 *
 * From project root:
 *   cd scripts && npm install && set SUPABASE_DB_PASSWORD=your_db_password && node push_db.js
 * Or PowerShell:
 *   cd scripts; npm install; $env:SUPABASE_DB_PASSWORD='your_db_password'; node push_db.js
 */

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const PROJECT_REF = 'eubbmivxtdyvunyblrhd';

async function main() {
  const password = process.env.SUPABASE_DB_PASSWORD;
  if (!password) {
    console.error('Missing SUPABASE_DB_PASSWORD. Get it from Supabase Dashboard → Project → Settings → Database.');
    process.exit(1);
  }

  // Direct connection (Dashboard → Settings → Database shows this format)
  const connectionString = process.env.SUPABASE_DB_URL ||
    `postgresql://postgres:${encodeURIComponent(password)}@db.${PROJECT_REF}.supabase.co:5432/postgres`;
  const client = new Client({ connectionString });

  try {
    await client.connect();
  } catch (e) {
    console.error('Connect failed:', e.message);
    console.error('Get your database password from Supabase Dashboard → Project → Settings → Database.');
    process.exit(1);
  }

  const sqlPath = path.join(__dirname, '..', 'supabase', 'migrations', '20260312000000_initial_schema.sql');
  const sql = fs.readFileSync(sqlPath, 'utf8');

  try {
    await client.query(sql);
    console.log('Migration applied successfully. Tables: profiles, products, shop_configs.');
    console.log('Create the "products" storage bucket in Dashboard → Storage (public) for product images.');
  } catch (e) {
    console.error('Migration failed:', e.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

main();
