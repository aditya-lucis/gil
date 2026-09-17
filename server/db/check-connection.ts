import { getDbPool } from './client'

async function checkConnection() {
  const pool = getDbPool()
  try {
    const client = await pool.connect()
    try {
      const res = await client.query('SELECT version(), current_database(), current_user')
      console.log(JSON.stringify({
        status: 'CONNECTED',
        database: res.rows[0]?.current_database,
        user: res.rows[0]?.current_user,
        version: res.rows[0]?.version
      }))
      process.exit(0)
    } finally {
      client.release()
    }
  } catch (err: any) {
    console.error(JSON.stringify({
      status: 'FAILED',
      code: err.code,
      message: err.message,
      host: err.address || 'localhost',
      port: err.port || 5432
    }))
    process.exit(1)
  }
}

checkConnection()
