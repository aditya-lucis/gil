import { getDbPool } from './client'

async function runIntegrityTests() {
  const pool = getDbPool()
  const client = await pool.connect()

  console.log('=== GIL PHASE D DATABASE INTEGRITY TEST SUITE ===\n')

  let passed = 0
  let failed = 0

  async function test(name: string, fn: () => Promise<void>) {
    const sp = `sp_${passed + failed}`
    await client.query(`SAVEPOINT ${sp}`)
    try {
      await fn()
      await client.query(`RELEASE SAVEPOINT ${sp}`)
      console.log(`[PASS] ${name}`)
      passed++
    } catch (err: any) {
      await client.query(`ROLLBACK TO SAVEPOINT ${sp}`)
      console.error(`[FAIL] ${name}:`, err.message || err)
      failed++
    }
  }

  async function expectError(fn: () => Promise<void>, expectedSqlState?: string) {
    await client.query('SAVEPOINT sub_err')
    try {
      await fn()
      await client.query('RELEASE SAVEPOINT sub_err')
      return false
    } catch (err: any) {
      await client.query('ROLLBACK TO SAVEPOINT sub_err')
      if (expectedSqlState && err.code !== expectedSqlState) {
        throw new Error(`Expected SQL error ${expectedSqlState}, got ${err.code}: ${err.message}`)
      }
      return true
    }
  }

  try {
    await client.query('BEGIN')

    // 1. Verify exact table count and names
    await test('1. All 42 tables (30 Phase A-C + 12 Phase D) exist in PostgreSQL', async () => {
      const res = await client.query(`
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
        ORDER BY table_name;
      `)
      const tables = res.rows.map((r: any) => r.table_name)
      if (tables.length !== 42) {
        throw new Error(`Expected 42 tables, got ${tables.length}`)
      }

      const expectedPhaseD = [
        'customer_contacts',
        'customer_groups',
        'customer_pricings',
        'customers',
        'discount_rules',
        'payment_terms',
        'price_list_items',
        'price_lists',
        'salespersons',
        'supplier_contacts',
        'supplier_groups',
        'suppliers'
      ]

      for (const t of expectedPhaseD) {
        if (!tables.includes(t)) {
          throw new Error(`Missing expected Phase D table: ${t}`)
        }
      }
    })

    // Prepare test fixture IDs inside a transaction that rolls back or cleans up
    await client.query(`
      INSERT INTO currencies (code, name, symbol, decimal_places)
      VALUES ('IDR', 'Indonesian Rupiah', 'Rp', 2)
      ON CONFLICT (code) DO NOTHING;
    `)

    const tenantRes = await client.query(`
      INSERT INTO tenants (code, name) 
      VALUES ('TEST-TENANT-D', 'Phase D Test Tenant') 
      RETURNING id;
    `)
    const tenantId = tenantRes.rows[0].id

    const orgRes = await client.query(`
      INSERT INTO organizations (tenant_id, code, name, base_currency_code)
      VALUES ($1, 'TEST-ORG-D', 'Phase D Org', 'IDR')
      RETURNING id;
    `, [tenantId])
    const orgId = orgRes.rows[0].id

    const companyRes = await client.query(`
      INSERT INTO companies (tenant_id, organization_id, code, name, base_currency_code) 
      VALUES ($1, $2, 'TEST-CO-D1', 'Phase D Company 1', 'IDR') 
      RETURNING id;
    `, [tenantId, orgId])
    const company1Id = companyRes.rows[0].id

    const company2Res = await client.query(`
      INSERT INTO companies (tenant_id, organization_id, code, name, base_currency_code) 
      VALUES ($1, $2, 'TEST-CO-D2', 'Phase D Company 2', 'IDR') 
      RETURNING id;
    `, [tenantId, orgId])
    const company2Id = company2Res.rows[0].id

    // Payment Terms test
    const termRes = await client.query(`
      INSERT INTO payment_terms (tenant_id, company_id, code, name, days, discount_days, discount_percentage)
      VALUES ($1, $2, 'NET30', 'Net 30 Days', 30, 10, 2.00)
      RETURNING id;
    `, [tenantId, company1Id])
    const termId = termRes.rows[0].id

    // 2. Duplicate customer code in same (tenant, company)
    await test('2. Duplicate customer code in same company is rejected', async () => {
      await client.query(`
        INSERT INTO customers (tenant_id, company_id, code, name, term_id)
        VALUES ($1, $2, 'CUST-001', 'Customer One', $3);
      `, [tenantId, company1Id, termId])

      const rejected = await expectError(async () => {
        await client.query(`
          INSERT INTO customers (tenant_id, company_id, code, name)
          VALUES ($1, $2, 'CUST-001', 'Duplicate Customer');
        `, [tenantId, company1Id])
      }, '23505')

      if (!rejected) {
        throw new Error('Expected unique violation for duplicate customer code')
      }
    })

    // 3. Multi-tenant / company isolation
    await test('3. Same customer code in DIFFERENT company is permitted (proper scoping)', async () => {
      const res = await client.query(`
        INSERT INTO customers (tenant_id, company_id, code, name)
        VALUES ($1, $2, 'CUST-001', 'Customer One in Company 2')
        RETURNING id;
      `, [tenantId, company2Id])

      if (!res.rows[0]?.id) {
        throw new Error('Failed to insert customer with same code in different company')
      }
    })

    // 4. Duplicate supplier code in same company
    await test('4. Duplicate supplier code in same company is rejected', async () => {
      await client.query(`
        INSERT INTO suppliers (tenant_id, company_id, code, name, term_id)
        VALUES ($1, $2, 'SUPP-001', 'Supplier One', $3);
      `, [tenantId, company1Id, termId])

      const rejected = await expectError(async () => {
        await client.query(`
          INSERT INTO suppliers (tenant_id, company_id, code, name)
          VALUES ($1, $2, 'SUPP-001', 'Duplicate Supplier');
        `, [tenantId, company1Id])
      }, '23505')

      if (!rejected) {
        throw new Error('Expected unique violation for duplicate supplier code')
      }
    })

    // 5. Invalid Foreign Key rejection
    await test('5. Invalid FK (non-existent customer_group_id) is rejected', async () => {
      const randomUuid = '00000000-0000-0000-0000-000000000999'
      const rejected = await expectError(async () => {
        await client.query(`
          INSERT INTO customers (tenant_id, company_id, group_id, code, name)
          VALUES ($1, $2, $3, 'CUST-FK-FAIL', 'Invalid FK Cust');
        `, [tenantId, company1Id, randomUuid])
      }, '23503')

      if (!rejected) {
        throw new Error('Expected foreign key violation for non-existent group_id')
      }
    })

    // 6. Check constraint: negative credit limit
    await test('6. Negative credit_limit on customer is rejected by CHECK constraint', async () => {
      const rejected = await expectError(async () => {
        await client.query(`
          INSERT INTO customers (tenant_id, company_id, code, name, credit_limit)
          VALUES ($1, $2, 'CUST-NEG-CREDIT', 'Negative Credit Cust', -500.00);
        `, [tenantId, company1Id])
      }, '23514')

      if (!rejected) {
        throw new Error('Expected check violation for negative credit limit')
      }
    })

    // 7. Check constraint: invalid date range on price_lists
    await test('7. Invalid date range (valid_to < valid_from) on price_lists is rejected', async () => {
      const rejected = await expectError(async () => {
        await client.query(`
          INSERT INTO price_lists (tenant_id, company_id, code, name, valid_from, valid_to)
          VALUES ($1, $2, 'PL-INVALID-DATES', 'Invalid Dates PL', '2026-12-31', '2026-01-01');
        `, [tenantId, company1Id])
      }, '23514')

      if (!rejected) {
        throw new Error('Expected check violation for valid_to < valid_from')
      }
    })

    // 8. Check constraint: discount_type domain check on discount_rules
    await test('8. Invalid discount_type on discount_rules is rejected', async () => {
      const rejected = await expectError(async () => {
        await client.query(`
          INSERT INTO discount_rules (tenant_id, company_id, code, name, discount_type, discount_value)
          VALUES ($1, $2, 'DISC-INVALID', 'Invalid Disc Rule', 'unsupported_type', 10);
        `, [tenantId, company1Id])
      }, '23514')

      if (!rejected) {
        throw new Error('Expected check violation for unsupported discount_type')
      }
    })

    // 9. Soft-delete retention and historical queryability
    await test('9. Soft-deleted customer remains in database with audit fields', async () => {
      const custRes = await client.query(`
        INSERT INTO customers (tenant_id, company_id, code, name)
        VALUES ($1, $2, 'CUST-SOFT-DEL', 'Customer To Soft Delete')
        RETURNING id;
      `, [tenantId, company1Id])
      const custId = custRes.rows[0].id

      // Perform soft delete
      await client.query(`
        UPDATE customers 
        SET deleted_at = NOW(), is_active = false 
        WHERE id = $1;
      `, [custId])

      // Verify row is still in the table for historical/audit reporting
      const historyCheck = await client.query(`
        SELECT id, code, name, is_active, deleted_at 
        FROM customers 
        WHERE id = $1;
      `, [custId])

      if (historyCheck.rows.length !== 1 || !historyCheck.rows[0].deleted_at) {
        throw new Error('Soft-deleted record missing or deleted_at is null')
      }
    })

    // 10. Price list and cascade delete to items
    await test('10. Deleting price_list cascades delete to price_list_items', async () => {
      const plRes = await client.query(`
        INSERT INTO price_lists (tenant_id, company_id, code, name)
        VALUES ($1, $2, 'PL-CASCADE', 'Cascade Test Price List')
        RETURNING id;
      `, [tenantId, company1Id])
      const plId = plRes.rows[0].id

      const dummyItemId = '11111111-1111-1111-1111-111111111111'
      await client.query(`
        INSERT INTO price_list_items (price_list_id, item_id, unit_price, min_quantity)
        VALUES ($1, $2, 150000.00, 1);
      `, [plId, dummyItemId])

      // Delete price list
      await client.query(`DELETE FROM price_lists WHERE id = $1;`, [plId])

      // Verify child item was cascaded
      const childCheck = await client.query(`
        SELECT count(*) FROM price_list_items WHERE price_list_id = $1;
      `, [plId])

      if (parseInt(childCheck.rows[0].count) !== 0) {
        throw new Error('Price list items were not cascade deleted')
      }
    })

    // Rollback test transaction to keep database clean
    await client.query('ROLLBACK')
    console.log('\nIntegrity test transaction rolled back cleanly.')
  } catch (err) {
    await client.query('ROLLBACK')
    throw err
  } finally {
    client.release()
    await pool.end()
  }

  console.log(`\nTEST SUMMARY: ${passed} passed, ${failed} failed.`)
  if (failed > 0) {
    process.exit(1)
  }
}

runIntegrityTests().catch((err) => {
  console.error('Fatal error during integrity tests:', err)
  process.exit(1)
})
