import pg from 'pg'
import { drizzle } from 'drizzle-orm/node-postgres'

const { Pool } = pg

let poolInstance: pg.Pool | null = null

/**
 * Returns a singleton PostgreSQL connection pool.
 * Configured with enterprise safety defaults (connection timeouts and idle client recycling).
 */
export function getDbPool(): pg.Pool {
  if (!poolInstance) {
    const connectionString = process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/gil'
    poolInstance = new Pool({
      connectionString,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000
    })

    poolInstance.on('error', (err) => {
      console.error('[DB POOL ERROR] Unexpected client error:', err)
    })
  }

  return poolInstance
}

/**
 * Returns the Drizzle ORM instance connected to the PostgreSQL pool.
 * Does not create or mutate any tables or schema.
 */
export function getDb() {
  const pool = getDbPool()
  return drizzle(pool)
}

export const db = getDb()
